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

  PicoViewConfig _config = const PicoViewConfig();

  Stream<PicoTouchEvent> get touches => _touch.stream;

  Stream<PicoLinkState> get linkStates => _link.stream;

  PicoLinkState get linkState => PicoLinkState.disconnected;

  Stream<PicoOtaEvent> get otaEvents => _ota.stream;

  PicoViewConfig get config => _config;

  bool get isOpen => false;

  void init() {}

  void open(PicoViewConfig config) {
    _config = config;
  }

  bool flushRgba(Uint8List rgba, int width, int height) => false;

  bool setBrightness(int level) => false;

  void otaStart(Uint8List image) {
    throw PicoViewException('firmware update is not supported on web');
  }

  void enterRecovery() {
    throw PicoViewException('recovery mode is not supported on web');
  }

  void openSystem() {}

  SystemSnapshot? sampleSystem() => null;

  void closeSystem() {}

  void dispose() {
    _touch.close();
    _link.close();
    _ota.close();
  }
}
