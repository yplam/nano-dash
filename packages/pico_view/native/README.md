# Prebuilt `pico-view` engine binaries

These are the compiled, committed artifacts of the **private** `pico-view`
Rust repository. They are the only form of the engine that ships in this
open-source package — the Rust source is intentionally not present here.

```
native/
  linux/{x64,arm64}/libpico_view.so
  macos/{x64,arm64}/libpico_view.dylib   # produced by a macOS/CI runner
  windows/x64/pico_view.dll              # produced by a Windows/CI runner
```

`hook/build.dart` picks the file matching the build target and bundles it as the
`package:pico_view/src/pico_view_bindings_generated.dart` code asset. The engine
talks to the panel over a **driverless USB** link (WinUSB on Windows, libusb on
macOS, a udev rule on Linux), so no separate runtime driver ships alongside it.
