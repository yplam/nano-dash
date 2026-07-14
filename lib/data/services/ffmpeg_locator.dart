import 'dart:io';

/// Resolves which `ffmpeg` executable the Video module should run.
///
/// The app does not bundle ffmpeg (a static build is ~130 MB), so playback
/// relies on an ffmpeg the user already has. The chosen command is stored in
/// the Video module's settings: when the user sets it explicitly we use it
/// verbatim; when it's empty we auto-detect an `ffmpeg` on `PATH`, falling back
/// to the bare name `ffmpeg` (letting the OS resolve it) if the scan finds none.
class FfmpegLocator {
  const FfmpegLocator._();

  /// Resolve the ffmpeg command to run.
  ///
  /// [configured] is the Video module's chosen path/command: used as given when
  /// non-empty, otherwise auto-detection kicks in.
  static String resolve(String? configured) {
    final chosen = configured?.trim() ?? '';
    if (chosen.isNotEmpty) return chosen;
    return autoDetect() ?? 'ffmpeg';
  }

  /// Search `PATH` for an executable `ffmpeg`, returning its absolute path or
  /// null if none is found. Also probes a couple of common install locations
  /// that aren't always on a GUI app's `PATH` (e.g. Homebrew on macOS).
  static String? autoDetect() {
    final exe = Platform.isWindows ? 'ffmpeg.exe' : 'ffmpeg';
    final sep = Platform.isWindows ? ';' : ':';
    final dirs = <String>[
      ...?Platform.environment['PATH']?.split(sep),
      if (!Platform.isWindows) '/usr/local/bin',
      if (!Platform.isWindows) '/usr/bin',
      if (!Platform.isWindows) '/opt/homebrew/bin',
    ];
    for (final dir in dirs) {
      if (dir.isEmpty) continue;
      final candidate = File('$dir${Platform.pathSeparator}$exe');
      if (candidate.existsSync()) return candidate.path;
    }
    return null;
  }
}
