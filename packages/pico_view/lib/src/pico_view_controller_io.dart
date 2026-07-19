/// The native [PicoViewController]: owns the FFI lifecycle (init / open / flush /
/// event channel) for the native pico_view bridge.
///
/// The control plane is protobuf over one generic call: requests are encoded
/// `PvRequest` messages through `pv_request`, and engine events (touch, link
/// state, OTA progress) arrive on the `pv_init` SendPort as encoded `PvEvent`
/// bytes. Only frame delivery (`pv_lcd_flush`) bypasses the message channel.
library;

import 'dart:async';
import 'dart:ffi' as ffi;
import 'dart:isolate';

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';

import 'gen/pv_ffi.pb.dart' as pb;
import 'gen/pv_wire.pb.dart' as pbw;
import 'pico_view_bindings_generated.dart' as bindings;
import 'pico_view_types.dart';

/// Owns the native bridge. Create one, [init] it once, then [open] a device.
///
/// The native side keeps a single device + SendPort, so use a single controller
/// per app.
class PicoViewController {
  final ReceivePort _rx = ReceivePort();
  final StreamController<PicoTouchEvent> _touch =
      StreamController<PicoTouchEvent>.broadcast();
  final StreamController<PicoLinkState> _link =
      StreamController<PicoLinkState>.broadcast();
  final StreamController<PicoOtaEvent> _ota =
      StreamController<PicoOtaEvent>.broadcast();
  final StreamController<PicoMediaSnapshot?> _media =
      StreamController<PicoMediaSnapshot?>.broadcast();

  bool _initialized = false;
  bool _opened = false;
  bool _disposed = false;

  PicoLinkState _linkState = PicoLinkState.disconnected;

  /// The connected device's firmware version, reported by the engine on the
  /// CONNECTED link event; `null` while disconnected or when the device didn't
  /// report one.
  String? _firmwareVersion;

  PicoViewConfig _config = const PicoViewConfig();

  /// Reusable frame buffer (grows once, freed in [dispose]). Safe to reuse
  /// because the copy → FFI-call critical section is synchronous.
  ffi.Pointer<ffi.Uint8>? _frameBuffer;
  int _frameBufferCap = 0;

  /// When true, an external frame producer (e.g. the video module) is pushing
  /// frames straight to the panel via [flushRgba], so the [PicoView] mirror loop
  /// must pause its own captures to avoid two writers fighting over the panel.
  bool suspendCapture = false;

  /// Physical-touch events in LCD pixel coordinates.
  Stream<PicoTouchEvent> get touches => _touch.stream;

  /// Link-state transitions (connected / disconnected / unauthorized). The
  /// native engine reconnects on its own; listen here to reflect it in the UI.
  Stream<PicoLinkState> get linkStates => _link.stream;

  /// The most recent link state (kept current from [linkStates]).
  PicoLinkState get linkState => _linkState;

  String? get firmwareVersion => _firmwareVersion;

  /// Firmware-update progress/result events (see [otaStart]).
  Stream<PicoOtaEvent> get otaEvents => _ota.stream;

  /// Host media-session snapshots (`null` = no session). Independent of any
  /// open device — start it with [startMedia].
  Stream<PicoMediaSnapshot?> get mediaEvents => _media.stream;

  /// The currently-open device config (geometry used by `PicoView`).
  PicoViewConfig get config => _config;

  /// Whether [open] succeeded. For the *live* device state, use [linkState]:
  /// the engine keeps reconnecting behind this flag.
  bool get isOpen => _opened;

  /// Wire up the Dart DL API + SendPort. Call once before [open]. Throws
  /// [PicoViewException] when the Dart DL API handshake fails (a native
  /// library / SDK version mismatch) — no events would ever be delivered.
  void init() {
    if (_initialized) return;
    final rc = bindings.pv_init(
      ffi.NativeApi.initializeApiDLData,
      _rx.sendPort.nativePort,
    );
    if (rc != 0) {
      throw PicoViewException(
        'pv_init failed: Dart DL API version mismatch (code $rc)',
        code: rc,
      );
    }
    _rx.listen(_onMessage);
    _initialized = true;
  }

