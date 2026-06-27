import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/timer_cubit.dart';
import '../models/timer_config.dart';
import 'pomodoro_stats_view.dart';
import 'timer_detail_view.dart';
import 'timer_list_view.dart';

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

  /// Whether the statistics page is showing instead of the list/detail.
  bool _stats = false;

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

  void _open(String id, String name) {
    context.read<TimerCubit>().select(id, name);
    setState(() => _viewing = id);
  }

  void _back() => setState(() => _viewing = null);

  void _openStats() => setState(() => _stats = true);

  void _closeStats() => setState(() => _stats = false);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TimerCubit, TimerState>(
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
          );
        }
        return TimerDetailView(state: state, onBack: _back);
      },
    );
  }
}
