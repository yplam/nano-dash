/// The [PicoView] container widget: mirror its child subtree to the physical LCD
/// and feed physical touches back into that same subtree.
library;

import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart' show SchedulerPhase;
import 'package:flutter/widgets.dart';

import 'pico_view_controller.dart';

/// A container whose child subtree is continuously captured and pushed to the
/// LCD attached via [controller], while physical touches on the panel are
/// injected back into the subtree as synthetic pointer events.
///
/// The child is laid out at exactly the LCD's logical resolution
/// (`controller.config.width` x `.height`), so a captured pixel maps 1:1 to a
/// panel pixel and a panel touch maps 1:1 to a child-local coordinate.
class PicoView extends StatefulWidget {
  const PicoView({
    super.key,
    required this.controller,
    required this.child,
    this.maxFps = 25,
    this.enableTouch = true,
  });

  /// The bridge to the native device. Must already be [PicoViewController.open]ed
  /// (or opened later — the widget reads geometry from `controller.config`).
  final PicoViewController controller;

  /// The subtree to mirror to the LCD.
  final Widget child;

  /// Capture cap. Frames are only sent when the content actually changed, so a
  /// static screen produces no USB traffic regardless of this value.
  final int maxFps;

  /// Inject panel touches into the subtree as synthetic pointer events.
  final bool enableTouch;

  @override
  State<PicoView> createState() => _PicoViewState();
}

class _PicoViewState extends State<PicoView> with WidgetsBindingObserver {
  final GlobalKey _boundaryKey = GlobalKey();

  // Capture is driven off Flutter's frame pipeline (a single post-frame callback
  // that re-arms itself) rather than a fixed-rate timer: it fires exactly when a
  // frame is painted, so the LCD tracks on-screen animation with minimal phase
  // lag, and costs nothing while the mirrored subtree is static.
  bool _looping = false;
  bool _capturing = false;
  int _lastHash = 0;

  /// Tracks the falling edge of [PicoViewController.suspendCapture] so the mirror
  /// loop forces a fresh capture when an external producer (the video module)
  /// releases the panel.
  bool _wasSuspended = false;

  /// Frame-rate budget in milliseconds, derived from [PicoView.maxFps].
  int _minIntervalMs = 38;

  /// Monotonic clock used to throttle captures to [PicoView.maxFps].
  final Stopwatch _clock = Stopwatch()..start();
  int _lastCaptureMs = -1 << 30;

  /// Deferred capture that guarantees the final resting frame still reaches the
  /// panel when an animation settles inside a throttle window (after which no
  /// further frames — and so no further post-frame callbacks — would fire).
  Timer? _trailingTimer;

  /// Drives the frame pipeline manually while the window is off-screen.
  Timer? _pumpTimer;

  StreamSubscription<PicoTouchEvent>? _touchSub;

