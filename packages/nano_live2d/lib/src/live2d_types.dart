/// Pure-Dart types shared by the FFI ([live2d_controller_io.dart]) and web-stub
/// ([live2d_controller_stub.dart]) implementations of [Live2dController]. Kept
/// free of `dart:ffi` so it imports cleanly on the web.
library;

/// Thrown when a native call fails.
class Live2dException implements Exception {
  Live2dException(this.message);

  final String message;

  @override
  String toString() => 'Live2dException: $message';
}

/// Motion priority. A starting motion only interrupts one of lower priority, so
/// use [normal]/[force] for user-triggered motions to override the auto-[idle].
enum Live2dMotionPriority {
  none(0),
  idle(1),
  normal(2),
  force(3);

  const Live2dMotionPriority(this.value);

  final int value;
}
