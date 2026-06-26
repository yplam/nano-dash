import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../widgets/panel_button.dart';
import '../../widgets/panel_text.dart';
import '../../widgets/progress_ring.dart';
import '../cubit/stopwatch_cubit.dart';

/// `MM:SS.cs` — minutes can grow past 60; they keep a fixed two-digit width
/// by showing only the low two digits (e.g. 199 min → `99`).
String _format(Duration d) {
  final mm = d.inMinutes.remainder(100).toString().padLeft(2, '0');
  final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  final cs = (d.inMilliseconds.remainder(1000) ~/ 10).toString().padLeft(
    2,
    '0',
  );
  return '$mm:$ss.$cs';
}

/// A stopwatch with a sweeping ring (one turn per minute), a centisecond
/// readout, and start/pause + reset controls.
class StopwatchView extends StatelessWidget {
  const StopwatchView({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final cubit = context.read<StopwatchCubit>();

    return BlocBuilder<StopwatchCubit, StopwatchState>(
      builder: (context, state) {
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
            // Height of one split row, and the list capped at three of them.
            final rowHeight = inner * 0.11;

            // One full sweep per minute.
            final progress =
                (state.elapsed.inMilliseconds.remainder(60000)) / 60000.0;
            final idle = !state.running && state.elapsed == Duration.zero;

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
                  progress: progress,
                  color: colors.primary,
                  trackColor: colors.onSurface.withValues(alpha: 0.12),
                  strokeWidth: side * 0.03,
                  child: SizedBox(
                    width: inner,
                    height: inner,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // With no splits the readout is large and centered; once
                        // splits exist it shrinks up top to make room for the
                        // list below.
                        if (state.laps.isEmpty)
                          Expanded(
                            child: Center(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  _format(state.elapsed),
                                  style: panelFont(
                                    inner * 0.26,
                                    600,
                                    colors.primary,
                                  ),
                                ),
                              ),
                            ),
                          )
                        else ...[
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              _format(state.elapsed),
                              style: panelFont(
                                inner * 0.16,
                                600,
                                colors.primary,
                              ),
                            ),
                          ),
                          // Splits: newest first, last 3 visible, older scroll up.
                          Expanded(
                            child: Center(
                              child: SizedBox(
                                height: rowHeight * 3,
                                child: _LapList(
                                  laps: state.laps,
                                  width: inner,
                                  rowHeight: rowHeight,
                                ),
                              ),
                            ),
                          ),
                        ],
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Left: split while running, otherwise reset.
                            PanelButton(
                              icon: state.running
                                  ? Icons.flag_outlined
                                  : Icons.refresh,
                              diameter: btn,
                              color: colors.surfaceContainerHighest,
                              foreground: colors.onSurfaceVariant,
                              onPressed: state.running
                                  ? cubit.split
                                  : (idle ? null : cubit.reset),
                            ),
                            SizedBox(width: inner * 0.1),
                            // Right: start / stop / continue.
                            PanelButton(
                              icon: state.running
                                  ? Icons.pause
                                  : Icons.play_arrow_rounded,
                              diameter: btn,
                              color: colors.primary,
                              foreground: colors.onPrimary,
                              onPressed: state.running
                                  ? cubit.pause
                                  : cubit.start,
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

/// The scrollable split list. Newest split sits on top (`03`, `02`, …); each row
/// shows the index, the lap time since the previous split, and the cumulative
/// total at that split.
class _LapList extends StatelessWidget {
  const _LapList({
    required this.laps,
    required this.width,
    required this.rowHeight,
  });

  final List<Lap> laps;
  final double width;
  final double rowHeight;

  @override
  Widget build(BuildContext context) {
    if (laps.isEmpty) return const SizedBox.shrink();

    final colors = Theme.of(context).colorScheme;
    final reversed = laps.reversed.toList();
    final font = panelFont(width * 0.085, 500, colors.onSurfaceVariant);

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: reversed.length,
      itemExtent: rowHeight,
      itemBuilder: (context, i) {
        final lap = reversed[i];
        return Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(lap.index.toString().padLeft(2, '0'), style: font),
              Text('+${_format(lap.lapTime)}', style: font),
              Text(
                _format(lap.total),
                style: font.copyWith(color: colors.primary),
              ),
            ],
          ),
        );
      },
    );
  }
}
