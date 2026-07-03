/// The web [PicoViewController]: a no-op stub.
library;

import 'dart:async';
import 'dart:typed_data';

import 'pico_view_types.dart';

class PicoViewController {
  final StreamController<PicoTouchEvent> _touch =
      StreamController<PicoTouchEvent>.broadcast();

  PicoViewConfig _config = const PicoViewConfig();

  Stream<PicoTouchEvent> get touches => _touch.stream;

  PicoViewConfig get config => _config;

  bool get isOpen => false;

  void init() {}

  void open(PicoViewConfig config) {
    _config = config;
  }

  bool flushRgba(Uint8List rgba, int width, int height) => false;

  void openSystem() {}

  SystemSnapshot? sampleSystem() => null;

  void closeSystem() {}

  void dispose() {
    _touch.close();
  }
}
