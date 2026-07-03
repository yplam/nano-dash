part of 'system_monitor_cubit.dart';

/// One retained telemetry reading. Percentages are 0–100; rates are bytes/sec.
@immutable
class SystemMonitorSample {
  const SystemMonitorSample({
    required this.time,
    required this.cpu,
    required this.mem,
    required this.netRxBps,
    required this.netTxBps,
  });

  final DateTime time;
  final double cpu;
  final double mem;
  final double netRxBps;
  final double netTxBps;
}

/// State for the system monitor: the most recent snapshot plus the rolling
/// history that backs the sparklines.
@immutable
class SystemMonitorState {
  const SystemMonitorState({this.latest, this.history = const []});

  /// The most recent snapshot, or null before the first sample lands.
  final SystemSnapshot? latest;

  /// Retained samples over the last ~1 minutes, oldest first.
  final List<SystemMonitorSample> history;

  List<double> get cpuHistory => [for (final s in history) s.cpu];

  List<double> get memHistory => [for (final s in history) s.mem];

  List<double> get netRxHistory => [for (final s in history) s.netRxBps];

  List<double> get netTxHistory => [for (final s in history) s.netTxBps];
}
