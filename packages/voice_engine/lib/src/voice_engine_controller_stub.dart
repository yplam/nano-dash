/// Web [VoiceEngineController]: a no-op stub. The engine is native-only (audio
/// capture/playback + ASR/TTS reached over `dart:ffi`), none of which exists on
/// the web, so [open] throws [VoiceEngineException] and every other member is
/// inert — callers that guard opening (see `VoiceService`) degrade to
/// "unavailable" instead of crashing.
///
/// Selected on the web by [voice_engine_controller.dart]; native builds get
/// [voice_engine_controller_io.dart].
library;

import 'dart:async';

import 'voice_engine_types.dart';

export 'voice_engine_types.dart';

/// See [voice_engine_controller_io.dart] for the behaving implementation. This
/// mirrors its public surface so the app compiles on the web.
class VoiceEngineController {
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

  bool _disposed = false;

  Stream<VoiceTranscript> get transcripts => _transcripts.stream;

  Stream<String> get errors => _errors.stream;

  Stream<bool> get ready => _ready.stream;

  Stream<bool> get speaking => _speaking.stream;

  bool get isSpeaking => false;

  double get speakingLevel => 0.0;

  Stream<String?> get wake => _wake.stream;

  Stream<void> get sleep => _sleep.stream;

  Stream<EnrollmentResult> get enrolled => _enrolled.stream;

  bool get isOpen => false;

  void init() {}

  Future<void> open(VoiceEngineConfig config) {
    throw VoiceEngineException('voice engine is not supported on the web');
  }

  Future<void> speak(Stream<String> textDeltas) async {
    throw VoiceEngineException('voice engine is not supported on the web');
  }

  Future<void> speakText(String text) async {}

  void sleepEngine() {}

  void wakeEngine() {}

  void enrollBegin() {}

  void enrollEnd([String name = '']) {}

  void enrollReset([String name = '']) {}

  Future<void> stop() async {}

  Future<void> close() async {}

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _transcripts.close();
    _errors.close();
    _ready.close();
    _speaking.close();
    _wake.close();
    _sleep.close();
    _enrolled.close();
  }
}
