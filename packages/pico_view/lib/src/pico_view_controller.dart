/// The [PicoViewController]: owns the FFI lifecycle (init / open / flush / touch
/// channel) for the native pico_view bridge.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:ffi' as ffi;
import 'dart:isolate';

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';

import 'pico_view_bindings_generated.dart' as bindings;

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
/// [PicoView] widget can size its capture surface without a round-trip to native.
/// Keep in sync with the Rust `panels` preset registry.
const Map<String, ({int width, int height})> kPicoViewModels = {
  'st77916-round-360': (width: 360, height: 360),
  'st7789-1.69': (width: 240, height: 280),
};

/// The default panel model (the 360x360 ST77916 round display).
const String kPicoViewDefaultModel = 'st77916-round-360';

/// Open-time device configuration.
///
/// The caller only chooses *which device* to open ([device] on Linux, [index]
/// on macOS/Windows) and *which panel* is wired up, by [model] name.
@immutable
class PicoViewConfig {
  const PicoViewConfig({
    this.device = '/dev/ch34x_pis0',
    this.index = 0,
    this.model = kPicoViewDefaultModel,
  });

  final String device;
  final int index;

  /// Panel model name; resolved to a preset on the native side.
  final String model;

  /// Visible width of the selected [model] in pixels, or `0` if unknown.
  int get width => kPicoViewModels[model]?.width ?? 0;

  /// Visible height of the selected [model] in pixels, or `0` if unknown.
  int get height => kPicoViewModels[model]?.height ?? 0;

  Map<String, dynamic> toJson() => {
    'device': device,
    'index': index,
    'model': model,
  };
}

/// Thrown when a native call fails.
class PicoViewException implements Exception {
  PicoViewException(this.message);

  final String message;

  @override
  String toString() => 'PicoViewException: $message';
}

/// Owns the native bridge. Create one, [init] it once, then [open] a device.
///
/// The native side keeps a single device + SendPort, so use a single controller
/// per app.
class PicoViewController {
  final ReceivePort _rx = ReceivePort();
  final StreamController<PicoTouchEvent> _touch =
      StreamController<PicoTouchEvent>.broadcast();

  bool _initialized = false;
  bool _opened = false;
  bool _disposed = false;

  PicoViewConfig _config = const PicoViewConfig();

  /// Reusable frame buffer (grows once, freed in [dispose]). Safe to reuse
  /// because the copy → FFI-call critical section is synchronous.
  ffi.Pointer<ffi.Uint8>? _frameBuffer;
  int _frameBufferCap = 0;

  /// Physical-touch events in LCD pixel coordinates.
  Stream<PicoTouchEvent> get touches => _touch.stream;

  /// The currently-open device config (geometry used by [PicoView]).
  PicoViewConfig get config => _config;

  bool get isOpen => _opened;

  /// Wire up the Dart DL API + SendPort. Call once before [open].
  void init() {
    if (_initialized) return;
    bindings.pv_init(
      ffi.NativeApi.initializeApiDLData,
      _rx.sendPort.nativePort,
    );
    _rx.listen(_onMessage);
    _initialized = true;
  }

  /// Open the CH347 device and start the worker. Throws [PicoViewException] on
  /// failure (bad config, device busy, open/setup error — the return code
  /// distinguishes which).
  void open(PicoViewConfig config) {
    if (!_initialized) init();
    final jsonBytes = utf8.encode(jsonEncode(config.toJson()));
    final ptr = malloc.allocate<ffi.Uint8>(jsonBytes.length);
    try {
      ptr.asTypedList(jsonBytes.length).setAll(0, jsonBytes);
      final rc = bindings.pv_open(ptr, jsonBytes.length);
      if (rc != 0) {
        throw PicoViewException('pv_open failed (code $rc)');
      }
      _config = config;
      _opened = true;
    } finally {
      malloc.free(ptr);
    }
  }

  /// Push one tightly-packed RGBA8888 frame (`rgba.length == width*height*4`).
  /// Returns false if the device isn't open or the enqueue was rejected.
  bool flushRgba(Uint8List rgba, int width, int height) {
    if (_disposed || !_opened) return false;
    if (rgba.length > _frameBufferCap) {
      if (_frameBuffer != null) malloc.free(_frameBuffer!);
      _frameBuffer = malloc.allocate<ffi.Uint8>(rgba.length);
      _frameBufferCap = rgba.length;
    }
    _frameBuffer!.asTypedList(rgba.length).setAll(0, rgba);
    return bindings.pv_lcd_flush(_frameBuffer!, rgba.length, width, height) ==
        0;
  }

  /// Decode a touch event JSON string pushed from the native side, e.g.
  /// `{"phase":"down","x":12,"y":34}`.
  void _onMessage(dynamic raw) {
    if (raw is! String) return;
    final Map<String, dynamic> map;
    try {
      map = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return;
    }
    final phase = switch (map['phase']) {
      'down' => TouchPhase.down,
      'move' => TouchPhase.move,
      'up' => TouchPhase.up,
      _ => null,
    };
    if (phase == null) return;
    final x = (map['x'] as num?)?.toInt() ?? 0;
    final y = (map['y'] as num?)?.toInt() ?? 0;
    if (kDebugMode) {
      debugPrint('PicoView touch: $phase ($x, $y)');
    }
    _touch.add(PicoTouchEvent(phase, x, y));
  }

  /// Close the device and release all resources. Safe to call multiple times.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    if (_opened) {
      bindings.pv_close();
      _opened = false;
    }
    if (_frameBuffer != null) {
      malloc.free(_frameBuffer!);
      _frameBuffer = null;
    }
    _touch.close();
    _rx.close();
  }
}
