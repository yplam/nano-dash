import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'dashboard.dart';

/// A pluggable dashboard widget.
///
/// One [Module] subclass = one available widget on the home page.
abstract class Module {
  const Module();

  /// Stable identifier used as the persistence key. Must be unique.
  String get id;

  /// Icon shown in the configuration list.
  IconData get icon;

  /// Localized display title.
  String title(AppLocalizations l10n);

  /// Default settings applied when the module is first added.
  ModuleSettings get defaultSettings => const {};

  /// Whether this module exposes a settings bottom sheet.
  bool get hasSettings => false;

  /// Whether this module renders a page on the LCD carousel.
  bool get hasDisplay => true;

  /// The page rendered onto the LCD (and the on-screen preview). Laid out at the
  /// panel's native size. [settings] is the module's current, persisted settings map.
  /// Only called when [hasDisplay] is true.
  Widget build(BuildContext context, ModuleSettings settings) =>
      const SizedBox.shrink();

  /// Body of the settings modal bottom sheet. Call [onChanged] with a new
  /// settings map to persist edits.
  Widget buildSettings(
    BuildContext context,
    ModuleSettings settings,
    ValueChanged<ModuleSettings> onChanged,
  ) => const SizedBox.shrink();
}
