part of 'timer_cubit.dart';

/// Which leg of a Pomodoro cycle the selected timer is currently on.
enum PomodoroPhase { focus, shortBreak, longBreak }

/// View state for the multi-timer module. The countdown applies to the single
/// [selectedId] timer — only one timer runs at a time.
class TimerState {
  const TimerState({
    this.timers = const [],
    this.selectedId,
    this.selectedName = '',
    this.remaining = Duration.zero,
    this.running = false,
    this.finished = false,
    this.phase = PomodoroPhase.focus,
    this.completedFocus = 0,
    this.logs = const [],
  });

  /// All configured timers, in display order (mirrors the persisted settings).
  final List<TimerConfig> timers;

  /// The timer the countdown currently applies to, or null when none is armed.
  final String? selectedId;

  /// The selected timer's resolved display name, captured when it was armed so
  /// completed focus sessions can be logged without access to localization.
  final String selectedName;

  /// Time left in the selected timer's countdown.
  final Duration remaining;

  /// Whether the selected timer's countdown is advancing.
  final bool running;

  /// Whether the current phase reached zero and is awaiting the next action
  /// (a reset, or — for a finished break — a manual focus restart).
  final bool finished;

  /// The current leg of the Pomodoro cycle for the selected timer.
  final PomodoroPhase phase;

  /// Focus sessions completed in the current cycle, counting towards the next
  /// long break. Reset to zero after a long break.
  final int completedFocus;

  /// The full recorded focus-session history (for the statistics report).
  final List<PomodoroLog> logs;

  /// The selected timer's config, or null if nothing is selected.
  TimerConfig? get selected {
    for (final t in timers) {
      if (t.id == selectedId) return t;
    }
    return null;
  }

  /// Whether the selected timer is a Pomodoro task.
  bool get isPomodoro => selected?.pomodoro ?? false;

  /// Whether there is any recorded history to show on the statistics page.
  bool get hasStats => logs.isNotEmpty;

  /// Whether the current phase is a break rather than focus.
  bool get onBreak => phase != PomodoroPhase.focus;

  /// The full configured length of the current phase: the selected timer's focus
  /// duration, or its short/long break when on a break leg.
  Duration get duration {
    final sel = selected;
    if (sel == null) return Duration.zero;
    switch (phase) {
      case PomodoroPhase.focus:
        return sel.duration;
      case PomodoroPhase.shortBreak:
        return sel.shortBreak;
      case PomodoroPhase.longBreak:
        return sel.longBreak;
    }
  }

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
    PomodoroPhase? phase,
    int? completedFocus,
    List<PomodoroLog>? logs,
  }) {
    return TimerState(
      timers: timers ?? this.timers,
      selectedId: selectedId,
      selectedName: selectedName,
      remaining: remaining ?? this.remaining,
      running: running ?? this.running,
      finished: finished ?? this.finished,
      phase: phase ?? this.phase,
      completedFocus: completedFocus ?? this.completedFocus,
      logs: logs ?? this.logs,
    );
  }
}
