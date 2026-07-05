import 'dart:typed_data';

import 'package:pico_view/pico_view.dart';

/// App-wide handle to the single [PicoViewController].
///
/// The native pico_view engine keeps one device + SendPort, so the whole app
/// shares one controller. The `Dashboard` still drives the open/dispose
/// lifecycle and owns the connection UX (error snackbars, re-applying brightness
/// on connect); this service just makes the controller and its device
/// operations reachable from anywhere — settings, feature cubits — via
/// `context.read<PicoViewService>()`.
class PicoViewService {
  PicoViewService([PicoViewController? controller])
    : controller = controller ?? PicoViewController();

  /// The shared controller. Pass it to the [PicoView] widget; issue device
  /// operations through the methods below.
  final PicoViewController controller;

  /// Link-state transitions (connected / disconnected / unauthorized).
  Stream<PicoLinkState> get linkStates => controller.linkStates;

  /// Host media-session snapshots (`null` = no session). Independent of any
  /// open device; call [startMedia] to begin observing.
  Stream<PicoMediaSnapshot?> get mediaEvents => controller.mediaEvents;

  /// Firmware-update progress/result events (see [otaStart]).
  Stream<PicoOtaEvent> get otaEvents => controller.otaEvents;

  /// Whether a device is currently open.
  bool get isOpen => controller.isOpen;

  /// The connected device's firmware version (e.g. `"1.4.0"`), or `null` when
  /// disconnected or when the device doesn't report one. Refreshed on each
  /// CONNECTED transition; watch [linkStates] to know when it may have changed.
  String? get firmwareVersion => controller.firmwareVersion;

  /// Wire up the native bridge. Safe to call more than once.
  void init() => controller.init();

  /// Open the panel device. Throws [PicoViewException] /
  /// [PicoViewUnauthorizedException] like [PicoViewController.open].
  void open([PicoViewConfig config = const PicoViewConfig()]) =>
      controller.open(config);

  /// Set the panel backlight, 0–255. Best-effort; see
  /// [PicoViewController.setBrightness].
  bool setBrightness(int level) => controller.setBrightness(level);

  /// Play one DRV2605L ROM alert effect ([effect] is a waveform id). A no-op
  /// for [effect] <= 0 (the "none" preset) or when no device is open.
  bool playHaptic(int effect) {
    if (effect <= 0) return false;
    return controller.playHaptic(effect);
  }

  /// Stop any haptic effect currently playing on the device.
  bool stopHaptic() => controller.stopHaptic();

  /// Stream a firmware image to the panel over USB. Fire-and-forget; progress
  /// and the result arrive on [otaEvents]. Throws [PicoViewException] if the
  /// update couldn't be enqueued (no device open). See
  /// [PicoViewController.otaStart].
  void otaStart(Uint8List image) => controller.otaStart(image);

  /// Start observing the host media session; snapshots arrive on [mediaEvents].
  /// Idempotent.
  void startMedia() => controller.startMedia();

  /// Stop observing the host media session. Idempotent.
  void stopMedia() => controller.stopMedia();

  /// Send a transport command to the active media session. Best-effort; a no-op
  /// when nothing is playing.
  bool mediaControl(PicoMediaCommand command) =>
      controller.mediaControl(command);

  /// Tear down the native bridge and close the device.
  void dispose() => controller.dispose();
}
