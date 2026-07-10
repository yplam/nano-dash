import 'dart:io';

import 'package:code_assets/code_assets.dart';
import 'package:crypto/crypto.dart';
import 'package:hooks/hooks.dart';

// This package ships the `voice-engine` engine as a PREBUILT library produced by
// the private Rust repo. The cdylib statically links onnxruntime and weighs ~32 MB
// per target, which would add ~60 MB to this repo's history on every refresh.
//
// So the hook downloads it. For the build target it resolves the release asset,
// fetches it from the public nano-dash release page, verifies it against the
// SHA-256 pinned in `native/engine.lock`, and caches it.

/// The asset id the `@ffi.Native` lookups in the generated bindings resolve
/// against. Must match `lib/src/voice_engine_bindings_generated.dart`.
const _assetName = 'src/voice_engine_bindings_generated.dart';

/// Pins the release tag and the per-target digests.
const _lockPath = 'native/engine.lock';

/// Escape hatch for engine development: a gitignored file holding the path to a
/// locally built cdylib, linked as-is with no digest check. Takes precedence
/// over [_overrideKey].
const _localPath = 'native/engine.local';

/// The same escape hatch as [_localPath], as a `hooks.user_defines.voice_engine`
/// key in the app's pubspec.yaml.
const _overrideKey = 'engine_lib';

void main(List<String> args) async {
  await build(args, (input, output) async {
    // In some invocations (e.g. `flutter run` in debug) the hook runs with code
    // assets disabled. Accessing `input.config.code` then throws, so bail early
    // when there is nothing for us to register.
    if (!input.config.buildCodeAssets) return;

    final code = input.config.code;
    final lockUri = input.packageRoot.resolve(_lockPath);
    final localUri = input.packageRoot.resolve(_localPath);

    // A directory dependency hashes its child names, so creating or deleting
    // `engine.local` re-runs this hook. The file itself cannot be declared
    // unconditionally: a missing dependency reports a modification time of
    // `now`, which the runner reads as "modified during the build".
    output.dependencies.add(input.packageRoot.resolve('native/'));

    final Uri libUri;
    final override = _localOverride(localUri) ?? _defineOverride(input);
    if (override != null) {
      final file = File.fromUri(override.lib);
      if (!file.existsSync()) {
        throw ArgumentError(
          '${override.origin} points at a file that does not exist: '
              '${file.path}',
        );
      }
      libUri = file.absolute.uri;
      // Relink when the local engine is rebuilt, or when the file naming it is
      // edited to name a different one.
      output.dependencies.add(libUri);
      if (override.sourceFile != null) {
        output.dependencies.add(override.sourceFile!);
      }
    } else {
      final lock = _EngineLock.parse(File.fromUri(lockUri), lockUri);
      final asset = _assetFor(code.targetOS, code.targetArchitecture);
      libUri = await _resolve(
        lock: lock,
        asset: asset,
        // The hook invoker serializes concurrent invocations on this directory,
        // and nothing else writes to it, so it is safe as a download cache. It
        // survives across builds, unlike `input.outputDirectory`.
        cacheDir: input.outputDirectoryShared,
      );
      // A new tag or digest must force a re-resolve.
      output.dependencies.add(lockUri);
    }

    output.assets.code.add(
      CodeAsset(
        package: input.packageName,
        name: _assetName,
        linkMode: DynamicLoadingBundled(),
        file: libUri,
      ),
    );
  });
}

/// A locally built engine to link in place of the pinned release.
class _Override {
  const _Override({required this.lib, required this.origin, this.sourceFile});

  /// Resolved location of the cdylib.
  final Uri lib;

  /// Where the path came from, for error messages.
  final String origin;

  /// The file naming [lib], when the hook must declare it as a dependency
  /// itself. Null for user-defines: the runner already tracks the pubspec.
  final Uri? sourceFile;
}

/// Reads the gitignored [_localPath], if present. The first non-empty,
/// non-comment line is a path to a cdylib, resolved against that file's own
/// directory so a relative path works from any cwd.
_Override? _localOverride(Uri localUri) {
  final file = File.fromUri(localUri);
  if (!file.existsSync()) return null;

  for (final raw in file.readAsLinesSync()) {
    final line = raw.trim();
    if (line.isEmpty || line.startsWith('#')) continue;
    return _Override(
      // `Uri.file` escapes spaces and, on Windows, flips separators. A relative
      // path resolves against `localUri`; an absolute one replaces it outright.
      lib: localUri.resolveUri(Uri.file(line, windows: Platform.isWindows)),
      origin: _localPath,
      sourceFile: localUri,
    );
  }
  throw StateError(
    '$_localPath holds no path. Write the path to a locally built cdylib '
        'into it, or delete it to use the release pinned in $_lockPath.',
  );
}

/// Reads the `hooks.user_defines.voice_engine.engine_lib` path from the app's
/// pubspec.yaml, if set. Already resolved against that file's directory.
_Override? _defineOverride(BuildInput input) {
  final uri = input.userDefines.path(_overrideKey);
  if (uri == null) return null;
  return _Override(
    lib: uri,
    origin: 'hooks.user_defines.voice_engine.$_overrideKey',
  );
}

