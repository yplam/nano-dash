// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Nano Dash';

  @override
  String get dashboardEmpty => 'No widgets enabled';

  @override
  String get dashboardEmptyHint => 'Enable a widget below to show it here.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsDone => 'Done';

  @override
  String get moduleClockTitle => 'Clock';

  @override
  String get moduleTimerTitle => 'Timer';

  @override
  String get moduleStopwatchTitle => 'Stopwatch';

  @override
  String get moduleLive2dTitle => 'Live2D';

  @override
  String get moduleSystemTitle => 'System Monitor';

  @override
  String get moduleSettingsTitle => 'Settings';

  @override
  String get clear => 'Clear';

  @override
  String get settingsBackground => 'Background';

  @override
  String get settingsBackgroundDefault => 'Default';

  @override
  String get settingsBackgroundHint => 'Image, GIF or animated WebP';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageSystem => 'System';

  @override
  String get settingsThemeColor => 'Theme color';

  @override
  String get systemCpu => 'CPU';

  @override
  String get systemMemory => 'Memory';

  @override
  String get systemNetwork => 'Network';

  @override
  String get systemTemperature => 'Temp';

  @override
  String get systemUnavailable => 'System info unavailable';

  @override
  String get live2dChooseModel => 'Model folder';

  @override
  String get live2dNoModel => 'No model selected';

  @override
  String get live2dClear => 'Clear';

  @override
  String get live2dPickHint => 'Choose a Live2D model folder in settings.';

  @override
  String get live2dNoModelJson => 'No .model3.json found in that folder.';

  @override
  String get live2dLoadFailed => 'Couldn\'t load the model.';

  @override
  String get live2dUnavailable => 'Live2D isn\'t available on this device.';

  @override
  String get timerHours => 'Hours';

  @override
  String get timerMinutes => 'Minutes';

  @override
  String get timerSeconds => 'Seconds';

  @override
  String get timerDone => 'Done';

  @override
  String get timerName => 'Name';

  @override
  String get timerSound => 'Sound';

  @override
  String get timerVibrate => 'Vibrate';

  @override
  String get timerAdd => 'Add timer';

  @override
  String get timerDelete => 'Delete';

  @override
  String get timerNewName => 'Timer';

  @override
  String get timerEmpty => 'No timers';

  @override
  String get timerDefaultCountdown => 'Countdown';

  @override
  String get timerDefaultPomodoro => 'Pomodoro';

  @override
  String get timerDefaultFocus => 'Focus';

  @override
  String get timerDefaultShortBreak => 'Short Break';

  @override
  String get timerDefaultLongBreak => 'Long Break';

  @override
  String get timerPomodoro => 'Pomodoro';

  @override
  String get timerShortBreak => 'Short break';

  @override
  String get timerLongBreak => 'Long break';

  @override
  String get timerLongBreakEvery => 'Long break every';

  @override
  String get timerStats => 'Statistics';

  @override
  String get timerStatsEmpty => 'No focus sessions yet';

  @override
  String timerStatsSessions(int count) {
    return '$count sessions';
  }

  @override
  String get moduleControlsTitle => 'Controls';

  @override
  String get moduleWidgetsTitle => 'Widgets';

  @override
  String get controlsPower => 'Power';

  @override
  String get controlsOn => 'On';

  @override
  String get controlsOff => 'Off';

  @override
  String get clockUse24Hour => '24-hour time';

  @override
  String get clockShowSeconds => 'Show seconds';

  @override
  String get clockShowDate => 'Show date';

  @override
  String get clockShowWeather => 'Show weather';

  @override
  String get weatherCity => 'City';

  @override
  String get weatherCityHint => 'e.g. Shanghai';

  @override
  String get weatherUnitsCelsius => 'Celsius (°C)';

  @override
  String get weatherUnitsFahrenheit => 'Fahrenheit (°F)';

  @override
  String get weatherError => 'Weather unavailable';

  @override
  String weatherFetchFailed(Object city) {
    return 'Couldn\'t get weather for \"$city\"';
  }

  @override
  String weatherFeelsLike(Object temp) {
    return 'Feels like $temp';
  }

  @override
  String get weatherAirQuality => 'Air quality';

  @override
  String get weatherAqiGood => 'Good';

  @override
  String get weatherAqiFair => 'Fair';

  @override
  String get weatherAqiModerate => 'Moderate';

  @override
  String get weatherAqiPoor => 'Poor';

  @override
  String get weatherAqiVeryPoor => 'Very poor';

  @override
  String get weatherAqiExtremelyPoor => 'Extremely poor';

  @override
  String get picoViewOpenFailed => 'Couldn\'t open the LCD display.';

  @override
  String get picoViewUnauthorized =>
      'This display is not a genuine device (or its firmware is too old), so it can\'t be used.';

  @override
  String get retry => 'Retry';

  @override
  String get settings => 'Settings';

  @override
  String get trayShow => 'Show NanoDash';

  @override
  String get trayHide => 'Hide to tray';

  @override
  String get trayQuit => 'Quit';

  @override
  String get trayTooltip => 'NanoDash';
}
