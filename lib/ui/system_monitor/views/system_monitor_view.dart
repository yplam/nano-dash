import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../l10n/app_localizations.dart';
import '../../widgets/panel_text.dart';
import '../../widgets/panel_theme.dart';
import '../cubit/system_monitor_cubit.dart';

/// The system monitor's LCD page: a scrollable stack of semi-transparent cards.
/// CPU and memory each show their current percentage beside a history
/// sparkline; network shows down/up rates beside a shared-scale two-line chart.
class SystemMonitorView extends StatelessWidget {
  const SystemMonitorView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;

    return BlocBuilder<SystemMonitorCubit, SystemMonitorState>(
      builder: (context, state) {
        final snap = state.latest;
        if (snap == null) {
          return Center(
            child: Text(
              l10n.systemUnavailable,
              style: panelFont(16, 500, colors.onSurfaceVariant),
            ),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final side = math.min(constraints.maxWidth, constraints.maxHeight);
            final m = PanelTheme.metricsOf(
              context,
              side,
              shape: PanelShape.square,
            );
            return Padding(
              padding: m.pageInset,
              child: ListView(
                children: [
                  _MetricCard(
                    side: side,
                    label: l10n.systemCpu,
                    value: '${snap.cpuUsage.round()}%',
                    color: colors.primary,
                    series: [_Series(state.cpuHistory, colors.primary)],
                    maxValue: 100,
                  ),
                  SizedBox(height: m.gap - 4),
                  _MetricCard(
                    side: side,
                    label: l10n.systemMemory,
                    value: '${(snap.memFraction * 100).round()}%',
                    color: colors.tertiary,
                    series: [_Series(state.memHistory, colors.tertiary)],
                    maxValue: 100,
                  ),
                  SizedBox(height: m.gap - 4),
                  _NetworkCard(
                    side: side,
                    rxValue: _fmtRate(snap.netRxBps),
                    txValue: _fmtRate(snap.netTxBps),
                    rxColor: colors.primary,
                    txColor: colors.tertiary,
                    rxHistory: state.netRxHistory,
                    txHistory: state.netTxHistory,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

/// The shared card chrome: a rounded, semi-transparent surface holding some
/// caller-supplied left content and a sparkline that fills the remaining width.
class _Card extends StatelessWidget {
  const _Card({required this.side, required this.left, required this.chart});

  final double side;
  final Widget left;
  final Widget chart;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final m = PanelTheme.metricsOf(context, side);
    return Material(
      color: colors.surface.withValues(alpha: m.cardAlpha),
      borderRadius: BorderRadius.circular(m.cardRadius),
      child: Padding(
        padding: m.cardPadding,
        child: Row(
          children: [
            left,
            SizedBox(width: side * 0.06),
            Expanded(
              child: SizedBox(height: side * 0.14, child: chart),
            ),
          ],
        ),
      ),
    );
  }
}

/// A single-value card: icon, current value + label, and a history sparkline.
class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.side,
    required this.label,
    required this.value,
    required this.color,
    required this.series,
    required this.maxValue,
  });

  final double side;
  final String label;
  final String value;
  final Color color;
  final List<_Series> series;
  final double maxValue;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final m = PanelTheme.metricsOf(context, side);
    return _Card(
      side: side,
      left: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: panelFont(m.fontLg, m.weightBold, colors.onSurface),
              ),
              Text(
                label,
                style: panelFont(
                  m.fontSm,
                  m.weightRegular,
                  colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
      chart: _Sparkline(series: series, maxValue: maxValue),
    );
  }
}

/// The network card: two stacked rows (down/up icon + rate) on the left and a
/// single two-line, shared-scale chart on the right.
class _NetworkCard extends StatelessWidget {
  const _NetworkCard({
    required this.side,
    required this.rxValue,
    required this.txValue,
    required this.rxColor,
    required this.txColor,
    required this.rxHistory,
    required this.txHistory,
  });

  final double side;
  final String rxValue;
  final String txValue;
  final Color rxColor;
  final Color txColor;
  final List<double> rxHistory;
  final List<double> txHistory;

  @override
  Widget build(BuildContext context) {
    // Both lines share one vertical scale so their relative magnitude reads
    // true; guard against an all-zero window collapsing the divisor.
    final peak = [
      ...rxHistory,
      ...txHistory,
    ].fold<double>(1, (m, v) => math.max(m, v));
    return _Card(
      side: side,
      left: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _NetRow(
            side: side,
            icon: Icons.south,
            value: rxValue,
            color: rxColor,
          ),
          SizedBox(height: side * 0.01),
          _NetRow(
            side: side,
            icon: Icons.north,
            value: txValue,
            color: txColor,
          ),
        ],
      ),
      chart: _Sparkline(
        series: [_Series(rxHistory, rxColor), _Series(txHistory, txColor)],
        maxValue: peak,
      ),
    );
  }
}

/// One direction of network throughput: a directional glyph and its rate.
class _NetRow extends StatelessWidget {
  const _NetRow({
    required this.side,
    required this.icon,
    required this.value,
    required this.color,
  });

  final double side;
  final IconData icon;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final m = PanelTheme.metricsOf(context, side);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: side * 0.06, color: color),
        Text(
          value,
          style: panelFont(m.fontMd, m.weightMedium, colors.onSurface),
        ),
      ],
    );
  }
}