/// Returns the cached library for [asset], downloading it from the release page
/// if it is absent or fails its digest check.
Future<Uri> _resolve({
  required _EngineLock lock,
  required String asset,
  required Uri cacheDir,
}) async {
  final expected = lock.digests[asset];
  if (expected == null) {
    throw StateError(
      'No SHA-256 pinned for "$asset" in $_lockPath.\n'
          'Publish a release from the private voice-engine repo, then copy its '
          'SHA256SUMS into that file.\n'
          'For local engine development, write the path to a locally built library '
          'into $_localPath.',
    );
  }

  // Key the cache on the tag so a bumped release does not collide with a stale
  // download of the same asset name.
  final cached = File.fromUri(cacheDir.resolve('${lock.tag}/$asset'));
  if (cached.existsSync() && _sha256(cached) == expected) {
    return cached.absolute.uri;
  }

  final url = Uri.parse(
    'https://github.com/${lock.repo}/releases/download/${lock.tag}/$asset',
  );
  await cached.parent.create(recursive: true);

  // Download to a sibling temp file and rename, so an interrupted build can
  // never leave a truncated library in the cache.
  final temp = File('${cached.path}.$pid.tmp');
  try {
    await _download(url, temp);
    final actual = _sha256(temp);
    if (actual != expected) {
      throw StateError(
        'Digest mismatch for $url\n'
            '  expected $expected (from $_lockPath)\n'
            '  actual   $actual\n'
            'The release asset was replaced, or $_lockPath is stale.',
      );
    }
    await temp.rename(cached.path);
  } finally {
    if (temp.existsSync()) await temp.delete();
  }
  return cached.absolute.uri;
}

Future<void> _download(Uri url, File dest) async {
  final client = HttpClient();
  try {
    // The hook runner forwards the proxy environment variables, but HttpClient
    // ignores them unless asked. Without this, a build behind a proxy hangs.
    client.findProxy = (uri) =>
        HttpClient.findProxyFromEnvironment(
          uri,
          environment: Platform.environment,
        );
    // GitHub redirects release downloads to its object store; HttpClient follows
    // redirects by default.
    final response = await (await client.getUrl(url)).close();
    if (response.statusCode != HttpStatus.ok) {
      throw HttpException(
        'GET $url failed with HTTP ${response.statusCode}. '
            'Is the release published and the asset name correct?',
        uri: url,
      );
    }
    await response.pipe(dest.openWrite());
  } finally {
    client.close();
  }
}

String _sha256(File file) => sha256.convert(file.readAsBytesSync()).toString();

/// The release asset name for [os]/[arch], matching the private repo's
/// `.github/workflows/release.yml` matrix.
///
/// Prebuilt binaries exist only for Linux x64/arm64, macOS x64/arm64 and
/// Windows x64; anything else throws.
String _assetFor(OS os, Architecture arch) {
  if (os == OS.linux &&
      (arch == Architecture.x64 || arch == Architecture.arm64)) {
    return 'libvoice_engine-${_triple(os, arch)}.so';
  }
  if (os == OS.macOS &&
      (arch == Architecture.x64 || arch == Architecture.arm64)) {
    return 'libvoice_engine-${_triple(os, arch)}.dylib';
  }
  if (os == OS.windows && arch == Architecture.x64) {
    return 'voice_engine-${_triple(os, arch)}.dll';
  }
  throw UnsupportedError('voice_engine has no prebuilt engine for $os/$arch');
}

String _triple(OS os, Architecture arch) {
  final cpu = arch == Architecture.x64 ? 'x86_64' : 'aarch64';
  if (os == OS.linux) return '$cpu-unknown-linux-gnu';
  if (os == OS.macOS) return '$cpu-apple-darwin';
  return '$cpu-pc-windows-msvc';
}

/// The parsed `native/engine.lock`: a release coordinate plus the SHA-256 of each
/// asset, in `sha256sum` output format so a published `SHA256SUMS` can be pasted
/// in verbatim.
class _EngineLock {
  _EngineLock({required this.repo, required this.tag, required this.digests});

  /// `owner/name` of the public repo hosting the release assets.
  final String repo;

  /// Release tag, e.g. `voice-engine-v0.1.0`.
  final String tag;

  /// Asset file name -> lowercase hex SHA-256.
  final Map<String, String> digests;

  static _EngineLock parse(File file, Uri uri) {
    if (!file.existsSync()) {
      throw StateError('Missing $_lockPath at $uri');
    }
    String? repo;
    String? tag;
    final digests = <String, String>{};

    for (final raw in file.readAsLinesSync()) {
      final line = raw.trim();
      if (line.isEmpty || line.startsWith('#')) continue;

      // `key = value` settings, vs `<digest>  <name>` checksum lines. A digest
      // is hex, so an `=` can only belong to a setting.
      final eq = line.indexOf('=');
      if (eq != -1) {
        final key = line.substring(0, eq).trim();
        final value = line.substring(eq + 1).trim();
        if (key == 'repo') repo = value;
        if (key == 'tag') tag = value;
        continue;
      }

      final parts = line.split(RegExp(r'\s+'));
      if (parts.length != 2) {
        throw FormatException('Cannot parse $_lockPath line: $raw');
      }
      // sha256sum prefixes binary-mode names with `*`.
      digests[parts[1].replaceFirst(RegExp(r'^\*'), '')] = parts[0];
    }

    if (repo == null || tag == null) {
      throw StateError('$_lockPath must set both `repo` and `tag`.');
    }
    return _EngineLock(repo: repo, tag: tag, digests: digests);
  }
}
