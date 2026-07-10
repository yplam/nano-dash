/// The [VoiceEngineController]: owns the FFI lifecycle (init / open / speak /
/// stop / close) and the event channel for the native full-duplex voice engine.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:ffi' as ffi;
import 'dart:isolate';

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';

import 'voice_engine_bindings_generated.dart' as bindings;

/// Open-time configuration. Field names + defaults mirror the Rust
/// `EngineConfig`; [toJson] uses the snake_case keys it deserializes.
///
/// [asrModelDir] must contain `tokens.txt` and the SenseVoice model as
/// `model.onnx` or `model.int8.onnx` (fp32 preferred over the int8 build); the
/// Silero VAD is supplied separately via [vadModelPath].
/// [ttsModelDir] must contain a VITS or Kokoro model (`model.onnx`, `tokens.txt`,
/// plus a lexicon — the engine sniffs the family).
@immutable
class VoiceEngineConfig {
  const VoiceEngineConfig({
    required this.asrModelDir,
    this.vadModelPath = '',
    this.language = 'auto',
    this.useItn = true,
    this.ttsBackend = 'local',
    required this.ttsModelDir,
    this.ttsApiKey = '',
    this.ttsResourceId = '',
    this.ttsEndpoint = '',
    this.ttsSpeaker = '',
    this.ttsModel = '',
    this.ttsBaseUrl = '',
    this.ttsLanguage = '',
    this.ttsInstructions = '',
    this.ttsProxy = '',
    this.sid = 0,
    this.speed = 1.0,
    this.streamDelayMs,
    this.enableAec = true,
    this.energyGate = 0.0,
    this.enableWake = false,
    this.kwsModelDir = '',
    this.wakeKeywords = '',
    this.wakeScore = 0.0,
    this.wakeThreshold = 0.0,
  });

  /// Folder with the SenseVoice ASR model files (`model.onnx`/`model.int8.onnx`,
  /// `tokens.txt`).
  final String asrModelDir;

  /// Path to the Silero VAD model (`silero_vad.onnx`). The VAD is not an ASR
  /// model, so it can live outside [asrModelDir]; empty falls back to
  /// `asrModelDir/silero_vad.onnx`.
  final String vadModelPath;

  /// SenseVoice language steer: `'auto'`, `'zh'`, `'en'`, `'ja'`, `'ko'`, `'yue'`.
  final String language;

  /// Inverse text normalization (digits, punctuation).
  final bool useItn;

  /// Which synthesizer to drive: `'local'` (VITS/Kokoro from [ttsModelDir]),
  /// `'volcengine'` (Volcengine WebSocket streaming TTS), `'vllm'` (a vLLM-Omni /
  /// OpenAI-compatible `/v1/audio/speech/stream` WebSocket), or `'openai'` (the
  /// OpenAI HTTP API `POST /v1/audio/speech`).
  final String ttsBackend;

  /// Folder with the VITS/Kokoro TTS model. Only used when [ttsBackend] is
  /// `'local'`.
  final String ttsModelDir;

  /// Online TTS API key. For `'volcengine'` it is the Volcengine `X-Api-Key`
  /// header; for `'vllm'`/`'openai'` it is sent as `Authorization: Bearer` (empty
  /// omits it).
  final String ttsApiKey;

  /// Online WebSocket TTS — `X-Api-Resource-Id` header (model family); empty lets
  /// the engine apply its default. Only used when [ttsBackend] is `'volcengine'`.
  final String ttsResourceId;

  /// Online WebSocket TTS endpoint; empty lets the engine apply its default.
  /// Only used when [ttsBackend] is `'volcengine'`.
  final String ttsEndpoint;

  /// Online TTS voice/speaker id. For `'volcengine'` e.g.
  /// `zh_female_gaolengyujie_uranus_bigtts`; for `'vllm'` e.g. `vivian`; for
  /// `'openai'` e.g. `alloy` (empty falls back to the engine default). Used when
  /// [ttsBackend] is `'volcengine'`, `'vllm'`, or `'openai'`.
  final String ttsSpeaker;

  /// Online TTS optional `model` id. For `'volcengine'` the cloned-voice version;
  /// for `'vllm'` the served model id; for `'openai'` e.g. `gpt-4o-mini-tts`.
  /// Used when [ttsBackend] is `'volcengine'`, `'vllm'`, or `'openai'`.
  final String ttsModel;

  /// Online TTS server base URL. For `'vllm'` (e.g. `http://localhost:8091`) a
  /// `ws(s)://.../v1/audio/speech/stream` endpoint is derived; for `'openai'`
  /// (e.g. `https://api.openai.com/v1`) the `/audio/speech` endpoint is derived.
  /// Used when [ttsBackend] is `'vllm'` or `'openai'`.
  final String ttsBaseUrl;