/// One line to draw in a sparkline: its readings (newest last) and colour.
class _Series {
  const _Series(this.values, this.color);

  final List<double> values;
  final Color color;
}

/// A minimal, axis-less line chart. Draws each [_Series] against a shared
/// [maxValue]; a single series also gets a soft fill beneath it.
class _Sparkline extends StatelessWidget {
  const _Sparkline({required this.series, required this.maxValue});

  final List<_Series> series;
  final double maxValue;

  @override
  Widget build(BuildContext context) {
    final panel =
        Theme.of(context).extension<PanelTheme>() ?? const PanelTheme();
    return CustomPaint(
      painter: _SparklinePainter(series, maxValue, panel.chartFillAlpha),
      size: Size.infinite,
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter(this.series, this.maxValue, this.fillAlpha);

  final List<_Series> series;
  final double maxValue;
  final double fillAlpha;

  @override
  void paint(Canvas canvas, Size size) {
    final fillUnder = series.length == 1;
    for (final s in series) {
      final values = s.values;
      if (values.length < 2) continue;
      final dx = size.width / (values.length - 1);
      final path = Path();
      var x = 0.0;
      for (var i = 0; i < values.length; i++) {
        final v = (values[i] / maxValue).clamp(0.0, 1.0);
        final y = size.height - v * size.height;
        i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
        x += dx;
      }

      if (fillUnder) {
        final fill = Path.from(path)
          ..lineTo(size.width, size.height)
          ..lineTo(0, size.height)
          ..close();
        canvas.drawPath(
          fill,
          Paint()..color = s.color.withValues(alpha: fillAlpha),
        );
      }
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..strokeJoin = StrokeJoin.round
          ..color = s.color,
      );
    }
  }

  @override
  bool shouldRepaint(_SparklinePainter old) =>
      old.series != series ||
      old.maxValue != maxValue ||
      old.fillAlpha != fillAlpha;
}

/// Format a bytes/second rate compactly (e.g. `1.2 MB/s`).
String _fmtRate(int bytesPerSec) {
  const units = ['B/s', 'KB/s', 'MB/s', 'GB/s'];
  double v = bytesPerSec.toDouble();
  var u = 0;
  while (v >= 1024 && u < units.length - 1) {
    v /= 1024;
    u++;
  }
  final digits = v >= 100 || u == 0 ? 0 : 1;
  return '${v.toStringAsFixed(digits)} ${units[u]}';
}
