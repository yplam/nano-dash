# Prebuilt `nano_live2d` engine binaries

These are the compiled, committed artifacts of the **private** `nano_live2d`
native (C++) repository.

```
native/
  linux/x64/libnano_live2d.so
  macos/arm64/libnano_live2d.dylib    # produced by a macOS/CI runner (arm64 slice)
  macos/x64/libnano_live2d.dylib      # produced by a macOS/CI runner (x86_64 slice)
  windows/x64/nano_live2d.dll         # produced by a Windows/CI runner
```

`hook/build.dart` picks the file matching the build target and bundles it as the
`package:nano_live2d/src/nano_live2d_bindings_generated.dart` code asset.
