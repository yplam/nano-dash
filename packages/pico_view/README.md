# pico_view

Mirror a Flutter widget subtree to an external **SPI LCD** driven over a
**CH347 USB bridge**, and feed physical capacitive-touch events from the panel
back into that same subtree. The display/touch engine is Rust; Flutter talks to
it through FFI.

## Usage

```dart
import 'package:pico_view/pico_view.dart';

final controller = PicoViewController()
  ..init();
controller.open
(
const PicoViewConfig());

// Anywhere in your tree:
PicoView(
controller: controller,
child: const MyDashboard(),
);
```

The child is laid out at exactly the LCD's logical resolution
(`controller.config.width` x `.height`), so a captured pixel maps 1:1 to a panel
pixel and a panel touch maps 1:1 to a child-local coordinate. If no device is
open, frames are dropped and the widget still renders on-screen.

## Native engine

The `pico-view` engine is **prebuilt** and committed under `native/`.
Prebuilt binaries are provided for **Linux x64/arm64**, **macOS arm64** and
**Windows x64**; other targets are unsupported. The Dart build hook
(`hook/build.dart`) just links the prebuilt library for the target as a native
code asset. Enable native assets in the consuming app:

```sh
flutter config --enable-native-assets
```

On Windows the CH347 driver ships as a runtime DLL data asset; on Linux and
macOS the WCH library is statically linked into the prebuilt engine.

Regenerate the FFI bindings after the ABI in `src/pico_view.h` changes (no Rust
required):

```sh
dart run ffigen --config ffigen.yaml
```
