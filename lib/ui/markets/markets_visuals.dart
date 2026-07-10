import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/models/markets.dart';

/// The colour + arrow for a rising/falling quote.
class MarketsTrendVisual {
  const MarketsTrendVisual(this.color, this.icon);

  final Color color;
  final IconData icon;
}

// Up/down tones, tuned lighter on dark backgrounds so they read on the panel's
// translucent card surface.
const Color _upLight = Color(0xFF0F9D58);
const Color _upDark = Color(0xFF4CD964);
const Color _downLight = Color(0xFFD32F2F);
const Color _downDark = Color(0xFFFF6B6B);

/// The trend visual for [isUp], adapted to [brightness].
MarketsTrendVisual marketsTrend(bool isUp, Brightness brightness) {
  final dark = brightness == Brightness.dark;
  if (isUp) {
    return MarketsTrendVisual(dark ? _upDark : _upLight, Icons.arrow_drop_up);
  }
  return MarketsTrendVisual(
    dark ? _downDark : _downLight,
    Icons.arrow_drop_down,
  );
}

/// Format a quote's price with a sensible number of decimals for its kind.
String formatQuotePrice(Quote q) => formatPrice(q.kind, q.price);

/// Format [value] as a [kind] price.
String formatPrice(QuoteKind kind, double value) {
  final decimals = switch (kind) {
    QuoteKind.forex => 4,
    QuoteKind.crypto => value >= 100 ? 2 : (value >= 1 ? 4 : 6),
    _ => 2,
  };
  return _decimal(decimals).format(value);
}

/// Format the signed percentage change, e.g. `+1.24%` / `-0.30%`.
String formatChangePercent(double pct) {
  final sign = pct >= 0 ? '+' : '-';
  return '$sign${pct.abs().toStringAsFixed(2)}%';
}

/// A grouped decimal formatter with [decimals] fraction digits. Built from an
/// explicit pattern so it behaves the same across `intl` versions.
NumberFormat _decimal(int decimals) {
  final fraction = decimals > 0 ? '.${'0' * decimals}' : '';
  return NumberFormat('#,##0$fraction');
}
