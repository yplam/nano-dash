/// The web [PicoViewController]: a no-op stub.
library;

import 'dart:async';
import 'dart:typed_data';

import 'pico_view_types.dart';

class PicoViewController {
  final StreamController<PicoTouchEvent> _touch =
      StreamController<PicoTouchEvent>.broadcast();
  final StreamController<PicoLinkState> _link =
      StreamController<PicoLinkState>.broadcast();
  final StreamController<PicoOtaEvent> _ota =
      StreamController<PicoOtaEvent>.broadcast();
  final StreamController<PicoMediaSnapshot?> _media =
      StreamController<PicoMediaSnapshot?>.broadcast();

  PicoViewConfig _config = const PicoViewConfig();

  Stream<PicoTouchEvent> get touches => _touch.stream;

  Stream<PicoLinkState> get linkStates => _link.stream;

  PicoLinkState get linkState => PicoLinkState.disconnected;

  /// No device on web, so no firmware version.
  String? get firmwareVersion => null;

  Stream<PicoOtaEvent> get otaEvents => _ota.stream;

  Stream<PicoMediaSnapshot?> get mediaEvents => _media.stream;

  PicoViewConfig get config => _config;

  bool get isOpen => false;

  void init() {}

  void open(PicoViewConfig config) {
    _config = config;
  }

  bool flushRgba(Uint8List rgba, int width, int height) => false;

  bool setBrightness(int level) => false;

  bool playHaptic(int effect, {int library = 0}) => false;

  bool stopHaptic() => false;

  void otaStart(Uint8List image) {
    throw PicoViewException('firmware update is not supported on web');
  }

  void enterRecovery() {
    throw PicoViewException('recovery mode is not supported on web');
  }

  void openSystem() {}

  SystemSnapshot? sampleSystem() => null;

  void closeSystem() {}

  void startMedia() {}

  void stopMedia() {}

  bool mediaControl(PicoMediaCommand command) => false;

  void dispose() {
    _touch.close();
    _link.close();
    _ota.close();
    _media.close();
  }
}
