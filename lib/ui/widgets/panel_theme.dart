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
///  * Resolution-independent tokens — alphas, font weights, corner radii — are
///    stored as literals.
///  * Spacing and font sizes are stored as *ratios of `side`* (the min of the
///    panel's width/height, taken from a `LayoutBuilder`), because the same
///    subtree is mirrored to LCD panels of differing pixel size and everything
///    must scale with the panel, not with logical pixels.
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
    // Spacing as a fraction of `side`.
    this.cardPadHRatio = 0.04,
    this.cardPadVRatio = 0.03,
    this.gapRatio = 0.03,
    // Font sizes as a fraction of `side`.
    this.fontLgRatio = 0.07,
    this.fontMdRatio = 0.05,
    this.fontSmRatio = 0.03,
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
  final double cardPadHRatio;
  final double cardPadVRatio;
  final double gapRatio;
  final double fontLgRatio;
  final double fontMdRatio;
  final double fontSmRatio;

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

  /// Flatten the ratio tokens against [side] (= `min(width, height)`), picking
  /// the page inset for [shape] and copying the absolute tokens through
  /// unchanged.
  PanelMetrics resolve(double side, PanelShape shape) => PanelMetrics(
    pageInset: pageInsetFor(shape, side),
    cardPadding: EdgeInsets.symmetric(
      horizontal: side * cardPadHRatio,
      vertical: side * cardPadVRatio,
    ),
    gap: side * gapRatio,
    fontLg: side * fontLgRatio,
    fontMd: side * fontMdRatio,
    fontSm: side * fontSmRatio,
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
    double? cardPadHRatio,
    double? cardPadVRatio,
    double? gapRatio,
    double? fontLgRatio,
    double? fontMdRatio,
    double? fontSmRatio,
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
    cardPadHRatio: cardPadHRatio ?? this.cardPadHRatio,
    cardPadVRatio: cardPadVRatio ?? this.cardPadVRatio,
    gapRatio: gapRatio ?? this.gapRatio,
    fontLgRatio: fontLgRatio ?? this.fontLgRatio,
    fontMdRatio: fontMdRatio ?? this.fontMdRatio,
    fontSmRatio: fontSmRatio ?? this.fontSmRatio,
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
      cardPadHRatio: d(cardPadHRatio, other.cardPadHRatio),
      cardPadVRatio: d(cardPadVRatio, other.cardPadVRatio),
      gapRatio: d(gapRatio, other.gapRatio),
      fontLgRatio: d(fontLgRatio, other.fontLgRatio),
      fontMdRatio: d(fontMdRatio, other.fontMdRatio),
      fontSmRatio: d(fontSmRatio, other.fontSmRatio),
    );
  }
}

/// [PanelTheme] resolved against a concrete `side`: spacing/fonts in pixels,
/// absolute tokens copied through. Built by [PanelTheme.resolve].
@immutable
class PanelMetrics {
  const PanelMetrics({
    required this.pageInset,
    required this.cardPadding,
    required this.gap,
    required this.fontLg,
    required this.fontMd,
    required this.fontSm,
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
  final EdgeInsets cardPadding;
  final double gap;
  final double fontLg;
  final double fontMd;
  final double fontSm;
  final double cardRadius;
  final double pillRadius;
  final double cardAlpha;
  final double pillAlpha;
  final double chartFillAlpha;
  final double weightRegular;
  final double weightMedium;
  final double weightBold;
}
