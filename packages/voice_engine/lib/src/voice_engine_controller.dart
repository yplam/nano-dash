/// [VoiceEngineController]: owns the FFI lifecycle (init / open / speak / stop /
/// close) and the event channel for the native full-duplex voice engine.
library;

export 'voice_engine_controller_stub.dart'
    if (dart.library.io) 'voice_engine_controller_io.dart';
