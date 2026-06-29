/// The [PicoViewController] has two backends selected at compile time: a native FFI
/// implementation (default, when `dart:io` is available) and a no-op web stub.
library;

export 'pico_view_controller_web.dart'
    if (dart.library.io) 'pico_view_controller_io.dart';
export 'pico_view_types.dart';
