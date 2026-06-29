import 'dart:async';
import 'dart:io';

import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import '../../extensions/loggable.dart';
import '../../l10n/app_localizations.dart';

/// Menu item keys.
const _kShow = 'show';
const _kHide = 'hide';
const _kQuit = 'quit';

/// The app is meant to live in the background: closing the window does not quit
/// it, it hides the window and drops it from the taskbar. The tray icon is the
/// re-entry point to bring it back. Only [quit] (or the OS killing the process)
/// actually terminates the app.
class TrayService with TrayListener, WindowListener, Loggable {
  TrayService();

  @override
  String get logIdentifier => '[TrayService]';

  // Asset path, resolved by tray_manager relative to `data/flutter_assets`.
  //   - Windows: multi-size .ico.
  //   - macOS: monochrome "template" icon that the OS auto-tints to match the
  //     light/dark menu bar.
  //   - Linux/other: the full-color .png.
  static String get _iconNormal {
    if (Platform.isWindows) return 'assets/tray/tray.ico';
    if (Platform.isMacOS) return 'assets/tray/trayTemplate.png';
    return 'assets/tray/tray.png';
  }

  AppLocalizations? _l10n;
  bool _initialized = false;

  /// Set up the tray icon, menu and window listeners.
  Future<void> init(AppLocalizations l10n) async {
    if (_initialized) return;
    _l10n = l10n;

    trayManager.addListener(this);
    try {
      await trayManager.setIcon(_iconNormal, isTemplate: Platform.isMacOS);
      // setToolTip is a no-op on Linux but harmless there.
      if (!Platform.isLinux) {
        await trayManager.setToolTip(l10n.trayTooltip);
      }
      await _setMenu();
    } catch (e, s) {
      trayManager.removeListener(this);
      logWarning(
        'tray setup failed; running without a tray icon',
        error: e,
        stackTrace: s,
      );
      return;
    }

    // Tray is live, so it's safe to make the window close button hide to the
    // background instead of quitting; we handle the request in [onWindowClose].
    await windowManager.setPreventClose(true);
    windowManager.addListener(this);
    _initialized = true;
  }

  Future<void> _setMenu() async {
    final l10n = _l10n!;
    await trayManager.setContextMenu(
      Menu(
        items: [
          MenuItem(key: _kShow, label: l10n.trayShow),
          MenuItem(key: _kHide, label: l10n.trayHide),
          MenuItem.separator(),
          MenuItem(key: _kQuit, label: l10n.trayQuit),
        ],
      ),
    );
  }

  /// Bring the window back to the foreground and the taskbar.
  Future<void> show() async {
    await windowManager.setSkipTaskbar(false);
    await windowManager.show();
    await windowManager.focus();
  }

  /// Hide the window into the background (no window, no taskbar entry).
  Future<void> hide() async {
    await windowManager.hide();
    await windowManager.setSkipTaskbar(true);
  }

  /// Actually terminate the app (the only path that does).
  Future<void> quit() async {
    await windowManager.setPreventClose(false);
    await trayManager.destroy();
    await windowManager.destroy();
  }

  // --- WindowListener -------------------------------------------------------

  @override
  void onWindowClose() {
    // User pressed the window close button: hide to background instead of
    // quitting.
    unawaited(hide());
  }

  // --- TrayListener ---------------------------------------------------------

  @override
  void onTrayIconMouseDown() {
    // Left-click on Windows/macOS toggles the window. On Linux the left-click
    // opens the menu natively, so this isn't delivered there.
    unawaited(show());
  }

  @override
  void onTrayIconRightMouseDown() {
    unawaited(trayManager.popUpContextMenu());
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    switch (menuItem.key) {
      case _kShow:
        unawaited(show());
        break;
      case _kHide:
        unawaited(hide());
        break;
      case _kQuit:
        unawaited(quit());
        break;
    }
  }

  void dispose() {
    trayManager.removeListener(this);
    windowManager.removeListener(this);
  }
}
