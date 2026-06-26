import 'package:flutter/widgets.dart';

/// The panel's display typeface, matching the clock module: a variable-weight
/// font with tabular figures so digits don't jitter as they tick.
TextStyle panelFont(
  double size,
  double weight,
  Color color, {
  double height = 1,
}) {
  return TextStyle(
    fontFamily: 'Nunito',
    fontSize: size,
    height: height,
    color: color,
    fontVariations: [FontVariation('wght', weight)],
    fontFeatures: const [FontFeature.tabularFigures()],
  );
}
