import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// The content rectangle a page carves out of the round panel. Each is the
/// largest centred rectangle of that aspect that fits inside the circle (its
/// corners sit on the rim), so content never spills past the visible glass.
///
/// The math: a centred W×H rectangle fits iff `W² + H² ≤ side²` (its diagonal
/// is the diameter at the maximum), and the per-edge inset is `(side − dim)/2`.
///
///  * [square] — `W = H = side/√2`; inset ≈ `0.146·side` on every edge. Balanced
///    content, e.g. the clock.
///  * [landscape] — a 4:3 rectangle (`0.8·side × 0.6·side`, a 3-4-5 triangle);
///    wide and short, for horizontally-laid **info items** (the monitor cards).
///  * [portrait] — 3:4, the transpose; narrow and tall, giving a scrollable
///    **list** the most vertical room (the timer list).
enum PanelShape { square, landscape, portrait }

/// Shared visual vocabulary for the panel modules (timer, system monitor, …) so
/// they read as one surface. Split in two on purpose:
///
///  * Spacing, font sizes, and other resolution-independent tokens — alphas,
///    font weights, corner radii — are stored as **fixed pixel literals**. The
///    panels this app drives sit close to their native pixel size, so fonts,
///    gaps, and card padding read best at a constant physical size rather than
///    scaling with the panel.
///  * The per-page insets stay *ratios of `side`* (the min of the panel's
///    width/height, taken from a `LayoutBuilder`), because they encode the
///    round-panel geometry — the largest rectangle of each aspect inscribed in
///    the circle — and must track the actual panel size.
///
/// Call [resolve] once per build with the panel's `side` and the page's
/// [PanelShape] to flatten both halves into a [PanelMetrics] with concrete
/// pixel values.
@immutable
class PanelTheme extends ThemeExtension<PanelTheme> {
  const PanelTheme({
    // Alphas for the layered, semi-transparent surfaces.
    this.cardAlpha = 0.5,
    this.pillAlpha = 0.6,
    this.chartFillAlpha = 0.15,
    // Absolute corner radii (small enough to read fine unscaled).
    this.cardRadius = 16,
    this.pillRadius = 20,
    // Variable-font weights.
    this.weightRegular = 500,
    this.weightMedium = 600,
    this.weightBold = 700,
    // Per-edge page insets as a fraction of `side`, one pair per [PanelShape]:
    // the largest rectangle of that aspect inscribed in the round panel.
    this.squareInset = 0.146,
    this.landscapeInsetH = 0.10,
    this.landscapeInsetV = 0.20,
    this.portraitInsetH = 0.20,
    this.portraitInsetV = 0.10,
    // Extra inset (fraction of `side`) added to every page edge so the inscribed
    // rectangle's corners pull in off the rim rather than kissing the bezel.
    this.safeMargin = 0.03,
    // Card padding in fixed pixels, in three sizes (horizontal, vertical).
    this.cardPadSmH = 10,
    this.cardPadSmV = 6,
    this.cardPadMdH = 14,
    this.cardPadMdV = 10,
    this.cardPadLgH = 18,
    this.cardPadLgV = 14,
    this.gap = 10,
    // Font sizes in fixed pixels.
    this.fontXs = 10,
    this.fontSm = 12,
    this.fontMd = 16,
    this.fontLg = 18,
    this.fontXl = 20,
  });

  final double cardAlpha;
  final double pillAlpha;
  final double chartFillAlpha;
  final double cardRadius;
  final double pillRadius;
  final double weightRegular;
  final double weightMedium;
  final double weightBold;
  final double squareInset;
  final double landscapeInsetH;
  final double landscapeInsetV;
  final double portraitInsetH;
  final double portraitInsetV;
  final double safeMargin;
  final double cardPadSmH;
  final double cardPadSmV;
  final double cardPadMdH;
  final double cardPadMdV;
  final double cardPadLgH;
  final double cardPadLgV;
  final double gap;
  final double fontXs;
  final double fontSm;
  final double fontMd;
  final double fontLg;
  final double fontXl;

