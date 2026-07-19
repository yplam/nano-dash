import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../widgets/panel_empty.dart';
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
/// countdown detail; long-pressing a row reveals a trailing delete button on
/// just that row (tapping elsewhere dismisses it). The foot pill opens the
/// statistics page.
class TimerListView extends StatefulWidget {
  const TimerListView({
    super.key,
    required this.timers,
    required this.state,
    required this.onOpen,
    required this.onStats,
    required this.onDelete,
  });

  final List<TimerConfig> timers;
  final TimerState state;
  final void Function(String id, String name) onOpen;
  final VoidCallback onStats;

  /// Remove the timer with the given id (from the long-press delete reveal).
  final ValueChanged<String> onDelete;

  @override
  State<TimerListView> createState() => _TimerListViewState();
}

class _TimerListViewState extends State<TimerListView> {
  /// The timer whose delete button is currently revealed, or null when none is.
  String? _revealedId;

  void _reveal(String id) => setState(() => _revealedId = id);

  void _dismissReveal() {
    if (_revealedId != null) setState(() => _revealedId = null);
  }

  void _delete(String id) {
    _dismissReveal();
    widget.onDelete(id);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final timers = widget.timers;
    final state = widget.state;

    return LayoutBuilder(
      builder: (context, constraints) {
        final side = math.min(constraints.maxWidth, constraints.maxHeight);
        final m = PanelTheme.metricsOf(
          context,
          side,
          shape: PanelShape.landscape,
        );
        return Padding(
          padding: m.pageInset.copyWith(bottom: m.pageInset.bottom - 42),
          child: Column(
            children: [
              Expanded(
                child: timers.isEmpty
                    ? PanelEmpty(
                        side: side,
                        icon: Icons.timer_outlined,
                        label: l10n.timerEmpty,
                      )
                    : LayoutBuilder(
                        builder: (context, c) {
                          Widget rowFor(TimerConfig t) {
                            final armed =
                                state.selectedId == t.id &&
                                (state.running ||
                                    state.finished ||
                                    state.remaining != t.duration);
                            final revealed = _revealedId == t.id;
                            return _TimerListRow(
                              name: t.displayName(l10n),
                              colors: colors,
                              metrics: m,
                              pomodoro: t.pomodoro,
                              running: armed && state.running,
                              finished: armed && state.finished,
                              readout: armed ? state.remaining : t.duration,
                              emphasised: armed,
                              showDelete: revealed,
                              // With a delete button revealed, a plain tap on the
                              // row just dismisses it rather than opening.
                              onTap: revealed
                                  ? _dismissReveal
                                  : () => widget.onOpen(
                                      t.id,
                                      t.displayName(l10n),
                                    ),
                              onLongPress: () => _reveal(t.id),
                              onDelete: () => _delete(t.id),
                            );
                          }

                          // A tap on the empty space around the rows also
                          // dismisses a revealed delete button.
                          return GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onTap: _dismissReveal,
                            child: SingleChildScrollView(
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
                            ),
                          );
                        },
                      ),
              ),
              if (state.hasStats) ...[
                SizedBox(height: 8),
                _StatsButton(colors: colors, metrics: m, onTap: widget.onStats),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// The round icon button at the foot of the timer list that opens the
/// statistics page.
class _StatsButton extends StatelessWidget {
  const _StatsButton({
    required this.colors,
    required this.metrics,
    required this.onTap,
  });

  final ColorScheme colors;
  final PanelMetrics metrics;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final diameter = metrics.fontLg * 2.4;
    return Center(
      child: Material(
        shape: const CircleBorder(),
        color: colors.surfaceContainerHighest.withValues(
          alpha: metrics.pillAlpha,
        ),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: diameter,
            height: diameter,
            child: Icon(
              Icons.bar_chart,
              size: metrics.fontLg,
              color: colors.onSurfaceVariant,
            ),
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
    required this.showDelete,
    required this.onTap,
    required this.onLongPress,
    required this.onDelete,
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

  /// Whether the trailing delete button is revealed on this row.
  final bool showDelete;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onDelete;

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

    return Material(
      color: background,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: m.cardPaddingLg,
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
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: panelFont(m.fontLg, m.weightMedium, foreground),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _format(readout),
                style: panelFont(m.fontMd, m.weightMedium, foreground),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOut,
                child: showDelete
                    ? Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: _DeleteButton(
                          colors: colors,
                          size: m.fontLg,
                          onTap: onDelete,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The circular delete affordance revealed at the trailing edge of a row on
/// long-press.
class _DeleteButton extends StatelessWidget {
  const _DeleteButton({
    required this.colors,
    required this.size,
    required this.onTap,
  });

  final ColorScheme colors;
  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final diameter = size * 1.7;
    return Material(
      shape: const CircleBorder(),
      color: colors.errorContainer,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: diameter,
          height: diameter,
          child: Icon(
            Icons.delete_outline,
            size: size,
            color: colors.onErrorContainer,
          ),
        ),
      ),
    );
  }
}
