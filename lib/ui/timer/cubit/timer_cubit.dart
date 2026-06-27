import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/timer_config.dart';

part 'timer_state.dart';

/// Owns the countdown timer module's state.
class TimerCubit extends Cubit<TimerState> {
  TimerCubit() : super(const TimerState());

  /// Readout update cadence while running.
  static const Duration _kTick = Duration(milliseconds: 100);

  /// Used to measure real elapsed time so the countdown stays accurate even if
  /// ticks are delayed by a busy UI/SPI flush.
  final Stopwatch _sw = Stopwatch();
  Timer? _ticker;

  /// Mirror the persisted timer list into the cubit. Called by the view when
  /// the configured timers change.
  void syncTimers(List<TimerConfig> timers) {
    final selected = _find(timers, state.selectedId);

    if (selected == null) {
      if (state.selectedId != null) {
        _stopTicker();
        emit(TimerState(timers: timers));
      } else {
        emit(state.copyWith(timers: timers));
      }
      return;
    }

    final fresh =
        !state.running && !state.finished && state.remaining == state.duration;
    if (fresh) {
      emit(
        TimerState(
          timers: timers,
          selectedId: selected.id,
          remaining: selected.duration,
        ),
      );
    } else {
      emit(state.copyWith(timers: timers));
    }
  }

  static TimerConfig? _find(List<TimerConfig> timers, String? id) {
    if (id == null) return null;
    for (final t in timers) {
      if (t.id == id) return t;
    }
    return null;
  }

  /// Arm a timer for counting down. Re-selecting the current timer is a no-op so
  /// opening its detail view never discards an in-progress (paused) countdown;
  /// switching to a different timer resets the previous one.
  void select(String id) {
    if (id == state.selectedId) return;
    final cfg = _find(state.timers, id);
    if (cfg == null) return;
    _stopTicker();
    emit(
      TimerState(
        timers: state.timers,
        selectedId: cfg.id,
        remaining: cfg.duration,
      ),
    );
  }

  /// Start (or resume) the selected countdown.
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
    _stopTicker();
    emit(state.copyWith(running: false));
  }

  /// Stop and restore the selected timer's full configured duration.
  void reset() {
    _sw
      ..stop()
      ..reset();
    _stopTicker();
    emit(
      state.copyWith(
        remaining: state.duration,
        running: false,
        finished: false,
      ),
    );
  }

  /// Recompute remaining time from real elapsed against [base] (the remaining
  /// time when the current run started). Fires the finish when it hits zero.
  void _onTick(Duration base) {
    final left = base - _sw.elapsed;
    if (left <= Duration.zero) {
      _sw.stop();
      _stopTicker();
      // TODO: honour selected.sound / selected.vibrate here once alert
      // playback (sound + haptics) is implemented.
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

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  @override
  Future<void> close() {
    _ticker?.cancel();
    return super.close();
  }
}
