import 'dart:math' as math;

import 'json_model.dart';

/// One configurable countdown preset: a named duration plus alert preferences.
class TimerConfig implements JsonModel {
  const TimerConfig({
    required this.id,
    required this.name,
    required this.duration,
    this.labelKey,
    this.sound = true,
    this.vibrate = true,
    this.pomodoro = false,
    this.shortBreak = const Duration(minutes: 5),
    this.longBreak = const Duration(minutes: 15),
  });

  /// How many focus sessions complete before a long break (instead of a short
  /// break). Fixed; no longer user-configurable.
  static const int longBreakEvery = 4;

  /// Stable identifier, unique within the list. Used as the selection key and
  /// the widget key so a row keeps its edit state across rebuilds.
  final String id;

  /// An explicit, user-chosen label. Empty for a default preset that has not
  /// been renamed — in that case the displayed name comes from [labelKey],
  /// localized at render time.
  final String name;

  /// The semantic key of a built-in default label (`countdown`, `pomodoro`,
  /// `focus`, `shortBreak`, `longBreak`). Null once the timer is user-named.
  /// Stored instead of a baked-in string so default names follow the app
  /// locale at runtime.
  final String? labelKey;

  /// The countdown length.
  final Duration duration;

  /// Play a sound when this timer finishes. (Playback is implemented later.)
  final bool sound;

  /// Vibrate when this timer finishes. (Playback is implemented later.)
  final bool vibrate;

  /// When true, this timer runs as a Pomodoro task: finishing its [duration]
  /// (the focus length) auto-starts a break, and completed focus sessions are
  /// recorded for the statistics report. A plain countdown when false.
  final bool pomodoro;

  /// Break length inserted after a focus session, when not a long break.
  final Duration shortBreak;

  /// Break length inserted after every [longBreakEvery]th focus session.
  final Duration longBreak;

  /// Like [copyWith], but always clears [labelKey] — used when the user gives
  /// the timer an explicit name, turning a default preset into a custom one.
  TimerConfig rename(String name) => TimerConfig(
    id: id,
    name: name,
    duration: duration,
    sound: sound,
    vibrate: vibrate,
    pomodoro: pomodoro,
    shortBreak: shortBreak,
    longBreak: longBreak,
  );

  TimerConfig copyWith({
    String? name,
    Duration? duration,
    bool? sound,
    bool? vibrate,
    bool? pomodoro,
    Duration? shortBreak,
    Duration? longBreak,
  }) {
    return TimerConfig(
      id: id,
      name: name ?? this.name,
      labelKey: labelKey,
      duration: duration ?? this.duration,
      sound: sound ?? this.sound,
      vibrate: vibrate ?? this.vibrate,
      pomodoro: pomodoro ?? this.pomodoro,
      shortBreak: shortBreak ?? this.shortBreak,
      longBreak: longBreak ?? this.longBreak,
    );
  }

  @override
  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    if (labelKey != null) 'labelKey': labelKey,
    'durationSec': duration.inSeconds,
    'sound': sound,
    'vibrate': vibrate,
    'pomodoro': pomodoro,
    'shortBreakSec': shortBreak.inSeconds,
    'longBreakSec': longBreak.inSeconds,
  };

  factory TimerConfig.fromJson(Map<String, Object?> json) => TimerConfig(
    id: json['id'] as String? ?? newId(),
    name: json['name'] as String? ?? '',
    labelKey: json['labelKey'] as String?,
    duration: Duration(seconds: json['durationSec'] as int? ?? 0),
    sound: json['sound'] as bool? ?? true,
    vibrate: json['vibrate'] as bool? ?? true,
    pomodoro: json['pomodoro'] as bool? ?? false,
    shortBreak: Duration(seconds: json['shortBreakSec'] as int? ?? 300),
    longBreak: Duration(seconds: json['longBreakSec'] as int? ?? 900),
  );

  /// A fresh, collision-resistant id for a newly added timer.
  static String newId() =>
      '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}'
      '${math.Random().nextInt(0x10000).toRadixString(36)}';

  @override
  bool operator ==(Object other) =>
      other is TimerConfig &&
      other.id == id &&
      other.name == name &&
      other.labelKey == labelKey &&
      other.duration == duration &&
      other.sound == sound &&
      other.vibrate == vibrate &&
      other.pomodoro == pomodoro &&
      other.shortBreak == shortBreak &&
      other.longBreak == longBreak;

  @override
  int get hashCode => Object.hash(
    id,
    name,
    labelKey,
    duration,
    sound,
    vibrate,
    pomodoro,
    shortBreak,
    longBreak,
  );
}

