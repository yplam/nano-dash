/// A single tray context-menu entry.
class MenuItem {
  MenuItem({this.key, this.label});

  MenuItem.separator() : key = null, label = null;

  final String? key;
  final String? label;
}

/// A tray context menu.
class Menu {
  Menu({this.items = const []});

  final List<MenuItem> items;
}

/// Tray event callbacks. All default to no-ops; the app overrides a few.
mixin TrayListener {
  void onTrayIconMouseDown() {}

  void onTrayIconMouseUp() {}

  void onTrayIconRightMouseDown() {}

  void onTrayIconRightMouseUp() {}

  void onTrayMenuItemClick(MenuItem menuItem) {}
}

/// Drop-in no-op for the real `TrayManager` singleton.
class TrayManager {
  void addListener(TrayListener listener) {}

  void removeListener(TrayListener listener) {}

  Future<void> setIcon(String iconPath, {bool isTemplate = false}) async {}

  Future<void> setToolTip(String toolTip) async {}

  Future<void> setContextMenu(Menu menu) async {}

  Future<void> popUpContextMenu() async {}

  Future<void> destroy() async {}
}

/// Global instance, matching the real package's API.
final TrayManager trayManager = TrayManager();
