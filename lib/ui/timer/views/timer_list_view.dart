import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../widgets/panel_text.dart';
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
        final inset = side * 0.16;
        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: inset,
            vertical: side * 0.14,
          ),
          child: Column(
            children: [
              Expanded(
                child: timers.isEmpty
                    ? Center(
                        child: Text(
                          l10n.timerEmpty,
                          style: panelFont(16, 500, colors.onSurfaceVariant),
                        ),
                      )
                    : Center(
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: timers.length,
                          separatorBuilder: (_, _) =>
                              SizedBox(height: side * 0.06),
                          itemBuilder: (context, i) {
                            final t = timers[i];
                            final armed =
                                state.selectedId == t.id &&
                                (state.running ||
                                    state.finished ||
                                    state.remaining != t.duration);
                            return _TimerListRow(
                              name: t.displayName(l10n),
                              colors: colors,
                              pomodoro: t.pomodoro,
                              running: armed && state.running,
                              finished: armed && state.finished,
                              readout: armed ? state.remaining : t.duration,
                              emphasised: armed,
                              onTap: () => onOpen(t.id, t.displayName(l10n)),
                            );
                          },
                        ),
                      ),
              ),
              if (state.hasStats) ...[
                SizedBox(height: side * 0.03),
                _StatsButton(
                  colors: colors,
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
    required this.label,
    required this.onTap,
  });

  final ColorScheme colors;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: colors.surfaceContainerHighest.withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bar_chart, size: 18, color: colors.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(label, style: panelFont(14, 600, colors.onSurfaceVariant)),
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

  /// Whether this timer is a Pomodoro task (shown with a task glyph when idle).
  final bool pomodoro;
  final bool running;
  final bool finished;
  final Duration readout;
  final bool emphasised;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final background = emphasised
        ? (finished ? colors.errorContainer : colors.primaryContainer)
        : colors.surface.withValues(alpha: 0.5);
    final foreground = emphasised
        ? (finished ? colors.onErrorContainer : colors.onPrimaryContainer)
        : colors.onSurface;
    final subdued = emphasised ? foreground : colors.onSurfaceVariant;
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
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
                size: 22,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: panelFont(18, 600, foreground),
                ),
              ),
              const SizedBox(width: 6),
              Text(_format(readout), style: panelFont(18, 600, foreground)),
            ],
          ),
        ),
      ),
    );
  }
}
