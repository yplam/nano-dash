import 'package:flutter/widgets.dart';

/// CJK font fallbacks so Chinese glyphs render without embedding a font file.
/// Nunito (the panel typeface) is Latin-only, so any CJK text — and the app's
/// default locale is `zh` — must fall through to a system CJK face. Applied both
/// app-wide (via `ThemeData.fontFamilyFallback`) and per [panelFont] call, since
/// a `TextStyle` that sets its own `fontFamily` does not inherit the theme's.
const List<String> kCjkFontFallback = <String>[
  'PingFang SC', // macOS / iOS
  'Microsoft YaHei', // Windows
  'Noto Sans CJK SC', // Linux (Noto package)
  'Noto Sans SC', // Linux alt naming
  'Source Han Sans SC', // Linux alt
  'WenQuanYi Micro Hei', // Linux fallback
];

/// The panel's display typeface, matching the clock module: a variable-weight
/// font with tabular figures so digits don't jitter as they tick. Nunito draws
/// the Latin/digit glyphs; CJK glyphs fall through to [kCjkFontFallback].
TextStyle panelFont(
  double size,
  double weight,
  Color color, {
  double height = 1,
}) {
  return TextStyle(
    fontFamily: 'Nunito',
    fontFamilyFallback: kCjkFontFallback,
    fontSize: size,
    height: height,
    color: color,
    fontVariations: [FontVariation('wght', weight)],
    fontFeatures: const [FontFeature.tabularFigures()],
  );
}
