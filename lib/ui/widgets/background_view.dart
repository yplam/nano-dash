import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    if (kIsWeb || path.isEmpty) {
      return Image.asset('assets/bg.png', fit: fit);
    }
    return Image.file(
      File(path),
      fit: fit,
      gaplessPlayback: true,
      errorBuilder: (context, error, stack) =>
          Image.asset('assets/bg.png', fit: fit),
    );
  }
}
