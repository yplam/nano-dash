/// pico_view: render a Flutter widget subtree to an external SPI LCD over a
/// CH347 USB bridge, with physical capacitive touch fed back into that subtree.
///
/// [PicoViewController] owns the FFI lifecycle (init / open / flush / touch
/// channel). Wrap your UI in the [PicoView] widget to capture+stream frames and
/// inject touches automatically.
library;

export 'src/pico_view_controller.dart';
export 'src/pico_view_widget.dart';
