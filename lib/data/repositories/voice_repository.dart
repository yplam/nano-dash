import 'dart:async';

import '../../domain/models/voice.dart';
import '../../extensions/loggable.dart';
import '../services/voice_service.dart';
import 'settings_repository.dart';

export '../services/voice_service.dart' show VoiceException, VoiceTranscript;

/// The app-wide voice contract: it owns the engine's lifecycle and persisted
/// settings, and hands out the streams every other feature listens to.
///
/// Deliberately independent of the voice *UI*. A consumer — the Live2D cubit
/// watching [speaking] to drive lip sync, or a agent cubit that pipes an
/// LLM token stream into [speak] and answers [transcripts] — reads this
/// repository and never has to know whether `VoiceCubit` or the mic button is
/// mounted. Only the lifecycle (enable/disable, wake/sleep) is UI-driven.
///
/// [transcripts], [speaking], [wake] and [sleep] are broadcast and belong to the
/// underlying `VoiceEngineController`.
class VoiceRepository with Loggable {
  VoiceRepository(this._settings, this._service)
    : _config = _settings.load(voiceSettingsKey) {
    _wakeSub = _service.wake.listen((_) => _setStatus(VoiceStatus.listening));
    _sleepSub = _service.sleep.listen((_) => _setStatus(VoiceStatus.idle));
    _errorSub = _service.errors.listen((e) => logWarning('engine: $e'));
  }

  final SettingsRepository _settings;
  final VoiceService _service;

  final StreamController<VoiceStatus> _status =
      StreamController<VoiceStatus>.broadcast();

  late final StreamSubscription<void> _wakeSub;
  late final StreamSubscription<void> _sleepSub;
  late final StreamSubscription<String> _errorSub;

  VoiceSettings _config;
  VoiceStatus _currentStatus = VoiceStatus.off;
  String? _error;

  @override
  String get logIdentifier => '[VoiceRepository]';

  /// The current persisted settings.
  VoiceSettings get config => _config;

  /// The engine lifecycle, coalesced from the open/close calls and the engine's
  /// own wake/sleep events. Broadcast; [status] is the latest value.
  Stream<VoiceStatus> get statusChanges => _status.stream;

  VoiceStatus get status => _currentStatus;

  /// Why the last [enable] failed, or `null` unless [status] is
  /// [VoiceStatus.error].
  String? get error => _error;

  /// Recognized utterances, one per VAD-segmented span.
  Stream<VoiceTranscript> get transcripts => _service.transcripts;

  /// `true` while synthesized speech is playing out, `false` once it drains.
  Stream<bool> get speaking => _service.speaking;

  /// Whether TTS audio is playing right now (latest [speaking] value).
  bool get isSpeaking => _service.isSpeaking;

  /// The current mouth-opening level in `[0, 1]`, from the amplitude (RMS) of the
  /// TTS audio playing out right now — `0.0` when nothing plays.
  double get speakingLevel => _service.speakingLevel;

  /// Fires when the engine leaves the asleep state (wake word, or [wakeNow]).
  Stream<void> get wake => _service.wake;

  /// Fires when the engine returns to the asleep state.
  Stream<void> get sleep => _service.sleep;

  /// Non-fatal engine errors (an AEC frame failure, a synthesis error).
  Stream<String> get errors => _service.errors;

  /// Whether the engine was opened with echo cancellation. Without it, played
  /// TTS bleeds into the mic and is transcribed, so a consumer must gate
  /// barge-in on [isSpeaking] rather than let a reply interrupt itself.
  bool get aecEnabled => _service.aecEnabled;

  Future<void> save(VoiceSettings config) {
    _config = config;
    return _settings.save(voiceSettingsKey, config);
  }

  /// Open the engine with the persisted settings: load the models, take the
  /// microphone, and start either wake-gated ([VoiceStatus.idle]) or
  /// continuously transcribing ([VoiceStatus.listening]).
  Future<void> enable() async {
    if (_currentStatus == VoiceStatus.starting || _service.isRunning) return;
    _error = null;
    _setStatus(VoiceStatus.starting);
    try {
      await _service.start(VoiceConfig.fromSettings(_config));
    } on VoiceException catch (e) {
      _error = e.message;
      logWarning('enable failed: ${e.message}');
      _setStatus(VoiceStatus.error);
      return;
    }
    // A wake-gated engine opens asleep; without the gate the ASR runs at once.
    _setStatus(_config.enableWake ? VoiceStatus.idle : VoiceStatus.listening);
  }

  /// Close the engine and release the microphone.
  Future<void> disable() async {
    if (!_service.isRunning) {
      // Clear a latched error so the button returns to its plain "off" look.
      if (_currentStatus != VoiceStatus.off) _setStatus(VoiceStatus.off);
      return;
    }
    await _service.stop();
    _setStatus(VoiceStatus.off);
  }

  /// Force the engine awake without the wake word ("tap to talk"). No-op unless
  /// the engine is open and wake-gated — an ungated engine is already awake.
  void wakeNow() {
    if (!_service.isRunning) return;
    _service.wakeEngine();
  }

  /// Put a wake-gated engine back to sleep. The engine emits `sleep`, which
  /// moves [status] to [VoiceStatus.idle].
  void sleepNow() {
    if (!_service.isRunning) return;
    _service.sleepEngine();
  }

  /// Speak a stream of text deltas (an LLM token stream) as it arrives: each
  /// complete sentence is synthesized while later ones are still streaming in.
  /// Cancels any speech already playing.
  Future<void> speak(Stream<String> textDeltas) async {
    if (!_service.isRunning) {
      logWarning('speak with the engine closed; dropping the reply');
      return;
    }
    await _service.speak(textDeltas);
  }

  /// Speak a single, already-complete string.
  Future<void> speakText(String text) async {
    if (!_service.isRunning) {
      logWarning('speakText with the engine closed; dropping "$text"');
      return;
    }
    await _service.speakText(text);
  }

  /// Barge-in: cancel the current reply and discard queued audio.
  Future<void> stopSpeaking() async {
    if (!_service.isRunning) return;
    await _service.stopSpeaking();
  }

  void _setStatus(VoiceStatus status) {
    // The engine emits `sleep` as it tears down, which would otherwise stomp
    // the `off` we just published.
    if (!_service.isRunning && status == VoiceStatus.idle) return;
    if (_currentStatus == status) return;
    _currentStatus = status;
    if (!_status.isClosed) _status.add(status);
  }

  Future<void> dispose() async {
    await _wakeSub.cancel();
    await _sleepSub.cancel();
    await _errorSub.cancel();
    await _status.close();
    await _service.dispose();
  }
}
