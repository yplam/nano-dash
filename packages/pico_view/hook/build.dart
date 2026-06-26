import 'package:code_assets/code_assets.dart';
import 'package:data_assets/data_assets.dart';
import 'package:hooks/hooks.dart';

// This package ships the `pico-view` engine as PREBUILT libraries under
// `native/` (produced by the private Rust repo, not compiled here). The hook's
// only job is to register the right prebuilt library for the target as a code
// asset, under the same id the generated bindings already expect:
//
//   package:pico_view/src/pico_view_bindings_generated.dart
//
// The `@ffi.Native` lookups in lib/src/pico_view_bindings_generated.dart resolve
// against that asset, so swapping the build-from-source step for a prebuilt link
// is transparent to the Dart side.
void main(List<String> args) async {
  await build(args, (input, output) async {
    // In some invocations (e.g. `flutter run` in debug) the hook runs with code
    // assets disabled. Accessing `input.config.code` then throws, so bail early
    // when there is nothing for us to register.
    if (!input.config.buildCodeAssets) return;

    final code = input.config.code;
    final lib = _engineLibrary(code.targetOS, code.targetArchitecture);
    final file = input.packageRoot.resolve(lib.path);

    output.assets.code.add(
      CodeAsset(
        package: input.packageName,
        name: 'src/pico_view_bindings_generated.dart',
        linkMode: DynamicLoadingBundled(),
        file: file,
      ),
    );
    // Rebuild dependents when the committed binary changes.
    output.dependencies.add(file);

    // On Windows the CH347 driver is linked through an import library, so the
    // matching DLL has to ship as a separate runtime file. Emit it as a data
    // asset so the SDK bundles it with the application.
    if (input.config.buildDataAssets && code.targetOS == OS.windows) {
      output.assets.data.add(
        DataAsset(
          package: input.packageName,
          name: 'ch347/CH347DLLA64.DLL',
          file: input.packageRoot.resolve('native/windows/x64/CH347DLLA64.DLL'),
        ),
      );
    }
  });
}

/// Resolves the prebuilt engine library for [os]/[arch] under `native/`.
///
/// Prebuilt binaries exist only for Linux x64/arm64, macOS arm64 and
/// Windows x64; anything else throws.
({String path}) _engineLibrary(OS os, Architecture arch) {
  if (os == OS.linux &&
      (arch == Architecture.x64 || arch == Architecture.arm64)) {
    return (path: 'native/linux/${_archDir(arch)}/libpico_view.so');
  }
  if (os == OS.macOS && arch == Architecture.arm64) {
    return (path: 'native/macos/${_archDir(arch)}/libpico_view.dylib');
  }
  if (os == OS.windows && arch == Architecture.x64) {
    return (path: 'native/windows/${_archDir(arch)}/pico_view.dll');
  }
  throw UnsupportedError('pico_view has no prebuilt engine for $os/$arch');
}

String _archDir(Architecture arch) {
  if (arch == Architecture.x64) return 'x64';
  if (arch == Architecture.arm64) return 'arm64';
  throw UnsupportedError('pico_view has no prebuilt engine for $arch');
}
