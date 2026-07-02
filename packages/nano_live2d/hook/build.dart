import 'dart:io';

import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';

const _assetName = 'src/nano_live2d_bindings_generated.dart';

void main(List<String> args) async {
  await build(args, (input, output) async {
    if (!input.config.buildCodeAssets) return;

    final code = input.config.code;
    final relative = _engineLibrary(code.targetOS, code.targetArchitecture);
    final file = input.packageRoot.resolve(relative);
    if (!File.fromUri(file).existsSync()) {
      throw StateError(
        'Missing prebuilt ${file.toFilePath()}. Build it from the private '
        'nano_live2d native repo and commit it under native/ '
        '(see packages/nano_live2d/native/README.md).',
      );
    }

    output.assets.code.add(
      CodeAsset(
        package: input.packageName,
        name: _assetName,
        linkMode: DynamicLoadingBundled(),
        file: file,
      ),
    );
    // Rebuild dependents when the committed binary changes.
    output.dependencies.add(file);
  });
}

/// Resolves the prebuilt engine library for [os]/[arch] under `native/`.
String _engineLibrary(OS os, Architecture arch) {
  if (os == OS.linux && arch == Architecture.x64) {
    return 'native/linux/x64/libnano_live2d.so';
  }
  if (os == OS.macOS &&
      (arch == Architecture.arm64 || arch == Architecture.x64)) {
    return 'native/macos/${_archDir(arch)}/libnano_live2d.dylib';
  }
  if (os == OS.windows && arch == Architecture.x64) {
    return 'native/windows/x64/nano_live2d.dll';
  }
  throw UnsupportedError('nano_live2d has no prebuilt engine for $os/$arch');
}

String _archDir(Architecture arch) {
  if (arch == Architecture.x64) return 'x64';
  if (arch == Architecture.arm64) return 'arm64';
  throw UnsupportedError('nano_live2d has no prebuilt engine for $arch');
}
