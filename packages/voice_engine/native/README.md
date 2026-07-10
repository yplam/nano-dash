# Prebuilt `voice-engine` binaries

The `voice-engine` cdylib statically links onnxruntime and weighs ~32 MB per target,
so committing all five would add ~60 MB to this repository's history on every
engine refresh.

`engine.lock` pins a release tag and the SHA-256 of each asset, and
`../hook/build.dart` downloads the one matching the build target from the
nano-dash release page, verifies it, and caches it. A download that does not
match its pinned digest is never linked.

```
libvoice_engine-x86_64-unknown-linux-gnu.so
libvoice_engine-aarch64-unknown-linux-gnu.so
libvoice_engine-aarch64-apple-darwin.dylib
libvoice_engine-x86_64-apple-darwin.dylib
voice_engine-x86_64-pc-windows-msvc.dll
```

## Runtime dependencies

The engine links sherpa-onnx and onnxruntime statically, so there is no sidecar
library to bundle. It does need, at runtime:

- **Linux:** `libasound.so.2` (ALSA, via cpal) and `libstdc++.so.6`. Artifacts are
  built on `ubuntu-22.04`, so their glibc floor is 2.35.
- **macOS / Windows:** system audio frameworks only.

## Local engine development

To link a locally built engine instead of a released one, build it in the private
repo (`./build.sh`), then write its path into `engine.local`.

```sh
echo ../../../../voice-engine/target/x86_64-unknown-linux-gnu/release/libvoice_engine.so \
  > packages/voice_engine/native/engine.local
```

The download and the digest check are both skipped for that path — it is linked
as-is. Rebuilding the engine relinks it; deleting `engine.local` returns to the
release pinned in `engine.lock`. Both are build-hook dependencies, so no
`flutter clean` is needed either way.
