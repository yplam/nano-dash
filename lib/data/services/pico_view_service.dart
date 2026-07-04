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

  /// Whether a device is currently open.
  bool get isOpen => controller.isOpen;

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

  /// Tear down the native bridge and close the device.
  void dispose() => controller.dispose();
}
