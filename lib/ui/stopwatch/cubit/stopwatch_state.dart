part of 'stopwatch_cubit.dart';

/// A recorded split: its 1-based [index], the [lapTime] since the previous
/// split, and the cumulative [total] elapsed at the moment of the split.
class Lap {
  const Lap({required this.index, required this.lapTime, required this.total});

  final int index;
  final Duration lapTime;
  final Duration total;
}

/// View state for the stopwatch module.
class StopwatchState {
  const StopwatchState({
    this.elapsed = Duration.zero,
    this.running = false,
    this.laps = const [],
  });

  /// Total time counted so far.
  final Duration elapsed;

  /// Whether the clock is currently advancing.
  final bool running;

  /// Recorded splits, in the order they were taken (oldest first).
  final List<Lap> laps;
}
