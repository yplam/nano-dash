/// FFI-backed [VoiceEngineController]: owns the FFI lifecycle (init / open /
/// speak / stop / close) and the event channel for the native full-duplex voice
/// engine.
///
/// Selected on native platforms by [voice_engine_controller.dart]; the web build
/// gets [voice_engine_controller_stub.dart] instead.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:ffi' as ffi;
import 'dart:isolate';

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';

import 'voice_engine_bindings_generated.dart' as bindings;
import 'voice_engine_types.dart';

export 'voice_engine_types.dart';

/// Owns the native voice engine. Create one, [init] it once, then [open] it with
/// model paths. Recognized speech arrives on [transcripts]; feed reply text to
/// [speak]/[speakText] and the engine synthesizes + plays it (AEC keeps the
/// played reply out of the transcript).
///
/// The native side keeps a single engine + SendPort, so use one controller per
/// app.
class VoiceEngineController {
  final ReceivePort _rx = ReceivePort();
  final StreamController<VoiceTranscript> _transcripts =
      StreamController<VoiceTranscript>.broadcast();
  final StreamController<String> _errors =
      StreamController<String>.broadcast();
  final StreamController<bool> _ready = StreamController<bool>.broadcast();
  final StreamController<bool> _speaking = StreamController<bool>.broadcast();
  final StreamController<String?> _wake = StreamController<String?>.broadcast();
  final StreamController<void> _sleep = StreamController<void>.broadcast();
  final StreamController<EnrollmentResult> _enrolled =
      StreamController<EnrollmentResult>.broadcast();

  bool _initialized = false;
  bool _opened = false;
  bool _disposed = false;
  bool _isSpeaking = false;
  // Whether the current reply has emitted `ve_speak_begin` (so `ve_speak_end`
  // is balanced). Set lazily on the first sentence sent; see [speak].
  bool _replyBegun = false;

  StreamSubscription<String>? _textSub;

  /// Recognized utterances, one event per VAD-segmented span. Broadcast.
  Stream<VoiceTranscript> get transcripts => _transcripts.stream;

  /// Non-fatal engine errors (e.g. an AEC frame failure), for surfacing/logging.
  Stream<String> get errors => _errors.stream;

  /// Fires `true` once the engine has loaded its models and capture is running.
  Stream<bool> get ready => _ready.stream;

  /// TTS playback state: `true` while synthesized audio is playing out, `false`
  /// once the far-end ring drains (after a short hangover). Broadcast; used to
  /// scope the chatbot's barge-in echo guard.
  Stream<bool> get speaking => _speaking.stream;

  /// Whether TTS audio is currently playing (latest [speaking] value).
  bool get isSpeaking => _isSpeaking;

  /// The current lip-sync mouth-opening level in `[0, 1]`, from the RMS of the
  /// TTS audio playing out right now (`0.0` when nothing plays). A lock-free
  /// native read, so poll it — e.g. once per Live2D render frame — rather than
  /// expecting a stream. Independent of [speaking]'s hangover: it tracks the
  /// instantaneous envelope, dropping to `0.0` in the gaps between sentences.
  double get speakingLevel => bindings.ve_speaking_level();

  /// Fires when the wake word is recognized and the engine leaves the idle
  /// state (ASR is now running). Only meaningful when opened with `enableWake`.
  /// Carries the canned greeting the engine just began playing (see
  /// `wakeAckPhrases`), or `null` when none was cached / on a programmatic
  /// [wakeEngine].
  Stream<String?> get wake => _wake.stream;

  /// Fires when the engine returns to the idle (asleep) state — after a
  /// Dart-driven [sleep] or at teardown. Only meaningful with `enableWake`.
  Stream<void> get sleep => _sleep.stream;

  /// Fires with the outcome of each [enrollEnd]. Only meaningful when opened with
  /// a `speakerModelPath`.
  Stream<EnrollmentResult> get enrolled => _enrolled.stream;

  bool get isOpen => _opened;

  /// Wire up the Dart DL API + SendPort. Call once before [open].
  void init() {
    if (_initialized) return;
    bindings.ve_init(
      ffi.NativeApi.initializeApiDLData,
      _rx.sendPort.nativePort,
    );
    _rx.listen(_onMessage);
    _initialized = true;
  }

  /// Load models, open the audio devices and start the engine. Throws
  /// [VoiceEngineException] on failure (bad config, already open, or a model/
  /// device startup error — the return code distinguishes which).
  ///
  /// `ve_open` blocks until both workers have loaded their models and capture is
  /// running (a few seconds for the ASR + TTS models), so the FFI call is made on
  /// a short-lived helper isolate to keep the UI responsive. The engine's threads
  /// post events to the SendPort wired by [init] regardless of which isolate
  /// opened it.
  Future<void> open(VoiceEngineConfig config) async {
    if (!_initialized) init();
    if (_opened) return;
    final jsonBytes = utf8.encode(jsonEncode(config.toJson()));
    final rc = await Isolate.run(() => _veOpen(jsonBytes));
    if (rc != 0) {
      throw VoiceEngineException(switch (rc) {
        -1 => 've_open: invalid config',
        -2 => 've_open: engine already open',
        _ => 've_open: model/device startup failed (code $rc)',
      });
    }
    _opened = true;
  }

