import 'dart:math' as math;

import 'package:flutter/foundation.dart';
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

/// The timer module's LCD page. Lands on a list of the configured timers; tap
/// one to open its draining-ring countdown detail.
class TimerView extends StatefulWidget {
  const TimerView({super.key, required this.timers});

  /// The persisted timers, mirrored into the shared cubit.
  final List<TimerConfig> timers;

  @override
  State<TimerView> createState() => _TimerViewState();
}

class _TimerViewState extends State<TimerView> {
  /// The timer whose detail is open, or null while showing the list.
  String? _viewing;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    context.read<TimerCubit>().syncTimers(widget.timers);
  }

  @override
  void didUpdateWidget(TimerView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.timers, widget.timers)) {
      context.read<TimerCubit>().syncTimers(widget.timers);
    }
  }

  void _open(String id) {
    context.read<TimerCubit>().select(id);
    setState(() => _viewing = id);
  }

  void _back() => setState(() => _viewing = null);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TimerCubit, TimerState>(
      builder: (context, state) {
        // The viewed timer may have been deleted from settings; fall back to
        // the list rather than showing a detail for a missing timer.
        final viewing =
            _viewing != null && state.timers.any((t) => t.id == _viewing)
            ? _viewing
            : null;
        if (viewing == null) {
          return _TimerList(timers: state.timers, state: state, onOpen: _open);
        }
        return _TimerDetail(state: state, onBack: _back);
      },
    );
  }
}

/// The landing list: one tappable row per configured timer, with a live readout
/// on whichever timer is currently armed.
class _TimerList extends StatelessWidget {
  const _TimerList({
    required this.timers,
    required this.state,
    required this.onOpen,
  });

  final List<TimerConfig> timers;
  final TimerState state;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    if (timers.isEmpty) {
      return Center(
        child: Text(
          l10n.timerEmpty,
          style: panelFont(16, 500, colors.onSurfaceVariant),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final side = math.min(constraints.maxWidth, constraints.maxHeight);
        final inset = side * 0.16;
        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: inset,
            vertical: side * 0.2,
          ),
          child: ListView.separated(
            itemCount: timers.length,
            separatorBuilder: (_, _) => SizedBox(height: side * 0.06),
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
                running: armed && state.running,
                finished: armed && state.finished,
                readout: armed ? state.remaining : t.duration,
                emphasised: armed,
                onTap: () => onOpen(t.id),
              );
            },
          ),
        );
      },
    );
  }
}

class _TimerListRow extends StatelessWidget {
  const _TimerListRow({
    required this.name,
    required this.colors,
    required this.running,
    required this.finished,
    required this.readout,
    required this.emphasised,
    required this.onTap,
  });

  /// The resolved, localized label for the timer (its name or default label).
  final String name;
  final ColorScheme colors;
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
                                : Icons.timer_outlined)),
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

/// The countdown detail for the armed timer: a draining ring with the timer's
/// name, the readout, and reset / start-pause controls.
class _TimerDetail extends StatelessWidget {
  const _TimerDetail({required this.state, required this.onBack});

  final TimerState state;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<TimerCubit>();
    final selected = state.selected;
    if (selected == null) return const SizedBox.shrink();

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
  }
}
