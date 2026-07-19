import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/timer_cubit.dart';
import 'pomodoro_stats_view.dart';
import 'timer_detail_view.dart';
import 'timer_list_view.dart';

/// The timer module's LCD page. Lands on a list of the configured timers; tap
/// one to open its draining-ring countdown detail.
class TimerView extends StatefulWidget {
  const TimerView({super.key});

  @override
  State<TimerView> createState() => _TimerViewState();
}

class _TimerViewState extends State<TimerView> {
  /// The timer whose detail is open, or null while showing the list.
  String? _viewing;

  /// Whether the statistics page is showing instead of the list/detail.
  bool _stats = false;

  void _open(String id, String name) {
    context.read<TimerCubit>().select(id, name);
    setState(() => _viewing = id);
  }

  void _delete(String id) {
    final cubit = context.read<TimerCubit>();
    final next = [
      for (final t in cubit.state.timers)
        if (t.id != id) t,
    ];
    cubit.saveTimers(next);
  }

  void _back() => setState(() => _viewing = null);

  void _openStats() => setState(() => _stats = true);

  void _closeStats() => setState(() => _stats = false);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TimerCubit, TimerState>(
      // The cubit ticks at 100ms while a timer runs.
      buildWhen: (prev, curr) {
        if (_stats) return prev.logs != curr.logs;
        if (_viewing != null) return true;
        return prev.timers != curr.timers ||
            prev.selectedId != curr.selectedId ||
            prev.running != curr.running ||
            prev.finished != curr.finished ||
            prev.logs != curr.logs ||
            prev.remaining.inSeconds != curr.remaining.inSeconds;
      },
      builder: (context, state) {
        if (_stats) {
          return PomodoroStatsView(
            logs: state.logs,
            onBack: _closeStats,
            onClear: context.read<TimerCubit>().clearStats,
          );
        }
        // The viewed timer may have been deleted from settings; fall back to
        // the list rather than showing a detail for a missing timer.
        final viewing =
            _viewing != null && state.timers.any((t) => t.id == _viewing)
            ? _viewing
            : null;
        if (viewing == null) {
          return TimerListView(
            timers: state.timers,
            state: state,
            onOpen: _open,
            onStats: _openStats,
            onDelete: _delete,
          );
        }
        return TimerDetailView(state: state, onBack: _back);
      },
    );
  }
}
