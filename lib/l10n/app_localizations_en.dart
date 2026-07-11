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
  String get moduleWeatherTitle => 'Weather';

  @override
  String get moduleCalendarTitle => 'Calendar';

  @override
  String get moduleMarketsTitle => 'Markets';

  @override
  String get moduleNowPlayingTitle => 'Now Playing';

  @override
  String get moduleVoiceTitle => 'Voice';

  @override
  String get moduleSettingsTitle => 'Settings';

  @override
  String get nowPlayingIdle => 'Nothing playing';

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
  String get settingsThemeMode => 'Appearance';

  @override
  String get settingsThemeModeSystem => 'System';

  @override
  String get settingsThemeModeLight => 'Light';

  @override
  String get settingsThemeModeDark => 'Dark';

  @override
  String get settingsBrightness => 'Brightness';

  @override
  String get settingsAlertEffect => 'Alert effect';

  @override
  String get alertEffectNone => 'Off';

  @override
  String get alertEffectClick => 'Click';

  @override
  String get alertEffectTick => 'Tick';

  @override
  String get alertEffectDoubleClick => 'Double click';

  @override
  String get alertEffectBuzz => 'Buzz';

  @override
  String get alertEffectStrongBuzz => 'Strong buzz';

  @override
  String get alertEffectAlert750 => 'Alert 750 ms';

  @override
  String get alertEffectAlert1000 => 'Alert 1000 ms';

  @override
  String get alertEffectPulsing => 'Pulsing';

  @override
  String get settingsAdvanced => 'Advanced';

  @override
  String get settingsFirmwareUpdate => 'Firmware update';

  @override
  String get settingsFirmwareUpdateHint => 'Flash a .bin to the panel over USB';

  @override
  String get settingsFirmwareUpdateNotConnected =>
      'Connect the panel to update';

  @override
  String firmwareCurrentVersion(String version) {
    return 'Installed: $version';
  }

  @override
  String get firmwareInvalidImage =>
      'That file isn\'t a valid ESP32 firmware image.';

  @override
  String get firmwareConfirmTitle => 'Update panel firmware?';

  @override
  String get firmwareConfirmBody =>
      'The panel will reboot into the new firmware. Keep it plugged in until the update finishes.';

  @override
  String get firmwareUpdate => 'Update';

  @override
  String get firmwareReceiving => 'Sending firmware…';

  @override
  String get firmwareVerifying => 'Verifying…';

  @override
  String get firmwareDone => 'Firmware updated. The panel is rebooting.';

  @override
  String firmwareFailed(int code) {
    return 'Update failed (error $code).';
  }

  @override
  String get cancel => 'Cancel';

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
  String get live2dZoom => 'Zoom';

  @override
  String get live2dVerticalOffset => 'Vertical offset';

  @override
  String get voiceModelsDir => 'Models folder';

  @override
  String get voiceNoModelsDir => 'No folder selected';

  @override
  String get voiceWakeWord => 'Wake word';

  @override
  String get voiceWakeWordHint =>
      'Listen for the wake word before transcribing. Off keeps the mic transcribing continuously.';

  @override
  String get voiceAec => 'Echo cancellation';

  @override
  String get voiceAecHint =>
      'Remove the spoken reply from the microphone, so it can be interrupted while it talks.';

  @override
  String get voiceLanguage => 'Recognition language';

  @override
  String get voiceLanguageAuto => 'Auto';

  @override
  String get voiceTtsBackend => 'Speech backend';

  @override
  String get voiceTtsNone => 'None (text only)';

  @override
  String get voiceTtsApiKey => 'API key';

  @override
  String get voiceTtsBaseUrl => 'Base URL';

  @override
  String get voiceTtsResourceId => 'Resource id';

  @override
  String get voiceTtsSpeaker => 'Voice';

  @override
  String get voiceTtsModel => 'Model';

  @override
  String get voiceTtsLanguage => 'Speech language';

  @override
  String get voiceTtsInstructions => 'Voice instructions';

  @override
  String get voiceTtsProxy => 'Proxy';

  @override
  String get voiceSpeakerId => 'Speaker id';

  @override
  String get voiceSpeed => 'Speed';

  @override
  String get voiceRestartToApply =>
      'Turn the microphone off and on again to apply these settings.';

  @override
  String get voiceSpeakerYou => 'You';

  @override
  String get moduleAgentTitle => 'Assistant';

  @override
  String get agentEnable => 'Enable assistant';

  @override
  String get agentEnableHint =>
      'Answer questions heard by the microphone with an AI model.';

  @override
  String get agentApiKey => 'API key';

  @override
  String get agentBaseUrl => 'Base URL';

  @override
  String get agentProxy => 'Proxy';

  @override
  String get agentLightModel => 'Quick model';

  @override
  String get agentLightModelHint =>
      'Hears every question and answers the simple ones.';

  @override
  String get agentProModel => 'Smart model';

  @override
  String get agentProModelHint =>
      'Takes over complex questions, with data tools.';

  @override
  String get agentPersona => 'Persona';

  @override
  String get agentPersonaHint =>
      'Optional character description for the assistant.';

  @override
  String get agentNeedsApiKey => 'Set an API key for the assistant to answer.';

  @override
  String get agentErrorLine => 'Sorry, something went wrong.';

  @override
  String get agentSpeakerName => 'Assistant';

  @override
  String get agentStop => 'Stop';

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
  String get weatherUseMyLocation => 'Use my location';

  @override
  String get weatherLocationFailed => 'Couldn\'t detect your location';

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
  String get weatherConditionClearDay => 'Clear sky';

  @override
  String get weatherConditionClearNight => 'Clear night';

  @override
  String get weatherConditionPartlyCloudy => 'Partly cloudy';

  @override
  String get weatherConditionCloudy => 'Cloudy';

  @override
  String get weatherConditionFog => 'Fog';

  @override
  String get weatherConditionDrizzle => 'Drizzle';

  @override
  String get weatherConditionRain => 'Rain';

  @override
  String get weatherConditionSnow => 'Snow';

  @override
  String get weatherConditionThunderstorm => 'Thunderstorm';

  @override
  String get weatherNow => 'Now';

  @override
  String get weatherToday => 'Today';

  @override
  String get weatherDaily => '7-day forecast';

  @override
  String get marketsError => 'Market data unavailable';

  @override
  String get marketsEmpty => 'No symbols in your watchlist';

  @override
  String get marketsFetchFailed => 'Couldn\'t refresh market data';

  @override
  String get marketsWatchlist => 'Watchlist';

  @override
  String get marketsWatchlistHint => 'AAPL\n^GSPC\nBTC-USD';

  @override
  String get marketsWatchlistHelp =>
      'One ticker per line, in Yahoo Finance form: ^ for indices (^GSPC), -USD for crypto (BTC-USD), and =X for FX (EURUSD=X).';

  @override
  String get marketsProxyYahoo => 'Yahoo Finance proxy (optional)';

  @override
  String get marketsProxyHint => 'host:port or socks5://host:port';

  @override
  String get calendarEmpty => 'No upcoming events';

  @override
  String get calendarError => 'Calendar unavailable';

  @override
  String get calendarToday => 'Today';

  @override
  String get calendarTomorrow => 'Tomorrow';

  @override
  String get calendarAllDay => 'All day';

  @override
  String get calendarNoFeeds => 'No calendars added yet.';

  @override
  String get calendarAddFeed => 'Add calendar';

  @override
  String get calendarRemoveFeed => 'Remove';

  @override
  String get calendarFeedUrl => 'Calendar URL';

  @override
  String get calendarFeedUrlHint => 'https://…/calendar.ics';

  @override
  String get calendarFeedOptions => 'Options';

  @override
  String get calendarFeedLabel => 'Name (optional)';

  @override
  String get calendarFeedUsername => 'Username';

  @override
  String get calendarFeedPassword => 'Password';

  @override
  String get calendarFeedProxy => 'Proxy (optional)';

  @override
  String get calendarFeedProxyHint => 'host:port or socks5://host:port';

  @override
  String get calendarRangeTitle => 'Show';

  @override
  String get calendarRangeToday => 'Today';

  @override
  String get calendarRangeTodayTomorrow => 'Today & tomorrow';

  @override
  String get calendarRangeAll => 'All';

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
