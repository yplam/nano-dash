import 'package:flutter/material.dart';

import '../../domain/models/dashboard.dart';
import '../../domain/models/module.dart';
import '../../l10n/app_localizations.dart';
import '../timer/views/timer_settings_view.dart';
import '../timer/views/timer_view.dart';

/// A countdown timer with a draining ring, start/pause + reset controls, and a
/// configurable duration.
class TimerModule extends Module {
  const TimerModule();

  static const String kId = 'timer';

  static const String _kDurationSec = 'durationSec';
  static const int _kDefaultSec = 300; // 5 minutes

  @override
  String get id => kId;

  @override
  IconData get icon => Icons.hourglass_empty;

  @override
  String title(AppLocalizations l10n) => l10n.moduleTimerTitle;

  @override
  bool get hasSettings => true;

  @override
  ModuleSettings get defaultSettings => const {_kDurationSec: _kDefaultSec};

  static Duration _durationOf(ModuleSettings settings) =>
      Duration(seconds: settings[_kDurationSec] as int? ?? _kDefaultSec);

  @override
  Widget build(BuildContext context, ModuleSettings settings) =>
      TimerView(configured: _durationOf(settings));

  @override
  Widget buildSettings(
    BuildContext context,
    ModuleSettings settings,
    ValueChanged<ModuleSettings> onChanged,
  ) {
    return TimerSettingsView(
      duration: _durationOf(settings),
      onChanged: (d) => onChanged({...settings, _kDurationSec: d.inSeconds}),
    );
  }
}