  /// vLLM-Omni TTS language steer (Qwen3-TTS only, e.g. `English`); empty omits
  /// it. Only used when [ttsBackend] is `'vllm'`.
  final String ttsLanguage;

  /// Online TTS voice style/emotion instructions; empty omits them. Used when
  /// [ttsBackend] is `'vllm'` or `'openai'`.
  final String ttsInstructions;

  /// Optional HTTP proxy (e.g. `http://127.0.0.1:1080`) for the online TTS
  /// connection; empty connects directly. For `'vllm'` (WebSocket) the proxy
  /// must support `CONNECT`. Used when [ttsBackend] is `'vllm'` or `'openai'`.
  final String ttsProxy;

  /// Speaker id for multi-speaker local TTS models.
  final int sid;

  /// Speaking rate (larger is faster).
  final double speed;

  /// AEC render→capture delay hint (ms); `null` lets AEC3 estimate it.
  final int? streamDelayMs;

  /// Run the webrtc AEC on the mic before ASR (disable for A/B testing).
  final bool enableAec;

  /// Post-AEC RMS gate: while > 0, mic frames quieter than this are zeroed
  /// before the VAD, suppressing low-level echo residue. `0` disables it.
  final double energyGate;

  /// Gate the ASR behind a wake word. When `true` the engine starts asleep and
  /// only runs the keyword-spotter until [wakeKeywords] is heard. `false` keeps
  /// the always-transcribing behavior.
  final bool enableWake;

  /// Folder with the keyword-spotter model (`encoder/decoder/joiner.onnx`,
  /// `tokens.txt`). Required when [enableWake].
  final String kwsModelDir;

  /// Inline, tokenized wake phrase(s); empty falls back to a `keywords.txt` in
  /// [kwsModelDir].
  final String wakeKeywords;

  /// KWS boost score; `0` keeps the engine default.
  final double wakeScore;

  /// KWS detection threshold; `0` keeps the engine default.
  final double wakeThreshold;

  Map<String, dynamic> toJson() => {
    'asr_model_dir': asrModelDir,
    'vad_model': vadModelPath,
    'language': language,
    'use_itn': useItn,
    'tts_backend': ttsBackend,
    'tts_model_dir': ttsModelDir,
    'volcengine_tts': {
      'api_key': ttsApiKey,
      'resource_id': ttsResourceId,
      'endpoint': ttsEndpoint,
      'speaker': ttsSpeaker,
      'model': ttsModel,
    },
    'vllm_tts': {
      'base_url': ttsBaseUrl,
      'api_key': ttsApiKey,
      'model': ttsModel,
      'voice': ttsSpeaker,
      'language': ttsLanguage,
      'instructions': ttsInstructions,
      'proxy': ttsProxy,
    },
    'openai_tts': {
      'base_url': ttsBaseUrl,
      'api_key': ttsApiKey,
      'model': ttsModel,
      'voice': ttsSpeaker,
      'instructions': ttsInstructions,
      'proxy': ttsProxy,
    },
    'sid': sid,
    'speed': speed,
    'stream_delay_ms': streamDelayMs,
    'enable_aec': enableAec,
    'energy_gate': energyGate,
    'enable_wake': enableWake,
    'kws_model_dir': kwsModelDir,
    'wake_keywords': wakeKeywords,
    'wake_score': wakeScore,
    'wake_threshold': wakeThreshold,
  };
}

/// Thrown when a native call fails.
class VoiceEngineException implements Exception {
  VoiceEngineException(this.message);
  final String message;
  @override
  String toString() => 'VoiceEngineException: $message';
}

/// A recognized utterance pushed from the engine's ASR.
@immutable
class VoiceTranscript {
  VoiceTranscript(this.text, {DateTime? time}) : time = time ?? DateTime.now();

  final String text;
  final DateTime time;

  @override
  String toString() => 'VoiceTranscript($text)';
}

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
  final StreamController<void> _wake = StreamController<void>.broadcast();
  final StreamController<void> _sleep = StreamController<void>.broadcast();

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

  /// Fires when the wake word is recognized and the engine leaves the idle
  /// state (ASR is now running). Only meaningful when opened with `enableWake`.
  Stream<void> get wake => _wake.stream;

  /// Fires when the engine returns to the idle (asleep) state — after a
  /// Dart-driven [sleep] or at teardown. Only meaningful with `enableWake`.
  Stream<void> get sleep => _sleep.stream;

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
        if (!_wake.isClosed) _wake.add(null);
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
