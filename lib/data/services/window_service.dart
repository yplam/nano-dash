/// Thin wrapper over `window_manager`.
///
/// `window_manager` only supports desktop (it pulls in `dart:io` and has no web
/// implementation), so on web this resolves to a no-op stub.
library;

export 'window_service_stub.dart' if (dart.library.io) 'window_service_io.dart';
