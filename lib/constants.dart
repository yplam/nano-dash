/// Build flavor, chosen at the entry point.
///
/// The flatpak release excludes the system tray: its native appindicator stack
/// pulls in the GPL-3.0 `libayatana-indicator`. Without a tray there's nowhere
/// to restore a hidden window from, so closing the window must quit rather than hide.
enum AppFlavor {
  /// Full desktop build: system tray, close-to-tray.
  desktop,

  /// Flatpak build: no system tray, close quits.
  flatpak,

  /// Web build: no OS window and no tray; runs in a browser tab.
  web;

  bool get hasTray => this == AppFlavor.desktop;
}
