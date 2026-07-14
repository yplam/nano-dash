import '../../../domain/models/timer.dart';
import '../../../l10n/app_localizations.dart';

export '../../../domain/models/timer.dart' show TimerConfig;

/// UI-side rendering of a [TimerConfig]'s name: the domain model stays free of
/// localization, so resolving a default preset's [TimerConfig.labelKey] into
/// the active locale happens here.
extension TimerConfigDisplay on TimerConfig {
  /// The label to show: the user's [TimerConfig.name] if set, otherwise the
  /// localized built-in label for [TimerConfig.labelKey]. Falls back to empty
  /// when neither applies.
  String displayName(AppLocalizations l10n) {
    if (name.isNotEmpty) return name;
    switch (labelKey) {
      case 'countdown':
        return l10n.timerDefaultCountdown;
      case 'pomodoro':
        return l10n.timerDefaultPomodoro;
      case 'focus':
        return l10n.timerDefaultFocus;
      case 'shortBreak':
        return l10n.timerDefaultShortBreak;
      case 'longBreak':
        return l10n.timerDefaultLongBreak;
    }
    return '';
  }
}
