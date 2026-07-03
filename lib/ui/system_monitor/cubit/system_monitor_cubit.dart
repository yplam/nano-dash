import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pico_view/pico_view.dart';

part 'system_monitor_state.dart';

/// Continuously samples host telemetry from the native `pico_view` sampler and
/// keeps a rolling one minute history in state.
class SystemMonitorCubit extends Cubit<SystemMonitorState> {
  SystemMonitorCubit() : super(const SystemMonitorState()) {
    _pv.openSystem();
    _sample();
    _timer = Timer.periodic(_kTick, (_) => _sample());
  }

  /// Own a controller purely for host sampling — it never opens a device, so it
  /// coexists with the dashboard's controller (the native sampler is global).
  final PicoViewController _pv = PicoViewController();
  Timer? _timer;

  /// How far back the retained history reaches; older samples are dropped.
  static const Duration _kWindow = Duration(minutes: 1);

  /// Sampling cadence.
  static const Duration _kTick = Duration(seconds: 1);

  void _sample() {
    final snap = _pv.sampleSystem();
    if (snap == null || isClosed) return;
    final now = DateTime.now();
    final cutoff = now.subtract(_kWindow);
    final history = <SystemMonitorSample>[
      for (final s in state.history)
        if (s.time.isAfter(cutoff)) s,
      SystemMonitorSample(
        time: now,
        cpu: snap.cpuUsage,
        mem: snap.memFraction * 100,
        netRxBps: snap.netRxBps.toDouble(),
        netTxBps: snap.netTxBps.toDouble(),
      ),
    ];
    emit(SystemMonitorState(latest: snap, history: history));
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    _pv.dispose();
    return super.close();
  }
}
