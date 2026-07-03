import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../widgets/panel_text.dart';
import '../../widgets/panel_theme.dart';
import '../cubit/timer_cubit.dart';
import '../models/timer_config.dart';

/// `H:MM:SS` past an hour, otherwise `MM:SS`.
String _format(Duration d) {
  final h = d.inHours;
  final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return h > 0 ? '$h:$mm:$ss' : '$mm:$ss';
}

/// The timer module's landing list: one tappable row per configured timer, with
/// a live readout on whichever timer is currently armed. Tapping a row opens its
/// countdown detail; the foot pill opens the statistics page.
class TimerListView extends StatelessWidget {
  const TimerListView({
    super.key,
    required this.timers,
    required this.state,
    required this.onOpen,
    required this.onStats,
  });

  final List<TimerConfig> timers;
  final TimerState state;
  final void Function(String id, String name) onOpen;
  final VoidCallback onStats;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final side = math.min(constraints.maxWidth, constraints.maxHeight);
        final m = PanelTheme.metricsOf(context, side, shape: PanelShape.square);
        return Padding(
          padding: m.pageInset,
          child: Column(
            children: [
              Expanded(
                child: timers.isEmpty
                    ? Center(
                        child: Text(
                          l10n.timerEmpty,
                          style: panelFont(
                            m.fontMd,
                            m.weightRegular,
                            colors.onSurfaceVariant,
                          ),
                        ),
                      )
                    : LayoutBuilder(
                        builder: (context, c) {
                          Widget rowFor(TimerConfig t) {
                            final armed =
                                state.selectedId == t.id &&
                                (state.running ||
                                    state.finished ||
                                    state.remaining != t.duration);
                            return _TimerListRow(
                              name: t.displayName(l10n),
                              colors: colors,
                              metrics: m,
                              pomodoro: t.pomodoro,
                              running: armed && state.running,
                              finished: armed && state.finished,
                              readout: armed ? state.remaining : t.duration,
                              emphasised: armed,
                              onTap: () => onOpen(t.id, t.displayName(l10n)),
                            );
                          }

                          return SingleChildScrollView(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: c.maxHeight,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  for (var i = 0; i < timers.length; i++) ...[
                                    if (i > 0) SizedBox(height: m.gap),
                                    rowFor(timers[i]),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              if (state.hasStats) ...[
                SizedBox(height: side * 0.03),
                _StatsButton(
                  colors: colors,
                  metrics: m,
                  label: l10n.timerStats,
                  onTap: onStats,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// The pill at the foot of the timer list that opens the statistics page.
class _StatsButton extends StatelessWidget {
  const _StatsButton({
    required this.colors,
    required this.metrics,
    required this.label,
    required this.onTap,
  });

  final ColorScheme colors;
  final PanelMetrics metrics;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(metrics.pillRadius);
    return Material(
      color: colors.surfaceContainerHighest.withValues(
        alpha: metrics.pillAlpha,
      ),
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bar_chart, size: 18, color: colors.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                label,
                style: panelFont(
                  metrics.fontSm,
                  metrics.weightMedium,
                  colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimerListRow extends StatelessWidget {
  const _TimerListRow({
    required this.name,
    required this.colors,
    required this.metrics,
    required this.pomodoro,
    required this.running,
    required this.finished,
    required this.readout,
    required this.emphasised,
    required this.onTap,
  });

  /// The resolved, localized label for the timer (its name or default label).
  final String name;
  final ColorScheme colors;
  final PanelMetrics metrics;

  /// Whether this timer is a Pomodoro task (shown with a task glyph when idle).
  final bool pomodoro;
  final bool running;
  final bool finished;
  final Duration readout;
  final bool emphasised;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final m = metrics;
    final background = emphasised
        ? (finished ? colors.errorContainer : colors.primaryContainer)
        : colors.surface.withValues(alpha: m.cardAlpha);
    final foreground = emphasised
        ? (finished ? colors.onErrorContainer : colors.onPrimaryContainer)
        : colors.onSurface;
    final subdued = emphasised ? foreground : colors.onSurfaceVariant;
    final radius = BorderRadius.circular(m.cardRadius);
    final cardPadding = EdgeInsets.only(
      left: m.cardPadding.left,
      right: m.cardPadding.right,
      top: m.cardPadding.top + 5,
      bottom: m.cardPadding.bottom + 5,
    );
    return Material(
      color: background,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Padding(
          padding: cardPadding,
          child: Row(
            children: [
              Icon(
                running
                    ? Icons.play_arrow_rounded
                    : (finished
                          ? Icons.notifications_active
                          : (emphasised
                                ? Icons.pause_rounded
                                : (pomodoro
                                      ? Icons.local_cafe_outlined
                                      : Icons.timer_outlined))),
                color: subdued,
                size: m.fontMd * 1.2,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: panelFont(m.fontMd, m.weightMedium, foreground),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                _format(readout),
                style: panelFont(m.fontMd, m.weightMedium, foreground),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
