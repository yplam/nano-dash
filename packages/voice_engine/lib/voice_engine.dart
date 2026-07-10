/// voice_engine: a full-duplex local voice loop  exposed to Flutter through a small FFI surface.
///
/// [VoiceEngineController] owns the FFI lifecycle (init / open / speak / stop /
/// close). Recognized speech arrives on its `transcripts` stream; reply text fed
/// to `speak`/`speakText` is synthesized and played, with the AEC keeping the
/// played reply out of the transcript.
library;

export 'src/voice_engine_controller.dart';
