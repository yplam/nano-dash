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
  String get timerMinutes => 'Minutes';

  @override
  String get timerSeconds => 'Seconds';

  @override
  String get timerDone => 'Done';

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
