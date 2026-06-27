import 'package:flutter/material.dart';

import '../../domain/models/dashboard.dart';
import '../../domain/models/module.dart';
import '../../l10n/app_localizations.dart';
import '../timer/models/timer_config.dart';
import '../timer/views/timer_settings_view.dart';
import '../timer/views/timer_view.dart';

/// A set of named countdown timers, each with its own duration and
/// sound/vibrate preferences. Defaults to a plain countdown plus a Pomodoro.
class TimerModule extends Module {
  const TimerModule();

  static const String kId = 'timer';

  static const String _kTimers = 'timers';

  /// The presets seeded when the module is first added: one plain countdown and
  /// one Pomodoro timer (which manages its own short/long breaks). Names are
  /// left empty and carried as semantic [TimerConfig.labelKey]s so they render
  /// in the active locale.
  static const List<TimerConfig> _defaultTimers = [
    TimerConfig(
      id: 'timer-countdown',
      name: '',
      labelKey: 'countdown',
      duration: Duration(minutes: 5),
    ),
    TimerConfig(
      id: 'timer-pomodoro',
      name: '',
      labelKey: 'pomodoro',
      duration: Duration(minutes: 25),
      pomodoro: true,
    ),
  ];

  @override
  String get id => kId;

  @override
  IconData get icon => Icons.hourglass_empty;

  @override
  String title(AppLocalizations l10n) => l10n.moduleTimerTitle;

  @override
  bool get hasSettings => true;

  @override
  ModuleSettings get defaultSettings => {
    _kTimers: _defaultTimers.map((t) => t.toJson()).toList(),
  };

  /// Read the configured timers, falling back to the Pomodoro presets when the
  /// stored settings predate this key or are malformed.
  static List<TimerConfig> _timersOf(ModuleSettings settings) {
    final raw = settings[_kTimers];
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((m) => TimerConfig.fromJson(Map<String, Object?>.from(m)))
          .toList();
    }
    return _defaultTimers;
  }

  static ModuleSettings _settingsOf(List<TimerConfig> timers) => {
    _kTimers: timers.map((t) => t.toJson()).toList(),
  };

  @override
  Widget build(BuildContext context, ModuleSettings settings) =>
      TimerView(timers: _timersOf(settings));

  @override
  Widget buildSettings(
    BuildContext context,
    ModuleSettings settings,
    ValueChanged<ModuleSettings> onChanged,
  ) {
    return TimerSettingsView(
      timers: _timersOf(settings),
      onChanged: (timers) => onChanged(_settingsOf(timers)),
    );
  }
}
