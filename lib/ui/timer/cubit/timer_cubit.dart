import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

part 'timer_state.dart';

/// Owns the countdown timer module's state. The countdown keeps running — and can
/// finish — while the user is on another page.
class TimerCubit extends Cubit<TimerState> {
  TimerCubit() : super(const TimerState());

  /// Readout update cadence while running. The display is second-granular, but
  /// a sub-second tick keeps the ring sweep smooth and the final flip prompt.
  static const Duration _kTick = Duration(milliseconds: 100);

  /// Used to measure real elapsed time so the countdown stays accurate even if
  /// ticks are delayed by a busy UI/SPI flush.
  final Stopwatch _sw = Stopwatch();
  Timer? _ticker;

  /// Set the total countdown duration. Ignored while running. Resets the
  /// remaining time and clears any finished state.
  void setDuration(Duration duration) {
    if (state.running) return;
    final d = duration.isNegative ? Duration.zero : duration;
    _sw.reset();
    emit(TimerState(duration: d, remaining: d));
  }

  /// Start (or resume) the countdown. Does nothing with no time remaining.
  void start() {
    if (state.running || state.remaining <= Duration.zero) return;
    _sw
      ..reset()
      ..start();
    final base = state.remaining;
    _ticker = Timer.periodic(_kTick, (_) => _onTick(base));
    emit(state.copyWith(running: true, finished: false));
  }

  /// Pause, holding the remaining time.
  void pause() {
    if (!state.running) return;
    _sw.stop();
    _ticker?.cancel();
    _ticker = null;
    emit(state.copyWith(running: false));
  }

  /// Stop and restore the full configured duration.
  void reset() {
    _sw
      ..stop()
      ..reset();
    _ticker?.cancel();
    _ticker = null;
    emit(TimerState(duration: state.duration, remaining: state.duration));
  }

  /// Recompute remaining time from real elapsed against [base] (the remaining
  /// time when the current run started). Fires the finish when it hits zero.
  void _onTick(Duration base) {
    final left = base - _sw.elapsed;
    if (left <= Duration.zero) {
      _sw.stop();
      _ticker?.cancel();
      _ticker = null;
      emit(
        state.copyWith(
          remaining: Duration.zero,
          running: false,
          finished: true,
        ),
      );
      return;
    }
    emit(state.copyWith(remaining: left));
  }

  @override
  Future<void> close() {
    _ticker?.cancel();
    return super.close();
  }
}
