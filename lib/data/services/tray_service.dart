/// `tray_manager`/`window_manager` are desktop-only (and pull in `dart:io`), so
/// on web this resolves to a no-op stub.
library;

export 'tray_service_stub.dart' if (dart.library.io) 'tray_service_io.dart';
