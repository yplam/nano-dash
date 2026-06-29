/// Desktop [WindowService] backed by `window_manager`.
library;

import 'package:flutter/widgets.dart';
import 'package:window_manager/window_manager.dart';

/// Desktop window operations used by the app shell. Mirrors the small subset of
/// `window_manager` the app needs; the web stub no-ops every method.
class WindowService {
  const WindowService._();

  /// Bind the `window_manager` plugin. Call once before any other method.
  static Future<void> ensureInitialized() => windowManager.ensureInitialized();

  /// Configure the initial window, then show and focus it.
  static Future<void> setupAndShow({
    required Size size,
    required Size minimumSize,
    required String title,
  }) {
    return windowManager.waitUntilReadyToShow(
      WindowOptions(
        size: size,
        minimumSize: minimumSize,
        center: true,
        title: title,
      ),
      () async {
        // Fixed dashboard: the app drives its own size (compact vs. expanded),
        // so a maximize button only fights that. Resizing by edge-drag stays on.
        await windowManager.setMaximizable(false);
        await windowManager.show();
        await windowManager.focus();
      },
    );
  }

  /// Current outer window size.
  static Future<Size> getSize() => windowManager.getSize();

  /// Resize the outer window.
  static Future<void> setSize(Size size) => windowManager.setSize(size);
}
