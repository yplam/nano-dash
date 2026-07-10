import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// Shipped background, used when no file is chosen and whenever one can't be read.
const String _kFallbackAsset = 'assets/bg.png';

/// How long the first frame may wait on the background decode.
const Duration _kPrecacheBudget = Duration(seconds: 2);

/// The shared dashboard background.
///
/// Renders the user-chosen image at [path] (a static PNG/JPEG/WebP, or an animated GIF/WebP.
class BackgroundView extends StatelessWidget {
  const BackgroundView({
    super.key,
    required this.path,
    this.fit = BoxFit.cover,
  });

  final String path;
  final BoxFit fit;

  /// Decode the background for [path] into the image cache.
  static Future<void> precache(String path) async {
    final provider = _providerFor(path);
    final loaded = await _decode(provider).timeout(
      _kPrecacheBudget,
      // A background on a slow or unmounted path must not hold the window back.
      // Giving up only restores the pop-in this method exists to avoid.
      onTimeout: () => true,
    );
    if (loaded || provider is! FileImage) return;
    // The chosen file is gone or undecodable, so [build] falls back to the
    // bundled asset — warm that instead.
    await _decode(const AssetImage(_kFallbackAsset));
  }

  /// The provider painted for [path]. Shared with [precache] so both address the
  /// same [ImageCache] entry.
  static ImageProvider _providerFor(String path) => kIsWeb || path.isEmpty
      ? const AssetImage(_kFallbackAsset)
      : FileImage(File(path));

  /// Resolve [provider] into the image cache, reporting whether it loaded.
  static Future<bool> _decode(ImageProvider provider) {
    final completer = Completer<bool>();
    final stream = provider.resolve(ImageConfiguration.empty);
    ImageStreamListener? listener;
    void finish(bool loaded) {
      stream.removeListener(listener!);
      if (!completer.isCompleted) completer.complete(loaded);
    }

    listener = ImageStreamListener((image, _) {
      // The cache keeps its own handle; this one is ours to drop.
      image.dispose();
      finish(true);
    }, onError: (_, _) => finish(false));
    stream.addListener(listener);
    return completer.future;
  }

  @override
  Widget build(BuildContext context) {
    final provider = _providerFor(path);
    if (provider is! FileImage) {
      return Image(image: provider, fit: fit);
    }
    return Image(
      image: provider,
      fit: fit,
      gaplessPlayback: true,
      errorBuilder: (context, error, stack) =>
          Image(image: const AssetImage(_kFallbackAsset), fit: fit),
    );
  }
}
