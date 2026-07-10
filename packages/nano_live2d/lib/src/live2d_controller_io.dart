/// FFI-backed [Live2dController]: owns one native renderer handle. Behind the
/// handle a background worker thread holds the offscreen GL context + model,
/// advances the animation on its own clock, and renders at a fixed cadence.
///
/// Selected on native platforms by [live2d_controller.dart]; the web build gets
/// [live2d_controller_stub.dart] instead.
library;

import 'dart:ffi' as ffi;
import 'dart:isolate';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import 'live2d_types.dart';
import 'nano_live2d_bindings_generated.dart' as bindings;

export 'live2d_types.dart';

class Live2dController {
  Live2dController._(this._handle, this.width, this.height);

  /// Create a renderer with an offscreen RGBA framebuffer of [width]x[height].
  /// [shaderDir] optionally overrides where framework shaders are read from; the
  /// bundled library embeds them, so it can be omitted.
  ///
  /// `nl_create` blocks synchronously while the native worker thread spins up
  /// its offscreen GL context, so the call runs on a background isolate (the
  /// pointer it returns is sent back as a plain address) to keep the caller's
  /// event loop — and any on-screen animation — from stalling while it waits.
  static Future<Live2dController> create({
    required int width,
    required int height,
    String? shaderDir,
  }) async {
    final handleAddress = await Isolate.run(() {
      if (shaderDir != null) {
        final sd = shaderDir.toNativeUtf8();
        try {
          bindings.nl_set_shader_dir(sd);
        } finally {
          malloc.free(sd);
        }
      }
      return bindings.nl_create(width, height).address;
    });
    final h = ffi.Pointer<ffi.Void>.fromAddress(handleAddress);
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
  ///
  /// `nl_load` blocks synchronously while the native worker decodes textures
  /// and motions, so — like [create] — it runs on a background isolate to keep
  /// the caller's event loop from stalling while it waits.
  Future<bool> load(String dir, String model3Json) async {
    _checkAlive();
    final handleAddress = _handle.address;
    final result = await Isolate.run(() {
      final h = ffi.Pointer<ffi.Void>.fromAddress(handleAddress);
      final d = dir.toNativeUtf8();
      final j = model3Json.toNativeUtf8();
      try {
        return bindings.nl_load(h, d, j);
      } finally {
        malloc.free(d);
        malloc.free(j);
      }
    });
    return result == 0;
  }

  /// Pause ([active] false) or resume ([active] true) the native render loop.
  void setActive(bool active) {
    if (_disposed) return;
    bindings.nl_set_active(_handle, active ? 1 : 0);
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

  /// Mouth openness in `[0, 1]` (clamped natively), applied to the model's
  /// LipSync parameters.
  void setLipSyncValue(double value) {
    if (_disposed) return;
    bindings.nl_set_lip_sync_value(_handle, value);
  }

  /// Number of expressions the loaded model declares (0 if none, or if no model
  /// is loaded). See [expressionName].
  int get expressionCount {
    if (_disposed) return 0;
    return bindings.nl_expression_count(_handle);
  }

  /// The name of expression [index], or null when [index] is out of range.
  String? expressionName(int index) {
    if (_disposed) return null;
    const cap = 128;
    final buf = malloc<ffi.Uint8>(cap).cast<Utf8>();
    try {
      final len = bindings.nl_expression_name(_handle, index, buf, cap);
      if (len <= 0) return null;
      return buf.toDartString();
    } finally {
      malloc.free(buf);
    }
  }

  /// Every expression name, in the order the model declares them.
  List<String> get expressionNames => [
    for (var i = 0; i < expressionCount; i++) expressionName(i) ?? '',
  ];

  /// Fade to the expression called [name] (one of [expressionNames]), or back to
  /// no expression when [name] is null or empty. Unknown names are ignored.
  void setExpression(String? name) {
    if (_disposed) return;
    final n = (name ?? '').toNativeUtf8();
    try {
      bindings.nl_set_expression(_handle, n);
    } finally {
      malloc.free(n);
    }
  }

  /// Pin the Cubism parameter [id] (e.g. `'ParamMouthForm'`) to [value], blended
  /// by [weight]. The override is re-applied after motions and effects on every
  /// frame — so it always wins — until [clearParameter]. When [add] is true it
  /// adds to what the motions and effects produced instead of replacing it.
  void setParameter(
    String id,
    double value, {
    double weight = 1.0,
    bool add = false,
  }) {
    if (_disposed) return;
    final p = id.toNativeUtf8();
    try {
      if (add) {
        bindings.nl_add_parameter(_handle, p, value, weight);
      } else {
        bindings.nl_set_parameter(_handle, p, value, weight);
      }
    } finally {
      malloc.free(p);
    }
  }

  /// Drop the override on [id], or on every parameter when [id] is null.
  void clearParameter([String? id]) {
    if (_disposed) return;
    final p = (id ?? '').toNativeUtf8();
    try {
      bindings.nl_clear_parameter(_handle, p);
    } finally {
      malloc.free(p);
    }
  }

  /// The current value of parameter [id] as of the worker's last update (after
  /// motions, effects and overrides). 0 when the model isn't loaded or has no
  /// such parameter. Blocks briefly for the worker's reply.
  double getParameter(String id) {
    if (_disposed) return 0;
    final p = id.toNativeUtf8();
    try {
      return bindings.nl_get_parameter(_handle, p);
    } finally {
      malloc.free(p);
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

  /// Callers must not dispose while a [create]/[load] call is still in flight
  /// on its background isolate — that isolate holds the same native handle and
  /// racing it with `nl_destroy` here is a use-after-free on the native side.
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
