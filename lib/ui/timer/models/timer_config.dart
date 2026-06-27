import 'dart:math' as math;

import '../../../l10n/app_localizations.dart';

/// One configurable countdown preset: a named duration plus alert preferences.
///
/// Persisted as part of the timer module's settings map (see `TimerModule`), so
/// it is a plain, JSON-friendly value with no behaviour of its own. The sound /
/// vibrate flags are stored now and wired up to actual playback later.
class TimerConfig {
  const TimerConfig({
    required this.id,
    required this.name,
    required this.duration,
    this.labelKey,
    this.sound = true,
    this.vibrate = true,
  });

  /// Stable identifier, unique within the list. Used as the selection key and
  /// the widget key so a row keeps its edit state across rebuilds.
  final String id;

  /// An explicit, user-chosen label. Empty for a default preset that has not
  /// been renamed — in that case the displayed name comes from [labelKey],
  /// localized at render time (see [displayName]).
  final String name;

  /// The semantic key of a built-in default label (`focus`, `shortBreak`,
  /// `longBreak`). Null once the timer is user-named. Stored instead of a
  /// baked-in string so default names follow the app locale at runtime.
  final String? labelKey;

  /// The countdown length.
  final Duration duration;

  /// Play a sound when this timer finishes. (Playback is implemented later.)
  final bool sound;

  /// Vibrate when this timer finishes. (Playback is implemented later.)
  final bool vibrate;

  /// The label to show: the user's [name] if set, otherwise the localized
  /// built-in label for [labelKey]. Falls back to empty when neither applies.
  String displayName(AppLocalizations l10n) {
    if (name.isNotEmpty) return name;
    switch (labelKey) {
      case 'focus':
        return l10n.timerDefaultFocus;
      case 'shortBreak':
        return l10n.timerDefaultShortBreak;
      case 'longBreak':
        return l10n.timerDefaultLongBreak;
    }
    return '';
  }

  /// Like [copyWith], but always clears [labelKey] — used when the user gives
  /// the timer an explicit name, turning a default preset into a custom one.
  TimerConfig rename(String name) => TimerConfig(
    id: id,
    name: name,
    duration: duration,
    sound: sound,
    vibrate: vibrate,
  );

  TimerConfig copyWith({
    String? name,
    Duration? duration,
    bool? sound,
    bool? vibrate,
  }) {
    return TimerConfig(
      id: id,
      name: name ?? this.name,
      labelKey: labelKey,
      duration: duration ?? this.duration,
      sound: sound ?? this.sound,
      vibrate: vibrate ?? this.vibrate,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    if (labelKey != null) 'labelKey': labelKey,
    'durationSec': duration.inSeconds,
    'sound': sound,
    'vibrate': vibrate,
  };

  factory TimerConfig.fromJson(Map<String, Object?> json) => TimerConfig(
    id: json['id'] as String? ?? newId(),
    name: json['name'] as String? ?? '',
    labelKey: json['labelKey'] as String?,
    duration: Duration(seconds: json['durationSec'] as int? ?? 0),
    sound: json['sound'] as bool? ?? true,
    vibrate: json['vibrate'] as bool? ?? true,
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
      other.vibrate == vibrate;

  @override
  int get hashCode =>
      Object.hash(id, name, labelKey, duration, sound, vibrate);
}
