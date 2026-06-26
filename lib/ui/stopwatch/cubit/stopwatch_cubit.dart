import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

part 'stopwatch_state.dart';

/// Owns the stopwatch module's timing. The count keeps running while the user
/// is on another page.
class StopwatchCubit extends Cubit<StopwatchState> {
  StopwatchCubit() : super(const StopwatchState());

  /// How often the readout updates while running. Fast enough for a smooth
  /// centisecond display without flooding the SPI panel with frames.
  static const Duration _kTick = Duration(milliseconds: 50);

  final Stopwatch _sw = Stopwatch();
  Timer? _ticker;

  /// Start (or resume) counting.
  void start() {
    if (state.running) return;
    _sw.start();
    _ticker = Timer.periodic(_kTick, (_) => emit(_snapshot(running: true)));
    emit(_snapshot(running: true));
  }

  /// Pause, holding the elapsed time.
  void pause() {
    if (!state.running) return;
    _sw.stop();
    _ticker?.cancel();
    _ticker = null;
    emit(_snapshot(running: false));
  }

  /// Stop and zero the elapsed time, clearing any recorded splits.
  void reset() {
    _sw
      ..stop()
      ..reset();
    _ticker?.cancel();
    _ticker = null;
    emit(const StopwatchState());
  }

  /// Record a split. Only acts while running; the lap is measured against the previous split.
  void split() {
    if (!state.running) return;
    final total = _sw.elapsed;
    final lastTotal = state.laps.isEmpty
        ? Duration.zero
        : state.laps.last.total;
    final lap = Lap(
      index: state.laps.length + 1,
      lapTime: total - lastTotal,
      total: total,
    );
    emit(_snapshot(running: true, laps: [...state.laps, lap]));
  }

  StopwatchState _snapshot({required bool running, List<Lap>? laps}) =>
      StopwatchState(
        elapsed: _sw.elapsed,
        running: running,
        laps: laps ?? state.laps,
      );

  @override
  Future<void> close() {
    _ticker?.cancel();
    return super.close();
  }
}