  /// Speak a stream of text deltas (e.g. an LLM token stream) in real time.
  /// Cancels any current speech, then splits the stream into sentences and hands
  /// each complete sentence to the engine as it forms — so the first sentence is
  /// heard while later ones are still arriving.
  Future<void> speak(Stream<String> textDeltas) async {
    if (!_opened) {
      throw VoiceEngineException('speak before open');
    }
    await stop();
    final splitter = _SentenceBuffer();
    // A reply is framed begin → sentences → end so the remote backend keeps one
    // connection+session open for the whole turn. `begin` is emitted lazily on
    // the first sentence actually sent, so an empty/non-speakable reply opens
    // nothing; `end` is emitted on completion only if a `begin` was.
    _replyBegun = false;
    _textSub = textDeltas.listen(
      (delta) {
        for (final sentence in splitter.add(delta)) {
          _speakSentence(sentence);
        }
      },
      onError: (Object e, StackTrace s) {
        if (kDebugMode) debugPrint('VoiceEngine text stream error: $e');
      },
      onDone: () {
        for (final sentence in splitter.flush()) {
          _speakSentence(sentence);
        }
        if (_replyBegun) {
          _replyBegun = false;
          bindings.ve_speak_end();
        }
      },
      cancelOnError: false,
    );
  }

  /// Speak a single, already-complete string. Convenience over [speak].
  Future<void> speakText(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return Future.value();
    return speak(Stream.value(trimmed));
  }

  /// Put the engine back to sleep: stop running ASR and listen only for the wake
  /// word again. A no-op unless opened with `enableWake`. The native side stops
  /// any in-flight TTS as it sleeps and emits a `sleep` event.
  void sleepEngine() {
    if (_opened) bindings.ve_set_active(0);
  }

  /// Force the engine awake without waiting for the wake word (e.g. a manual
  /// "tap to talk"). A no-op unless opened with `enableWake`. Emits `wake`.
  void wakeEngine() {
    if (_opened) bindings.ve_set_active(1);
  }

  /// Start capturing the enrolled voice. From now until [enrollEnd] the engine
  /// accumulates mic audio (and pauses ASR/wake handling) instead of transcribing.
  /// A no-op unless opened with a `speakerModelPath`. Have the user speak a short
  /// phrase, then call [enrollEnd].
  void enrollBegin() {
    if (_opened) bindings.ve_enroll_begin();
  }

  /// Finish enrollment: compute the voiceprint from the captured audio and store
  /// it under [name] (empty uses the default `'owner'`). The outcome arrives on
  /// [enrolled]. Call [enrollBegin]/[enrollEnd] a few times to enroll several
  /// samples for a more robust voiceprint.
  void enrollEnd([String name = '']) {
    if (_opened) _callWithName(bindings.ve_enroll_end, name);
  }

  /// Forget every voiceprint under [name] (empty uses the default `'owner'`) so
  /// enrollment can start over. A no-op unless opened with a `speakerModelPath`.
  void enrollReset([String name = '']) {
    if (_opened) _callWithName(bindings.ve_enroll_reset, name);
  }

  /// Marshal a UTF-8 name into native memory and invoke [fn] with the pointer.
  void _callWithName(
    int Function(ffi.Pointer<ffi.Uint8>, int) fn,
    String name,
  ) {
    final bytes = utf8.encode(name);
    if (bytes.isEmpty) {
      fn(ffi.nullptr, 0);
      return;
    }
    final ptr = malloc.allocate<ffi.Uint8>(bytes.length);
    try {
      ptr.asTypedList(bytes.length).setAll(0, bytes);
      fn(ptr, bytes.length);
    } finally {
      malloc.free(ptr);
    }
  }

  /// Barge-in: cancel the current speech and discard queued/in-flight audio.
  Future<void> stop() async {
    await _textSub?.cancel();
    _textSub = null;
    // The session bump from ve_stop cancels any open remote reply, so no
    // ve_speak_end is needed; just drop the pending balance.
    _replyBegun = false;
    if (_opened) bindings.ve_stop();
    // The ring is now cleared, so playback is over; reflect it at once instead
    // of waiting for the engine's hangover, so a barge-in guard lifts promptly.
    if (_isSpeaking) {
      _isSpeaking = false;
      if (!_speaking.isClosed) _speaking.add(false);
    }
  }

  /// Stop the engine and close the audio devices, keeping the controller
  /// reusable (the event channel stays open) so a later [open] can restart it.
  /// `ve_close` joins the worker threads, so it runs off the UI isolate too.
  Future<void> close() async {
    await stop();
    if (_opened) {
      await Isolate.run(bindings.ve_close);
      _opened = false;
    }
  }

