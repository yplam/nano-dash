/// Pure-Dart types shared by the native and web [PicoViewController] backends.
///
/// Kept free of `dart:ffi`/`dart:isolate` so it compiles on every target.
library;

import 'package:flutter/foundation.dart';

/// Phase of a physical-touch event reported by the panel.
enum TouchPhase { down, move, up }

/// A touch event in LCD pixel coordinates.
@immutable
class PicoTouchEvent {
  const PicoTouchEvent(this.phase, this.x, this.y);

  final TouchPhase phase;
  final int x;
  final int y;

  @override
  String toString() => 'PicoTouchEvent($phase, $x, $y)';
}

/// Width/height of each built-in panel [model](PicoViewConfig.model), so the
/// `PicoView` widget can size its capture surface without a round-trip to native.
/// Keep in sync with the Rust `panels` preset registry.
const Map<String, ({int width, int height})> kPicoViewModels = {
  'st77916-round-360': (width: 360, height: 360),
};

const String kPicoViewDefaultModel = 'st77916-round-360';

/// Open-time device configuration.
@immutable
class PicoViewConfig {
  const PicoViewConfig({this.model = kPicoViewDefaultModel});

  /// Panel model name; resolved to a preset on the native side.
  final String model;

  /// Visible width of the selected [model] in pixels, or `0` if unknown.
  int get width => kPicoViewModels[model]?.width ?? 0;

  /// Visible height of the selected [model] in pixels, or `0` if unknown.
  int get height => kPicoViewModels[model]?.height ?? 0;

  Map<String, dynamic> toJson() => {'model': model};
}

@immutable
class SystemTemperature {
  const SystemTemperature(this.label, this.celsius);

  final String label;
  final double celsius;
}

/// A single snapshot of host-machine telemetry produced by `sampleSystem()`.
@immutable
class SystemSnapshot {
  const SystemSnapshot({
    required this.cpuUsage,
    required this.cpuCores,
    required this.cpuFreqMhz,
    required this.memTotal,
    required this.memUsed,
    required this.swapTotal,
    required this.swapUsed,
    required this.netRxBps,
    required this.netTxBps,
    required this.netRxTotal,
    required this.netTxTotal,
    required this.temperatures,
    required this.loadAverage,
  });

  /// Overall CPU utilization, 0–100.
  final double cpuUsage;

  /// Per-core utilization (0–100), in the CPUs' listed order.
  final List<double> cpuCores;

  /// Max reported core frequency, in MHz (`0` if unknown).
  final int cpuFreqMhz;

  /// Physical memory, in bytes.
  final int memTotal;
  final int memUsed;

  /// Swap, in bytes.
  final int swapTotal;
  final int swapUsed;

  /// Network throughput over the last interval, in bytes/second (summed over
  /// all interfaces).
  final int netRxBps;
  final int netTxBps;

  /// Cumulative bytes received/transmitted since the sampler opened.
  final int netRxTotal;
  final int netTxTotal;

  /// Available temperature sensors (may be empty on some platforms).
  final List<SystemTemperature> temperatures;

  /// Unix load average `[1m, 5m, 15m]`; all zero on Windows.
  final List<double> loadAverage;

  /// Fraction of memory used, 0.0–1.0 (`0` when [memTotal] is 0).
  double get memFraction => memTotal == 0 ? 0 : memUsed / memTotal;

  factory SystemSnapshot.fromJson(Map<String, dynamic> json) {
    double d(dynamic v) => (v as num?)?.toDouble() ?? 0;
    int i(dynamic v) => (v as num?)?.toInt() ?? 0;
    final cpu = (json['cpu'] as Map?)?.cast<String, dynamic>() ?? const {};
    final mem = (json['mem'] as Map?)?.cast<String, dynamic>() ?? const {};
    final net = (json['net'] as Map?)?.cast<String, dynamic>() ?? const {};
    return SystemSnapshot(
      cpuUsage: d(cpu['usage']),
      cpuCores: ((cpu['cores'] as List?) ?? const []).map((e) => d(e)).toList(),
      cpuFreqMhz: i(cpu['freqMhz']),
      memTotal: i(mem['total']),
      memUsed: i(mem['used']),
      swapTotal: i(mem['swapTotal']),
      swapUsed: i(mem['swapUsed']),
      netRxBps: i(net['rxBps']),
      netTxBps: i(net['txBps']),
      netRxTotal: i(net['rxTotal']),
      netTxTotal: i(net['txTotal']),
      temperatures: ((json['temps'] as List?) ?? const [])
          .map((e) => (e as Map).cast<String, dynamic>())
          .map((e) => SystemTemperature(e['label'] as String? ?? '', d(e['c'])))
          .toList(),
      loadAverage: ((json['loadAvg'] as List?) ?? const [])
          .map((e) => d(e))
          .toList(),
    );
  }
}

/// Thrown when a native call fails.
class PicoViewException implements Exception {
  PicoViewException(this.message, {this.code});

  final String message;

  /// The native return code, when the failure came from an FFI call.
  final int? code;

  @override
  String toString() => 'PicoViewException: $message';
}

/// Thrown by `open` when the connected device failed hardware attestation.
class PicoViewUnauthorizedException extends PicoViewException {
  PicoViewUnauthorizedException()
    : super('unauthorized device: hardware attestation failed', code: -4);
}
