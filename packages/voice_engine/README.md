# voice_engine

A full-duplex local voice loop for Flutter desktop. The engine is Rust, Flutter talks to it through
FFI.

## Usage

```dart
import 'package:voice_engine/voice_engine.dart';

final controller = VoiceEngineController()
  ..init();

controller.transcripts.listen
(
(t) => print('heard: ${t.text}'));

await controller.open(VoiceEngineConfig(
asrModelDir: '/models/sense-voice',
ttsModelDir: '/models/vits-zh',
));

await controller.
speak
(
'
你好，我是娜娜。
'
);
```

`speak` synthesizes and plays the text while the AEC keeps that audio out of the
transcript stream, so there is no half-duplex muting. `stop()` is a barge-in:
it discards queued and in-flight TTS immediately.

Model files are **not** bundled — `VoiceEngineConfig` takes filesystem paths to a
SenseVoice ASR directory, a Silero VAD model, and (for the local TTS backend) a
VITS/Kokoro directory.

## Native engine

The `voice-engine` engine is **prebuilt** by a separate, private Rust repo.
Prebuilt binaries are provided for **Linux x64/arm64**, **macOS x64/arm64** and
**Windows x64**; other targets are unsupported.

Enable native assets in the consuming app:

```sh
flutter config --enable-native-assets
```

On Linux the engine needs `libasound.so.2` (ALSA) and `libstdc++.so.6` present at
runtime.

## The ABI contract

`src/voice_engine.h` is the contract of record. It must stay in lockstep with the
private repo's `crates/voice-engine/src/ffi.rs` and with the generated bindings:

```sh
dart run ffigen --config ffigen.yaml
```

A symbol the `.so` exports but the header omits is invisible to Dart, and
regenerating will silently delete any binding for it.
