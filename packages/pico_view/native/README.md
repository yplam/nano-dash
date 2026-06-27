# Prebuilt `pico-view` engine binaries

These are the compiled, committed artifacts of the **private** `pico-view`
Rust repository. They are the only form of the engine that ships in this
open-source package — the Rust source is intentionally not present here.

```
native/
  linux/{x64,arm64}/libpico_view.so
  macos/arm64/libpico_view.dylib      # produced by a macOS/CI runner
  windows/x64/pico_view.dll           # produced by a Windows/CI runner
  windows/x64/CH347DLLA64.DLL         # CH347 runtime driver (redistributable)
```

`hook/build.dart` picks the file matching the build target and bundles it as the
`package:pico_view/src/pico_view_bindings_generated.dart` code asset.