  /// The page inset for [shape], resolved against [side], with [safeMargin]
  /// folded into every edge so the inscribed rectangle clears the rim.
  EdgeInsets pageInsetFor(PanelShape shape, double side) {
    final m = safeMargin;
    return switch (shape) {
      PanelShape.square => EdgeInsets.all(side * (squareInset + m)),
      PanelShape.landscape => EdgeInsets.symmetric(
        horizontal: side * (landscapeInsetH + m),
        vertical: side * (landscapeInsetV + m),
      ),
      PanelShape.portrait => EdgeInsets.symmetric(
        horizontal: side * (portraitInsetH + m),
        vertical: side * (portraitInsetV + m),
      ),
    };
  }

  /// Resolve the page inset for [shape] against [side] (= `min(width, height)`)
  /// and copy the fixed-pixel spacing/font tokens through unchanged.
  PanelMetrics resolve(double side, PanelShape shape) => PanelMetrics(
    pageInset: pageInsetFor(shape, side),
    cardPaddingSm: EdgeInsets.symmetric(
      horizontal: cardPadSmH,
      vertical: cardPadSmV,
    ),
    cardPaddingMd: EdgeInsets.symmetric(
      horizontal: cardPadMdH,
      vertical: cardPadMdV,
    ),
    cardPaddingLg: EdgeInsets.symmetric(
      horizontal: cardPadLgH,
      vertical: cardPadLgV,
    ),
    gap: gap,
    fontXs: fontXs,
    fontSm: fontSm,
    fontMd: fontMd,
    fontLg: fontLg,
    fontXl: fontXl,
    cardRadius: cardRadius,
    pillRadius: pillRadius,
    cardAlpha: cardAlpha,
    pillAlpha: pillAlpha,
    chartFillAlpha: chartFillAlpha,
    weightRegular: weightRegular,
    weightMedium: weightMedium,
    weightBold: weightBold,
  );

  /// Convenience: read the extension and resolve in one step. [shape] selects
  /// the inscribed content rectangle for the page (defaults to [square]).
  static PanelMetrics metricsOf(
    BuildContext context,
    double side, {
    PanelShape shape = PanelShape.square,
  }) => (Theme.of(context).extension<PanelTheme>() ?? const PanelTheme())
      .resolve(side, shape);

  @override
  PanelTheme copyWith({
    double? cardAlpha,
    double? pillAlpha,
    double? chartFillAlpha,
    double? cardRadius,
    double? pillRadius,
    double? weightRegular,
    double? weightMedium,
    double? weightBold,
    double? squareInset,
    double? landscapeInsetH,
    double? landscapeInsetV,
    double? portraitInsetH,
    double? portraitInsetV,
    double? safeMargin,
    double? cardPadSmH,
    double? cardPadSmV,
    double? cardPadMdH,
    double? cardPadMdV,
    double? cardPadLgH,
    double? cardPadLgV,
    double? gap,
    double? fontXs,
    double? fontSm,
    double? fontMd,
    double? fontLg,
    double? fontXl,
  }) => PanelTheme(
    cardAlpha: cardAlpha ?? this.cardAlpha,
    pillAlpha: pillAlpha ?? this.pillAlpha,
    chartFillAlpha: chartFillAlpha ?? this.chartFillAlpha,
    cardRadius: cardRadius ?? this.cardRadius,
    pillRadius: pillRadius ?? this.pillRadius,
    weightRegular: weightRegular ?? this.weightRegular,
    weightMedium: weightMedium ?? this.weightMedium,
    weightBold: weightBold ?? this.weightBold,
    squareInset: squareInset ?? this.squareInset,
    landscapeInsetH: landscapeInsetH ?? this.landscapeInsetH,
    landscapeInsetV: landscapeInsetV ?? this.landscapeInsetV,
    portraitInsetH: portraitInsetH ?? this.portraitInsetH,
    portraitInsetV: portraitInsetV ?? this.portraitInsetV,
    safeMargin: safeMargin ?? this.safeMargin,
    cardPadSmH: cardPadSmH ?? this.cardPadSmH,
    cardPadSmV: cardPadSmV ?? this.cardPadSmV,
    cardPadMdH: cardPadMdH ?? this.cardPadMdH,
    cardPadMdV: cardPadMdV ?? this.cardPadMdV,
    cardPadLgH: cardPadLgH ?? this.cardPadLgH,
    cardPadLgV: cardPadLgV ?? this.cardPadLgV,
    gap: gap ?? this.gap,
    fontXs: fontXs ?? this.fontXs,
    fontSm: fontSm ?? this.fontSm,
    fontMd: fontMd ?? this.fontMd,
    fontLg: fontLg ?? this.fontLg,
    fontXl: fontXl ?? this.fontXl,
  );

