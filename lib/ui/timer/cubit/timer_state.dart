part of 'timer_cubit.dart';

/// View state for the multi-timer module. The countdown applies to the single
/// [selectedId] timer — only one timer runs at a time.
class TimerState {
  const TimerState({
    this.timers = const [],
    this.selectedId,
    this.remaining = Duration.zero,
    this.running = false,
    this.finished = false,
  });

  /// All configured timers, in display order (mirrors the persisted settings).
  final List<TimerConfig> timers;

  /// The timer the countdown currently applies to, or null when none is armed.
  final String? selectedId;

  /// Time left in the selected timer's countdown.
  final Duration remaining;

  /// Whether the selected timer's countdown is advancing.
  final bool running;

  /// Whether the selected timer reached zero and is awaiting a reset.
  final bool finished;

  /// The selected timer's config, or null if nothing is selected.
  TimerConfig? get selected {
    for (final t in timers) {
      if (t.id == selectedId) return t;
    }
    return null;
  }

  /// The selected timer's full configured length.
  Duration get duration => selected?.duration ?? Duration.zero;

  /// Fraction of the countdown already elapsed, 0..1. Drives the ring sweep.
  double get progress {
    final total = duration.inMilliseconds;
    if (total <= 0) return 0;
    final done = total - remaining.inMilliseconds;
    return (done / total).clamp(0.0, 1.0);
  }

  TimerState copyWith({
    List<TimerConfig>? timers,
    Duration? remaining,
    bool? running,
    bool? finished,
  }) {
    return TimerState(
      timers: timers ?? this.timers,
      selectedId: selectedId,
      remaining: remaining ?? this.remaining,
      running: running ?? this.running,
      finished: finished ?? this.finished,
    );
  }
}
