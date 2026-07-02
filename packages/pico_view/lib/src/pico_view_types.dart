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

/// Thrown when a native call fails.
class PicoViewException implements Exception {
  PicoViewException(this.message);

  final String message;

  @override
  String toString() => 'PicoViewException: $message';
}
