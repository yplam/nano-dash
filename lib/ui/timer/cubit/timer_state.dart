part of 'timer_cubit.dart';

/// View state for the countdown timer module.
class TimerState {
  const TimerState({
    this.duration = Duration.zero,
    this.remaining = Duration.zero,
    this.running = false,
    this.finished = false,
  });

  /// The total configured countdown length.
  final Duration duration;

  /// Time left in the current countdown.
  final Duration remaining;

  /// Whether the countdown is currently advancing.
  final bool running;

  /// Whether the countdown reached zero and is awaiting a reset.
  final bool finished;

  /// Fraction of the countdown already elapsed, 0..1. Drives the ring sweep.
  double get progress {
    final total = duration.inMilliseconds;
    if (total <= 0) return 0;
    final done = total - remaining.inMilliseconds;
    return (done / total).clamp(0.0, 1.0);
  }

  TimerState copyWith({
    Duration? duration,
    Duration? remaining,
    bool? running,
    bool? finished,
  }) {
    return TimerState(
      duration: duration ?? this.duration,
      remaining: remaining ?? this.remaining,
      running: running ?? this.running,
      finished: finished ?? this.finished,
    );
  }
}