  /// Send one encoded control-plane request and decode the response. Throws
  /// [PicoViewException] only when the native side produced no response at all
  /// (per-request failures come back as an `error` response, handled by the
  /// callers).
  pb.PvResponse _request(pb.PvRequest req) {
    final reqBytes = req.writeToBuffer();
    final reqPtr = malloc.allocate<ffi.Uint8>(reqBytes.length);
    final respPtr = malloc.allocate<ffi.Pointer<ffi.Uint8>>(
      ffi.sizeOf<ffi.Pointer<ffi.Uint8>>(),
    );
    final respLen = malloc.allocate<ffi.UintPtr>(ffi.sizeOf<ffi.UintPtr>());
    try {
      reqPtr.asTypedList(reqBytes.length).setAll(0, reqBytes);
      final rc = bindings.pv_request(reqPtr, reqBytes.length, respPtr, respLen);
      if (rc != 0) {
        throw PicoViewException('pv_request failed (code $rc)', code: rc);
      }
      final ptr = respPtr.value;
      final len = respLen.value;
      try {
        // Parsing copies out of the native buffer, so it can be freed after.
        return pb.PvResponse.fromBuffer(ptr.asTypedList(len));
      } finally {
        bindings.pv_free(ptr, len);
      }
    } finally {
      malloc.free(reqPtr);
      malloc.free(respPtr);
      malloc.free(respLen);
    }
  }

  /// Throw the matching exception for an `error` response.
  Never _throwError(pb.Error error, String op) {
    if (error.code == pb.ErrorCode.ERROR_CODE_UNAUTHORIZED) {
      throw PicoViewUnauthorizedException();
    }
    throw PicoViewException(
      '$op failed: ${error.message} (${error.code.name})',
      code: error.code.value,
    );
  }

