/// [Live2dController]: owns one native renderer handle. Behind the handle a
/// background worker thread holds the offscreen GL context + model, advances the
/// animation on its own clock, and renders at a fixed cadence.
library;

import 'dart:ffi' as ffi;
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import 'nano_live2d_bindings_generated.dart' as bindings;

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

class Live2dController {
  Live2dController._(this._handle, this.width, this.height);

  /// Create a renderer with an offscreen RGBA framebuffer of [width]x[height].
  /// [shaderDir] optionally overrides where framework shaders are read from; the
  /// bundled library embeds them, so it can be omitted.
  factory Live2dController({
    required int width,
    required int height,
    String? shaderDir,
  }) {
    if (shaderDir != null) {
      final sd = shaderDir.toNativeUtf8();
      try {
        bindings.nl_set_shader_dir(sd);
      } finally {
        malloc.free(sd);
      }
    }
    final h = bindings.nl_create(width, height);
    if (h == ffi.nullptr) {
      throw Live2dException('nl_create($width, $height) failed');
    }
    return Live2dController._(h, width, height);
  }

  final int width;
  final int height;
  ffi.Pointer<ffi.Void> _handle;
  bool _disposed = false;
  bool _frameHeld = false;

  /// Bytes per frame (`width * height * 4`).
  int get frameBytes => width * height * 4;

  /// Load a model.
  bool load(String dir, String model3Json) {
    _checkAlive();
    final d = dir.toNativeUtf8();
    final j = model3Json.toNativeUtf8();
    try {
      return bindings.nl_load(_handle, d, j) == 0;
    } finally {
      malloc.free(d);
      malloc.free(j);
    }
  }

  /// Look-at target, normalized to [-1, 1] (0,0 = center).
  void setDrag(double nx, double ny) {
    if (_disposed) return;
    bindings.nl_set_drag(_handle, nx, ny);
  }

  /// Tap at a normalized point [-1, 1]; a body hit triggers a motion.
  void tap(double nx, double ny) {
    if (_disposed) return;
    bindings.nl_tap(_handle, nx, ny);
  }

  /// Number of motions in [group]. The model's groups come from its
  /// `model3.json`; many models export a single **unnamed** group, addressed by
  /// the empty string `''` (the default).
  int motionCount([String group = '']) {
    if (_disposed) return 0;
    final g = group.toNativeUtf8();
    try {
      return bindings.nl_motion_count(_handle, g);
    } finally {
      malloc.free(g);
    }
  }

  /// Start motion [index] of [group],  [index] < 0 plays a random motion from the group.
  /// Use [Live2dMotionPriority.normal] or higher to override the auto-played idle.
  void startMotion({
    String group = '',
    int index = -1,
    Live2dMotionPriority priority = Live2dMotionPriority.normal,
  }) {
    if (_disposed) return;
    final g = group.toNativeUtf8();
    try {
      bindings.nl_start_motion(_handle, g, index, priority.value);
    } finally {
      malloc.free(g);
    }
  }

  /// Acquire the newest worker-rendered frame as RGBA8888 pixels (top row first,
  /// [frameBytes] long), or null if no new frame has been produced since the
  /// last [acquireFrame].
  Uint8List? acquireFrame() {
    if (_disposed) return null;
    final p = bindings.nl_acquire_frame(_handle);
    if (p == ffi.nullptr) return null;
    _frameHeld = true;
    return p.asTypedList(frameBytes);
  }

  /// Release the frame from the last [acquireFrame], letting the worker reuse that buffer.
  void releaseFrame() {
    if (_disposed || !_frameHeld) return;
    _frameHeld = false;
    bindings.nl_release_frame(_handle);
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _frameHeld = false;
    bindings.nl_destroy(_handle);
    _handle = ffi.nullptr;
  }

  void _checkAlive() {
    if (_disposed) throw Live2dException('controller disposed');
  }
}