  @override
  PanelTheme lerp(covariant PanelTheme? other, double t) {
    if (other == null) return this;
    double d(double a, double b) => lerpDouble(a, b, t)!;
    return PanelTheme(
      cardAlpha: d(cardAlpha, other.cardAlpha),
      pillAlpha: d(pillAlpha, other.pillAlpha),
      chartFillAlpha: d(chartFillAlpha, other.chartFillAlpha),
      cardRadius: d(cardRadius, other.cardRadius),
      pillRadius: d(pillRadius, other.pillRadius),
      weightRegular: d(weightRegular, other.weightRegular),
      weightMedium: d(weightMedium, other.weightMedium),
      weightBold: d(weightBold, other.weightBold),
      squareInset: d(squareInset, other.squareInset),
      landscapeInsetH: d(landscapeInsetH, other.landscapeInsetH),
      landscapeInsetV: d(landscapeInsetV, other.landscapeInsetV),
      portraitInsetH: d(portraitInsetH, other.portraitInsetH),
      portraitInsetV: d(portraitInsetV, other.portraitInsetV),
      safeMargin: d(safeMargin, other.safeMargin),
      cardPadSmH: d(cardPadSmH, other.cardPadSmH),
      cardPadSmV: d(cardPadSmV, other.cardPadSmV),
      cardPadMdH: d(cardPadMdH, other.cardPadMdH),
      cardPadMdV: d(cardPadMdV, other.cardPadMdV),
      cardPadLgH: d(cardPadLgH, other.cardPadLgH),
      cardPadLgV: d(cardPadLgV, other.cardPadLgV),
      gap: d(gap, other.gap),
      fontXs: d(fontXs, other.fontXs),
      fontSm: d(fontSm, other.fontSm),
      fontMd: d(fontMd, other.fontMd),
      fontLg: d(fontLg, other.fontLg),
      fontXl: d(fontXl, other.fontXl),
    );
  }
}

/// [PanelTheme] resolved against a concrete `side`: spacing/fonts in pixels,
/// absolute tokens copied through. Built by [PanelTheme.resolve].
@immutable
class PanelMetrics {
  const PanelMetrics({
    required this.pageInset,
    required this.cardPaddingSm,
    required this.cardPaddingMd,
    required this.cardPaddingLg,
    required this.gap,
    required this.fontXs,
    required this.fontSm,
    required this.fontMd,
    required this.fontLg,
    required this.fontXl,
    required this.cardRadius,
    required this.pillRadius,
    required this.cardAlpha,
    required this.pillAlpha,
    required this.chartFillAlpha,
    required this.weightRegular,
    required this.weightMedium,
    required this.weightBold,
  });

  final EdgeInsets pageInset;
  final EdgeInsets cardPaddingSm;
  final EdgeInsets cardPaddingMd;
  final EdgeInsets cardPaddingLg;
  final double gap;
  final double fontXs;
  final double fontSm;
  final double fontMd;
  final double fontLg;
  final double fontXl;
  final double cardRadius;
  final double pillRadius;
  final double cardAlpha;
  final double pillAlpha;
  final double chartFillAlpha;
  final double weightRegular;
  final double weightMedium;
  final double weightBold;
}