  void open(PicoViewConfig config) {
    if (!_initialized) init();
    final req = pb.PvRequest(openDevice: pb.OpenDevice(model: config.model));
    var resp = _request(req);
    if (resp.whichResp() == pb.PvResponse_Resp.error &&
        resp.error.code == pb.ErrorCode.ERROR_CODE_ALREADY_OPEN &&
        !_opened) {
      // The native worker survived a hot restart (this controller never
      // opened it). Tear the stale one down and retry once.
      _request(pb.PvRequest(closeDevice: pb.CloseDevice()));
      resp = _request(req);
    }
    if (resp.whichResp() == pb.PvResponse_Resp.error) {
      _throwError(resp.error, 'open');
    }
    _config = config;
    _opened = true;
    _linkState = PicoLinkState.connected;
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

  /// Set the panel backlight level, 0 (off) – 255 (full). Best-effort: returns
  /// false (without throwing) when no device is open or the engine rejects the
  /// request, so callers can apply it opportunistically on connect / config
  /// change. The value is clamped into range.
  bool setBrightness(int level) {
    if (_disposed || !_opened) return false;
    final clamped = level.clamp(0, 255);
    final resp = _request(
      pb.PvRequest(setParam: pbw.SetParam(brightness: clamped)),
    );
    return resp.whichResp() != pb.PvResponse_Resp.error;
  }

  /// Play one built-in DRV2605L haptic effect ([effect] is a ROM waveform id,
  /// 1–123). [library] picks the ROM library (1–7); 0 keeps the firmware
  /// default (the LRA library). Best-effort and fire-and-forget: returns false
  /// (without throwing) when no device is open or the engine rejects it, and the
  /// device sends no acknowledgement. A no-op on devices without haptics.
  bool playHaptic(int effect, {int library = 0}) {
    if (_disposed || !_opened) return false;
    final resp = _request(
      pb.PvRequest(
        haptics: pbw.Haptics(
          play: pbw.HapticsPlay(effect: effect, library: library),
        ),
      ),
    );
    return resp.whichResp() != pb.PvResponse_Resp.error;
  }

  /// Stop any haptic effect currently playing on the device. Best-effort; see
  /// [playHaptic].
  bool stopHaptic() {
    if (_disposed || !_opened) return false;
    final resp = _request(
      pb.PvRequest(haptics: pbw.Haptics(stop: pbw.HapticsStop())),
    );
    return resp.whichResp() != pb.PvResponse_Resp.error;
  }

  bool _sysOpen = false;

  /// Start the host system sampler (CPU / RAM / network / temperatures).
  /// Optional: [sampleSystem] opens it on first use.
  void openSystem() {
    _sysOpen = true;
  }

  /// Sample host telemetry once. Opens the sampler on first use.
  SystemSnapshot? sampleSystem() {
    if (_disposed) return null;
    _sysOpen = true;
    final resp = _request(pb.PvRequest(sysSample: pb.SysSample()));
    if (resp.whichResp() != pb.PvResponse_Resp.system) return null;
    return _toSystemSnapshot(resp.system);
  }

  /// Stop the host sampler and free its native state. Idempotent.
  void closeSystem() {
    if (_sysOpen && !_disposed) {
      _request(pb.PvRequest(sysClose: pb.SysClose()));
      _sysOpen = false;
    }
  }

  bool _mediaOpen = false;

  /// Start observing the host media session; snapshots arrive on [mediaEvents].
  /// Independent of any open device. Idempotent.
  void startMedia() {
    if (_disposed || _mediaOpen) return;
    _request(pb.PvRequest(mediaStart: pb.MediaStart()));
    _mediaOpen = true;
  }

  /// Stop observing the media session and release the monitor thread.
  /// Idempotent.
  void stopMedia() {
    if (_mediaOpen && !_disposed) {
      _request(pb.PvRequest(mediaStop: pb.MediaStop()));
      _mediaOpen = false;
    }
  }

  /// Send a transport command to the active media session. Best-effort and
  /// fire-and-forget: returns false (without throwing) when the engine rejects
  /// it; a control with no active session is a harmless no-op.
  bool mediaControl(PicoMediaCommand command) {
    if (_disposed) return false;
    final cmd = switch (command) {
      PicoMediaCommand.playPause => pb.MediaCommand.MEDIA_COMMAND_PLAY_PAUSE,
      PicoMediaCommand.next => pb.MediaCommand.MEDIA_COMMAND_NEXT,
      PicoMediaCommand.previous => pb.MediaCommand.MEDIA_COMMAND_PREVIOUS,
    };
    final resp = _request(
      pb.PvRequest(mediaControl: pb.MediaControl(command: cmd)),
    );
    return resp.whichResp() != pb.PvResponse_Resp.error;
  }

  /// Stream a signed firmware image to the device. Fire-and-forget: progress
  /// and the result arrive on [otaEvents]; while it runs, frames are dropped
  /// and the device reboots into the new image on success (a
  /// disconnected→connected pair appears on [linkStates]).
  ///
  /// Throws [PicoViewException] if the update couldn't be enqueued (no device
  /// open, or the worker is gone).
  void otaStart(Uint8List image) {
    if (_disposed || !_opened) {
      throw PicoViewException('otaStart: device not open', code: -1);
    }
    final resp = _request(pb.PvRequest(otaStart: pb.OtaStart(image: image)));
    if (resp.whichResp() == pb.PvResponse_Resp.error) {
      _throwError(resp.error, 'otaStart');
    }
  }

  /// Ask the device to reboot into its factory recovery image. Throws
  /// [PicoViewException] if the request couldn't be enqueued.
  void enterRecovery() {
    if (_disposed || !_opened) {
      throw PicoViewException('enterRecovery: device not open', code: -1);
    }
    final resp = _request(pb.PvRequest(enterRecovery: pbw.EnterRecovery()));
    if (resp.whichResp() == pb.PvResponse_Resp.error) {
      _throwError(resp.error, 'enterRecovery');
    }
  }

  /// Decode one `PvEvent` pushed from the native side and route it to the
  /// matching stream. Unknown variants are ignored so newer native libraries
  /// stay compatible with older Dart code.
  void _onMessage(dynamic raw) {
    if (raw is! Uint8List) return;
    final pb.PvEvent event;
    try {
      event = pb.PvEvent.fromBuffer(raw);
    } catch (_) {
      return;
    }
    switch (event.whichEvent()) {
      case pb.PvEvent_Event.touch:
        _onTouch(event.touch);
      case pb.PvEvent_Event.link:
        final state = switch (event.link.state) {
          pb.LinkState.LINK_STATE_CONNECTED => PicoLinkState.connected,
          pb.LinkState.LINK_STATE_DISCONNECTED => PicoLinkState.disconnected,
          pb.LinkState.LINK_STATE_UNAUTHORIZED => PicoLinkState.unauthorized,
          _ => null,
        };
        if (state != null) {
          _linkState = state;
          // fw_version is only meaningful on CONNECTED; clear it otherwise so a
          // stale version can't linger after unplug.
          _firmwareVersion = state == PicoLinkState.connected
              ? (event.link.fwVersion.isEmpty ? null : event.link.fwVersion)
              : null;
          _link.add(state);
        }
      case pb.PvEvent_Event.ota:
        _ota.add(
          PicoOtaEvent(
            switch (event.ota.state) {
              pbw.OtaState.OTA_STATE_RECEIVING => 'receiving',
              pbw.OtaState.OTA_STATE_VERIFYING => 'verifying',
              pbw.OtaState.OTA_STATE_DONE => 'done',
              pbw.OtaState.OTA_STATE_FAILED => 'failed',
              _ => 'unknown',
            },
            event.ota.pct,
            event.ota.err,
          ),
        );
      case pb.PvEvent_Event.media:
        _media.add(_toMediaSnapshot(event.media));
      default:
        break;
    }
  }

  /// Map a pushed `MediaSnapshot`, treating an empty `playerName` (the engine's
  /// idle signal) as `null`.
  PicoMediaSnapshot? _toMediaSnapshot(pb.MediaSnapshot m) {
    if (m.playerName.isEmpty) return null;
    return PicoMediaSnapshot(
      playerName: m.playerName,
      title: m.title,
      artist: m.artist,
      album: m.album,
      artUri: m.artUri,
      artBytes: m.artBytes.isEmpty ? null : Uint8List.fromList(m.artBytes),
      artMime: m.artMime,
      position: Duration(microseconds: m.positionUs.toInt()),
      duration: Duration(microseconds: m.durationUs.toInt()),
      playing: m.playing,
      canNext: m.canNext,
      canPrevious: m.canPrevious,
    );
  }

  void _onTouch(pbw.Touch touch) {
    final phase = switch (touch.phase) {
      pbw.TouchPhase.TOUCH_PHASE_DOWN => TouchPhase.down,
      pbw.TouchPhase.TOUCH_PHASE_MOVE => TouchPhase.move,
      pbw.TouchPhase.TOUCH_PHASE_UP => TouchPhase.up,
      _ => null,
    };
    if (phase == null) return;
    _touch.add(PicoTouchEvent(phase, touch.x, touch.y));
  }

  SystemSnapshot _toSystemSnapshot(pb.SystemSnapshot s) {
    return SystemSnapshot(
      cpuUsage: s.cpu.usage,
      cpuCores: List<double>.from(s.cpu.cores),
      cpuFreqMhz: s.cpu.freqMhz.toInt(),
      memTotal: s.mem.total.toInt(),
      memUsed: s.mem.used.toInt(),
      swapTotal: s.mem.swapTotal.toInt(),
      swapUsed: s.mem.swapUsed.toInt(),
      netRxBps: s.net.rxBps.toInt(),
      netTxBps: s.net.txBps.toInt(),
      netRxTotal: s.net.rxTotal.toInt(),
      netTxTotal: s.net.txTotal.toInt(),
      temperatures: s.temps
          .map((t) => SystemTemperature(t.label, t.celsius))
          .toList(),
      loadAverage: [s.load.one, s.load.five, s.load.fifteen],
    );
  }

  /// Close the device and release all resources. Safe to call multiple times.
  ///
  /// Only tears down the native state *this* controller owns: the app runs one
  /// device controller plus a sampling-only controller (the native engine is a
  /// global singleton), so an unconditional `pv_close` here would kill the
  /// other controller's device worker.
  void dispose() {
    if (_disposed) return;
    closeSystem();
    stopMedia();
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
    _link.close();
    _ota.close();
    _media.close();
    _rx.close();
  }
}
