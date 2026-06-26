import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../l10n/app_localizations.dart';
import '../../widgets/panel_button.dart';
import '../../widgets/panel_text.dart';
import '../../widgets/progress_ring.dart';
import '../cubit/timer_cubit.dart';

/// `H:MM:SS` past an hour, otherwise `MM:SS`.
String _format(Duration d) {
  final h = d.inHours;
  final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return h > 0 ? '$h:$mm:$ss' : '$mm:$ss';
}

/// A countdown timer with a draining ring, start/pause + reset controls.
class TimerView extends StatelessWidget {
  const TimerView({super.key, required this.configured});

  /// The persisted duration; used to seed the shared cubit when it is at rest.
  final Duration configured;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<TimerCubit>();

    return BlocBuilder<TimerCubit, TimerState>(
      builder: (context, state) {
        if (!state.running &&
            !state.finished &&
            state.remaining == state.duration &&
            state.duration != configured) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final s = cubit.state;
            if (!s.running &&
                !s.finished &&
                s.remaining == s.duration &&
                s.duration != configured) {
              cubit.setDuration(configured);
            }
          });
        }

        final accent = state.finished ? colors.error : colors.primary;
        final atFull = !state.running && state.remaining == state.duration;

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
            final btn = inner * 0.36;

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
                        // Countdown readout fills the upper area; a "done" label
                        // tucks under it when the timer finishes.
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
                                  ),
                              ],
                            ),
                          ),
                        ),
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
                              onPressed: state.remaining <= Duration.zero
                                  ? null
                                  : (state.running ? cubit.pause : cubit.start),
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
      },
    );
  }
}