  /// Matches any speakable character: a Unicode letter or digit (covers Latin
  /// and CJK). A fragment without one is pure punctuation/whitespace.
  static final RegExp _speakable = RegExp(r'[\p{L}\p{N}]', unicode: true);

  /// Push one sentence to the native TTS queue.
  void _speakSentence(String sentence) {
    final trimmed = sentence.trim();
    if (trimmed.isEmpty || !_opened) return;
    // Skip fragments with no speakable content (e.g. a stray closing quote
    // split off a sentence): the TTS lexicon drops every char and the native
    // `generate` then fails with "TTS generation failed".
    if (!_speakable.hasMatch(trimmed)) {
      if (kDebugMode) debugPrint('VoiceEngine tts: skip non-speakable "$trimmed"');
      return;
    }
    if (kDebugMode) debugPrint('VoiceEngine tts: "$trimmed"');
    // Open the reply on the first real sentence so the remote backend keeps a
    // single session for the whole turn.
    if (!_replyBegun) {
      _replyBegun = true;
      bindings.ve_speak_begin();
    }
    final bytes = utf8.encode(trimmed);
    final ptr = malloc.allocate<ffi.Uint8>(bytes.length);
    try {
      ptr.asTypedList(bytes.length).setAll(0, bytes);
      bindings.ve_speak(ptr, bytes.length);
    } finally {
      malloc.free(ptr);
    }
  }

  /// Decode an event JSON string pushed from the native side.
  void _onMessage(dynamic raw) {
    if (raw is! String) return;
    final Map<String, dynamic> map;
    try {
      map = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return;
    }
    switch (map['event']) {
      case 'ready':
        if (!_ready.isClosed) _ready.add(true);
      case 'wake':
        final ack = (map['ack'] as String?)?.trim();
        if (!_wake.isClosed) _wake.add(ack != null && ack.isNotEmpty ? ack : null);
      case 'sleep':
        if (!_sleep.isClosed) _sleep.add(null);
      case 'transcript':
        final text = (map['text'] as String?)?.trim() ?? '';
        if (text.isNotEmpty && !_transcripts.isClosed) {
          _transcripts.add(VoiceTranscript(text));
        }
      case 'error':
        final message = map['message'] as String? ?? 'unknown error';
        if (kDebugMode) debugPrint('VoiceEngine error: $message');
        if (!_errors.isClosed) _errors.add(message);
      case 'speaking':
        final active = map['value'] as bool? ?? false;
        _isSpeaking = active;
        if (!_speaking.isClosed) _speaking.add(active);
      case 'speakDone':
        // Synthesis for a session was queued; no UI action needed today.
        break;
      case 'enrolled':
        final result = EnrollmentResult(
          ok: map['ok'] as bool? ?? false,
          count: map['count'] as int? ?? 0,
          message: map['message'] as String?,
        );
        if (!_enrolled.isClosed) _enrolled.add(result);
    }
  }

  /// Close the engine and release all resources. Safe to call multiple times.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _textSub?.cancel();
    if (_opened) {
      // Final teardown: a synchronous close is fine (we're going away anyway).
      bindings.ve_close();
      _opened = false;
    }
    _transcripts.close();
    _errors.close();
    _ready.close();
    _speaking.close();
    _wake.close();
    _sleep.close();
    _enrolled.close();
    _rx.close();
  }
}

/// Allocate the config JSON, call `ve_open`, free it, and return the code.
/// Top-level so it can run on an [Isolate.run] helper isolate.
int _veOpen(Uint8List jsonBytes) {
  final ptr = malloc.allocate<ffi.Uint8>(jsonBytes.length);
  try {
    ptr.asTypedList(jsonBytes.length).setAll(0, jsonBytes);
    return bindings.ve_open(ptr, jsonBytes.length);
  } finally {
    malloc.free(ptr);
  }
}

/// Accumulates streamed text and yields complete sentences as they form, so the
/// engine can start synthesizing before the whole reply has arrived. Splits on
/// CJK and ASCII sentence terminators (and a period followed by whitespace).
///
/// Ported from the old Dart `TtsService` (the split logic was tuned there).
class _SentenceBuffer {
  final StringBuffer _buf = StringBuffer();

  static final RegExp _boundary = RegExp(r'[。！？!?；;\n]|\.(?=\s)');

  /// Append [text] and return any sentences that are now complete.
  List<String> add(String text) {
    _buf.write(text);
    return _drain(flush: false);
  }

  /// Return remaining buffered text as a final sentence (if any).
  List<String> flush() => _drain(flush: true);

  List<String> _drain({required bool flush}) {
    final out = <String>[];
    var s = _buf.toString();
    while (true) {
      final m = _boundary.firstMatch(s);
      if (m == null) break;
      final sentence = s.substring(0, m.end).trim();
      if (sentence.isNotEmpty) out.add(sentence);
      s = s.substring(m.end);
    }
    _buf.clear();
    if (flush) {
      final rest = s.trim();
      if (rest.isNotEmpty) out.add(rest);
    } else {
      _buf.write(s);
    }
    return out;
  }
}