/// The persisted timer presets. [timers] is null until first saved (or
/// migrated), so `TimerRepository` can tell "never stored" apart from "the
/// user deleted every timer".
class TimerSettings implements JsonModel {
  const TimerSettings(this.timers);

  final List<TimerConfig>? timers;

  @override
  Map<String, Object?> toJson() => {
    'timers': [for (final t in timers ?? const <TimerConfig>[]) t.toJson()],
  };

  factory TimerSettings.fromJson(Map<String, Object?> json) {
    final raw = json['timers'];
    return TimerSettings(
      raw is List
          ? raw
                .whereType<Map>()
                .map((m) => TimerConfig.fromJson(Map<String, Object?>.from(m)))
                .toList()
          : null,
    );
  }
}

const timerSettingsKey = SettingKey<TimerSettings>(
  'timer_settings_v1',
  TimerSettings.fromJson,
  defaults: TimerSettings(null),
);

/// Which leg of a Pomodoro cycle the selected timer is currently on.
enum PomodoroPhase { focus, shortBreak, longBreak }

/// One completed Pomodoro focus session, recorded when a focus countdown
/// reaches zero. Keyed by the task's [name] (the timer's resolved display name
/// at the time it ran), so the statistics report groups time by task name.
class PomodoroLog implements JsonModel {
  const PomodoroLog({
    required this.name,
    required this.focusSeconds,
    required this.completedAt,
  });

  static const String kKey = 'pomodoro_logs_v1';

  /// The task name this session counted towards.
  final String name;

  /// How long the completed focus session was.
  final int focusSeconds;

  /// When the session finished.
  final DateTime completedAt;

  @override
  Map<String, Object?> toJson() => {
    'name': name,
    'focusSeconds': focusSeconds,
    'completedAt': completedAt.toIso8601String(),
  };

  factory PomodoroLog.fromJson(Map<String, Object?> json) => PomodoroLog(
    name: json['name'] as String? ?? '',
    focusSeconds: json['focusSeconds'] as int? ?? 0,
    completedAt:
        DateTime.tryParse(json['completedAt'] as String? ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0),
  );
}

/// A task's focus total for a single calendar day — one row in the report.
class PomodoroDailyStat {
  const PomodoroDailyStat({
    required this.name,
    required this.day,
    required this.focus,
    required this.sessions,
  });

  /// The task name.
  final String name;

  /// The calendar day (date only, local time).
  final DateTime day;

  /// Total focus time logged for [name] on [day].
  final Duration focus;

  /// Number of focus sessions logged for [name] on [day].
  final int sessions;
}

/// Collapse raw [logs] into per-task, per-day totals, newest day first (then by
/// task name). Drives the statistics list.
List<PomodoroDailyStat> aggregateDaily(List<PomodoroLog> logs) {
  // Group by (day, name); the key keeps both so rows stay split per task.
  final buckets = <String, PomodoroDailyStat>{};
  for (final log in logs) {
    final d = log.completedAt;
    final day = DateTime(d.year, d.month, d.day);
    final key = '${day.toIso8601String()} ${log.name}';
    final existing = buckets[key];
    buckets[key] = PomodoroDailyStat(
      name: log.name,
      day: day,
      focus:
          (existing?.focus ?? Duration.zero) +
          Duration(seconds: log.focusSeconds),
      sessions: (existing?.sessions ?? 0) + 1,
    );
  }
  final rows = buckets.values.toList();
  rows.sort((a, b) {
    final byDay = b.day.compareTo(a.day);
    return byDay != 0 ? byDay : a.name.compareTo(b.name);
  });
  return rows;
}
