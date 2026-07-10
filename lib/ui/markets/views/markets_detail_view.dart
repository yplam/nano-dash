import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/models/markets.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/panel_empty.dart';
import '../../widgets/panel_text.dart';
import '../../widgets/panel_theme.dart';
import '../cubit/markets_cubit.dart';
import '../markets_visuals.dart';

class MarketsDetailView extends StatelessWidget {
  const MarketsDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = math.min(
          constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : constraints.maxHeight,
          constraints.maxHeight.isFinite
              ? constraints.maxHeight
              : constraints.maxWidth,
        );
        return BlocBuilder<MarketsCubit, MarketsState>(
          builder: (context, state) => _body(context, side, state),
        );
      },
    );
  }

  Widget _body(BuildContext context, double side, MarketsState state) {
    final l10n = AppLocalizations.of(context);
    final m = PanelTheme.metricsOf(context, side, shape: PanelShape.square);

    final quotes = state.quotes;
    if (quotes == null || quotes.isEmpty) {
      // No symbols, still loading the first result, or the last fetch failed.
      if (state.loading && quotes == null) {
        return const Center(child: CircularProgressIndicator());
      }
      final unconfigured = state.config.symbols.isEmpty;
      return PanelEmpty(
        side: side,
        icon: unconfigured ? Icons.show_chart : Icons.error_outline,
        label: unconfigured ? l10n.marketsEmpty : l10n.marketsError,
      );
    }

    return SingleChildScrollView(
      padding: m.pageInset,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < quotes.length; i++) ...[
            if (i > 0) SizedBox(height: m.gap),
            _QuoteCard(side: side, quote: quotes[i]),
          ],
        ],
      ),
    );
  }
}

/// Shared translucent card chrome, matching the other panel modules.
class _PanelCard extends StatelessWidget {
  const _PanelCard({required this.side, required this.child});

  final double side;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final m = PanelTheme.metricsOf(context, side);
    return Material(
      color: colors.surface.withValues(alpha: m.cardAlpha),
      borderRadius: BorderRadius.circular(m.cardRadius),
      child: Padding(padding: m.cardPaddingMd, child: child),
    );
  }
}

/// One watchlist row: name + price on top, a signed change pill, and (when a
/// session range is available) a low–price–high bar underneath.
class _QuoteCard extends StatelessWidget {
  const _QuoteCard({required this.side, required this.quote});

  final double side;
  final Quote quote;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final m = PanelTheme.metricsOf(context, side);
    final trend = marketsTrend(quote.isUp, colors.brightness);

    return _PanelCard(
      side: side,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Name (ellipsised, taking the slack) and the headline price.
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(
                  quote.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: panelFont(m.fontMd, m.weightMedium, colors.onSurface),
                ),
              ),
              SizedBox(width: side * 0.02),
              Text(
                formatQuotePrice(quote),
                style: panelFont(m.fontLg, m.weightBold, colors.onSurface),
              ),
            ],
          ),
          SizedBox(height: side * 0.01),
          // Optional currency on the left, the signed change pill on the right.
          // The currency (a short code) is the inflexible child so the pill —
          // the child that can actually run out of room — is handed all the
          // remaining width instead of an even split of it.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            spacing: side * 0.02,
            children: [
              if (quote.currency != null)
                Text(
                  quote.currency!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: panelFont(
                    m.fontXs,
                    m.weightRegular,
                    colors.onSurfaceVariant,
                  ),
                )
              else
                const SizedBox.shrink(),
              Flexible(
                child: _ChangePill(side: side, quote: quote, trend: trend),
              ),
            ],
          ),
          if (quote.hasRange) ...[
            SizedBox(height: m.gap),
            _RangeRow(side: side, quote: quote, color: trend.color),
          ],
        ],
      ),
    );
  }
}

/// A pill showing the signed percentage change with a direction arrow, coloured by trend.
class _ChangePill extends StatelessWidget {
  const _ChangePill({
    required this.side,
    required this.quote,
    required this.trend,
  });

  final double side;
  final Quote quote;
  final MarketsTrendVisual trend;

  @override
  Widget build(BuildContext context) {
    final m = PanelTheme.metricsOf(context, side);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: side * 0.02,
        vertical: side * 0.008,
      ),
      decoration: BoxDecoration(
        color: trend.color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(m.pillRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(trend.icon, size: m.fontMd, color: trend.color),
          Flexible(
            child: Text(
              formatChangePercent(quote.changePercent),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: panelFont(m.fontSm, m.weightMedium, trend.color),
            ),
          ),
        ],
      ),
    );
  }
}

/// The day's low–high track with a marker at the current price, flanked by the
/// low and high labels.
class _RangeRow extends StatelessWidget {
  const _RangeRow({
    required this.side,
    required this.quote,
    required this.color,
  });

  final double side;
  final Quote quote;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final m = PanelTheme.metricsOf(context, side);
    final lo = quote.dayLow!;
    final hi = quote.dayHigh!;
    final frac = ((quote.price - lo) / (hi - lo)).clamp(0.0, 1.0);
    final labelStyle = panelFont(
      m.fontXs,
      m.weightRegular,
      colors.onSurfaceVariant,
    );

    return Row(
      children: [
        Text(formatPrice(quote.kind, lo), style: labelStyle),
        SizedBox(width: side * 0.02),
        Expanded(
          child: _RangeBar(
            fraction: frac,
            color: color,
            track: colors.onSurface.withValues(alpha: 0.12),
            height: side * 0.014,
          ),
        ),
        SizedBox(width: side * 0.02),
        Text(formatPrice(quote.kind, hi), style: labelStyle),
      ],
    );
  }
}

/// A horizontal track with a marker at [fraction] (0 = low end, 1 = high end).
class _RangeBar extends StatelessWidget {
  const _RangeBar({
    required this.fraction,
    required this.color,
    required this.track,
    required this.height,
  });

  final double fraction;
  final Color color;
  final Color track;
  final double height;

  @override
  Widget build(BuildContext context) {
    final f = fraction.clamp(0.0, 1.0);
    final markerWidth = height * 1.2;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        // Keep the marker fully inside the track at both extremes.
        final left = (f * width - markerWidth / 2)
            .clamp(0.0, math.max(0.0, width - markerWidth))
            .toDouble();
        return SizedBox(
          height: height,
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: track,
                    borderRadius: BorderRadius.circular(height),
                  ),
                ),
              ),
              Positioned(
                left: left,
                top: 0,
                bottom: 0,
                width: markerWidth,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(height),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