  // Synthetic pointer identity, kept distinct from real input devices.
  static const int _pointerId = 0x70C0;
  Offset _lastGlobal = Offset.zero;
  bool _down = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startCapture();
    if (widget.enableTouch) {
      _touchSub = widget.controller.touches.listen(_onTouch);
    }
  }

  @override
  void didUpdateWidget(PicoView old) {
    super.didUpdateWidget(old);
    if (old.maxFps != widget.maxFps) {
      _startCapture();
    }
    if (old.enableTouch != widget.enableTouch) {
      _touchSub?.cancel();
      _touchSub = widget.enableTouch
          ? widget.controller.touches.listen(_onTouch)
          : null;
    }
  }

  void _startCapture() {
    if (kIsWeb) return;
    _minIntervalMs = (1000 / widget.maxFps.clamp(16, 120)).round();
    // Start the per-frame loop once; subsequent maxFps changes only retune the
    // budget above. A second concurrent loop would double every capture.
    if (!_looping) {
      _looping = true;
      WidgetsBinding.instance.addPostFrameCallback(_onFrame);
    }
    // If we're currently driving frames manually, restart the timer so the new
    // budget takes effect immediately.
    if (_pumpTimer != null) {
      _stopPumping();
      _startPumping();
    }
  }

  /// Track window visibility. On desktop, hiding to the tray or minimizing takes
  /// the app out of [AppLifecycleState.resumed]; the engine then stops requesting
  /// frames, so the post-frame capture loop goes idle and the mirrored content
  /// freezes. While off-screen we drive the pipeline ourselves; when visible
  /// again the engine's vsync takes back over.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final offscreen =
        state == AppLifecycleState.hidden || state == AppLifecycleState.paused;
    if (offscreen) {
      _startPumping();
    } else {
      _stopPumping();
    }
  }

  void _startPumping() {
    if (kIsWeb || _pumpTimer != null) return;
    // Rebase the scheduler's frame epoch onto the last real frame so the
    // synthetic timestamps we feed below continue smoothly from it.
    WidgetsBinding.instance.resetEpoch();
    // Match the capture budget; each pumped frame runs build/layout/paint and
    // fires the re-armed post-frame callback.
    _pumpTimer = Timer.periodic(
      Duration(milliseconds: _minIntervalMs),
      (_) => _pump(),
    );
  }

  void _stopPumping() {
    if (_pumpTimer == null) return;
    _pumpTimer!.cancel();
    _pumpTimer = null;
    // Rebase again so the engine's first real frame.
    WidgetsBinding.instance.resetEpoch();
    WidgetsBinding.instance.scheduleFrame();
  }

  /// Manually advance the frame pipeline one step while off-screen.
  /// Feeding [_clock].elapsed as the frame time keeps `AnimationController`s
  /// running in real time.
  void _pump() {
    if (!mounted) return;
    final binding = WidgetsBinding.instance;
    if (binding.schedulerPhase != SchedulerPhase.idle) return;
    binding.handleBeginFrame(_clock.elapsed);
    binding.handleDrawFrame();
  }

  void _onFrame(Duration _) {
    if (!mounted) {
      _looping = false;
      return;
    }
    // Re-arm for the next frame. Post-frame callbacks are one-shot and only fire
    // when a frame is actually produced, so this idles to zero cost on a static
    // screen and resumes the instant the subtree animates again.
    WidgetsBinding.instance.addPostFrameCallback(_onFrame);
    _maybeCapture();
  }

  void _maybeCapture() {
    // An external producer owns the panel: skip captures entirely while it does.
    if (widget.controller.suspendCapture) {
      _wasSuspended = true;
      _trailingTimer?.cancel();
      _trailingTimer = null;
      return;
    }
    if (_wasSuspended) {
      _wasSuspended = false;
      _lastHash = 0;
    }
    final nowMs = _clock.elapsedMilliseconds;
    final sinceLast = nowMs - _lastCaptureMs;
    if (sinceLast >= _minIntervalMs) {
      _trailingTimer?.cancel();
      _trailingTimer = null;
      _lastCaptureMs = nowMs;
      _captureFrame();
    } else {
      // Too soon for another send; defer one trailing capture to the end of the
      // budget window so a just-settled animation's last frame still lands.
      _trailingTimer ??= Timer(
        Duration(milliseconds: _minIntervalMs - sinceLast),
        () {
          _trailingTimer = null;
          if (!mounted) return;
          _lastCaptureMs = _clock.elapsedMilliseconds;
          _captureFrame();
        },
      );
    }
  }

  Future<void> _captureFrame() async {
    if (_capturing || !mounted) return;
    final boundary =
        _boundaryKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
    if (boundary == null || !boundary.attached) return;
    // `debugNeedsPaint` is a debug-only getter: in release builds asserts are
    // stripped and it throws LateInitializationError, so only read it under an
    // assert. toImage() itself only asserts on a dirty boundary in debug anyway.
    var needsPaint = false;
    assert(() {
      needsPaint = boundary.debugNeedsPaint;
      return true;
    }());
    if (needsPaint) return;
    _capturing = true;
    try {
      // pixelRatio 1.0: the child is already sized to LCD logical pixels, so the
      // image is exactly width x height device pixels.
      final image = await boundary.toImage();
      final byteData = await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );
      image.dispose();
      if (byteData == null) return;
      final rgba = byteData.buffer.asUint8List();

      final hash = _fastHash(rgba);
      if (hash == _lastHash) return; // unchanged → skip the USB write

      final cfg = widget.controller.config;
      if (widget.controller.flushRgba(rgba, cfg.width, cfg.height)) {
        _lastHash = hash;
      }
    } catch (_) {
      // toImage can transiently fail mid-frame; just try again next tick.
    } finally {
      _capturing = false;
    }
  }

  /// Cheap FNV-1a over the frame; only used to detect change, not for security.
  int _fastHash(Uint8List bytes) {
    var h = 0x811c9dc5;
    // Sampling every 7th byte keeps this O(n/7) while still catching changes.
    for (var i = 0; i < bytes.length; i += 7) {
      h = (h ^ bytes[i]) & 0xffffffff;
      h = (h * 0x01000193) & 0xffffffff;
    }
    return h ^ bytes.length;
  }

  void _onTouch(PicoTouchEvent e) {
    final boundary =
        _boundaryKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
    if (boundary == null || !boundary.attached) return;

    // Panel pixels == child local logical pixels (1:1 sizing). For 'up' the
    // native side reports (0,0); reuse the last position.
    final global = e.phase == TouchPhase.up
        ? _lastGlobal
        : boundary.localToGlobal(Offset(e.x.toDouble(), e.y.toDouble()));
    // Drag recognizers (e.g. Slider) accumulate event.delta rather than diffing
    // absolute positions, so a move with the default zero delta registers no
    // motion. Carry the per-event delta from the previous position; reset it to
    // zero on 'down' so a delta never leaks across gestures.
    final delta = e.phase == TouchPhase.down
        ? Offset.zero
        : global - _lastGlobal;
    _lastGlobal = global;

    final binding = GestureBinding.instance;
    // Monotonic timestamp so the gesture arena's velocity tracker sees distinct
    // event times; without it every synthetic event shares Duration.zero and
    // velocity-based recognizers (drags, flings) misbehave.
    final ts = _clock.elapsed;
    switch (e.phase) {
      case TouchPhase.down:
        _down = true;
        binding.handlePointerEvent(
          PointerDownEvent(
            pointer: _pointerId,
            kind: PointerDeviceKind.touch,
            position: global,
            timeStamp: ts,
          ),
        );
        break;
      case TouchPhase.move:
        if (!_down) {
          // A move with no preceding down (e.g. first report) — synthesize down.
          _down = true;
          binding.handlePointerEvent(
            PointerDownEvent(
              pointer: _pointerId,
              kind: PointerDeviceKind.touch,
              position: global,
              timeStamp: ts,
            ),
          );
          return;
        }
        binding.handlePointerEvent(
          PointerMoveEvent(
            pointer: _pointerId,
            kind: PointerDeviceKind.touch,
            position: global,
            delta: delta,
            timeStamp: ts,
          ),
        );
        break;
      case TouchPhase.up:
        if (!_down) return;
        _down = false;
        binding.handlePointerEvent(
          PointerUpEvent(
            pointer: _pointerId,
            kind: PointerDeviceKind.touch,
            position: global,
            timeStamp: ts,
          ),
        );
        break;
    }
  }

  @override
  void dispose() {
    _looping = false;
    _trailingTimer?.cancel();
    _pumpTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _touchSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cfg = widget.controller.config;
    // Lock the subtree to LCD logical resolution so capture + touch map 1:1.
    return SizedBox(
      width: cfg.width.toDouble(),
      height: cfg.height.toDouble(),
      child: RepaintBoundary(key: _boundaryKey, child: widget.child),
    );
  }
}
