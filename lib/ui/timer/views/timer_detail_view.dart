import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../l10n/app_localizations.dart';
import '../../widgets/panel_button.dart';
import '../../widgets/panel_text.dart';
import '../../widgets/progress_ring.dart';
import '../cubit/timer_cubit.dart';
import '../models/timer_config.dart';

/// `H:MM:SS` past an hour, otherwise `MM:SS`.
String _format(Duration d) {
  final h = d.inHours;
  final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return h > 0 ? '$h:$mm:$ss' : '$mm:$ss';
}

/// The countdown detail for the armed timer: a draining ring with the timer's
/// name, the readout, and reset / start-pause controls. Tapping back returns to
/// the timer list.
class TimerDetailView extends StatelessWidget {
  const TimerDetailView({super.key, required this.state, required this.onBack});

  final TimerState state;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<TimerCubit>();
    final selected = state.selected;
    if (selected == null) return const SizedBox.shrink();

    final accent = state.finished
        ? colors.error
        : (state.onBreak ? colors.tertiary : colors.primary);
    final atFull = !state.running && state.remaining == state.duration;
    final startEnabled =
        state.running ||
        state.remaining > Duration.zero ||
        (!selected.pomodoro && selected.duration > Duration.zero);

    // The phase caption and progress dots shown for a Pomodoro task.
    final pomodoro = state.isPomodoro;
    final phaseLabel = switch (state.phase) {
      PomodoroPhase.focus => l10n.timerDefaultFocus,
      PomodoroPhase.shortBreak => l10n.timerDefaultShortBreak,
      PomodoroPhase.longBreak => l10n.timerDefaultLongBreak,
    };
    const every = TimerConfig.longBreakEvery;
    final filledDots = state.phase == PomodoroPhase.longBreak
        ? every
        : state.completedFocus % every;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : constraints.maxHeight;
        final maxH = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : constraints.maxWidth;
        final side = math.min(maxW, maxH);

        // Ring nearly fills the round panel; all content lives inside it.
        final ringSize = side * 0.92;
        // The square that fits inside the ring's inner circle.
        final inner = ringSize * 0.7;
        final btn = inner * 0.34;

        return Center(
          child: Container(
            width: ringSize,
            height: ringSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.surface.withValues(alpha: 0.5),
              border: Border.all(
                color: colors.onSurface.withValues(alpha: 0.08),
              ),
            ),
            child: ProgressRing(
              progress: state.progress,
              color: accent,
              trackColor: colors.onSurface.withValues(alpha: 0.12),
              strokeWidth: side * 0.03,
              child: SizedBox(
                width: inner,
                height: inner,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top: tapping the chevron or the name returns to the list.
                    InkResponse(
                      onTap: onBack,
                      radius: inner * 0.12,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.chevron_left,
                            size: inner * 0.16,
                            color: colors.onSurfaceVariant,
                          ),
                          Flexible(
                            child: Text(
                              selected.displayName(l10n),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: panelFont(
                                inner * 0.1,
                                600,
                                colors.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                _format(state.remaining),
                                style: panelFont(inner * 0.26, 600, accent),
                              ),
                            ),
                            if (state.finished)
                              Text(
                                l10n.timerDone,
                                style: panelFont(
                                  inner * 0.1,
                                  600,
                                  colors.error,
                                ),
                              )
                            else if (pomodoro)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    phaseLabel,
                                    style: panelFont(
                                      inner * 0.05,
                                      600,
                                      state.onBreak
                                          ? colors.tertiary
                                          : colors.onSurfaceVariant,
                                    ),
                                  ),
                                  SizedBox(width: inner * 0.05),
                                  _CycleDots(
                                    total: every,
                                    filled: filledDots,
                                    size: inner * 0.05,
                                    color: accent,
                                    trackColor: colors.onSurface.withValues(
                                      alpha: 0.18,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                    // Bottom: reset and start/pause.
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PanelButton(
                          icon: Icons.refresh,
                          diameter: btn,
                          color: colors.surfaceContainerHighest,
                          foreground: colors.onSurfaceVariant,
                          onPressed: atFull ? null : cubit.reset,
                        ),
                        SizedBox(width: inner * 0.1),
                        PanelButton(
                          icon: state.running
                              ? Icons.pause
                              : Icons.play_arrow_rounded,
                          diameter: btn,
                          color: colors.primary,
                          foreground: colors.onPrimary,
                          onPressed: startEnabled
                              ? (state.running ? cubit.pause : cubit.start)
                              : null,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// A row of small dots tracking progress towards the next long break: [filled]
/// of [total] solid, the rest outlined.
class _CycleDots extends StatelessWidget {
  const _CycleDots({
    required this.total,
    required this.filled,
    required this.size,
    required this.color,
    required this.trackColor,
  });

  final int total;
  final int filled;
  final double size;
  final Color color;
  final Color trackColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < total; i++)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: size * 0.4),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < filled ? color : trackColor,
              ),
            ),
          ),
      ],
    );
  }
}
