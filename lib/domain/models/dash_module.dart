import 'package:flutter/widgets.dart';

import '../../l10n/app_localizations.dart';

/// Settings for a single dashboard module. A plain JSON-friendly map so it can
/// be persisted as-is; modules own their keys.
typedef DashSettings = Map<String, Object?>;

/// A pluggable dashboard widget.
///
/// One [DashModule] subclass = one available widget on the home page. The
/// engine renders [buildLcd] onto the SPI LCD (and the on-screen preview) at the
/// panel's native logical size; [buildSettings] optionally provides a
/// modal-bottom-sheet body for per-widget configuration.
abstract class DashModule {
  const DashModule();

  /// Stable identifier used as the persistence key. Must be unique and must not
  /// change once shipped (stored configs reference it).
  String get id;

  /// Icon shown in the configuration list.
  IconData get icon;

  /// Localized display title.
  String title(AppLocalizations l10n);

  /// Default settings applied when the module is first added.
  DashSettings get defaultSettings => const {};

  /// Whether this module exposes a settings bottom sheet.
  bool get hasSettings => false;

  /// Whether this module renders a page on the LCD carousel.
  ///
  /// Display modules (the default) implement [buildLcd] and appear as a
  /// swipeable page; their position in the config list encodes page order.
  ///
  /// Config-only modules return `false`: they are a capability toggle (e.g.
  /// the voice engine) with enable/disable and settings but no display. They
  /// take no page on the LCD and are not part of the page order, so they are
  /// shown in the config list without a drag handle and never [buildLcd].
  bool get hasDisplay => true;

  /// The page rendered onto the LCD (and the on-screen preview). Laid out at the
  /// panel's native size (e.g. 240×280). [settings] is the module's current,
  /// persisted settings map. Only called when [hasDisplay] is true; config-only
  /// modules need not override it.
  Widget buildLcd(BuildContext context, DashSettings settings) =>
      const SizedBox.shrink();

  /// Body of the settings modal bottom sheet. Call [onChanged] with a new
  /// settings map to persist edits. Default: nothing.
  Widget buildSettings(
    BuildContext context,
    DashSettings settings,
    ValueChanged<DashSettings> onChanged,
  ) =>
      const SizedBox.shrink();
}
