import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Nano Dash'**
  String get appTitle;

  /// No description provided for @dashboardEmpty.
  ///
  /// In en, this message translates to:
  /// **'No widgets enabled'**
  String get dashboardEmpty;

  /// No description provided for @dashboardEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Enable a widget below to show it here.'**
  String get dashboardEmptyHint;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get settingsDone;

  /// No description provided for @moduleClockTitle.
  ///
  /// In en, this message translates to:
  /// **'Clock'**
  String get moduleClockTitle;

  /// No description provided for @moduleTimerTitle.
  ///
  /// In en, this message translates to:
  /// **'Timer'**
  String get moduleTimerTitle;

  /// No description provided for @moduleStopwatchTitle.
  ///
  /// In en, this message translates to:
  /// **'Stopwatch'**
  String get moduleStopwatchTitle;

  /// No description provided for @moduleLive2dTitle.
  ///
  /// In en, this message translates to:
  /// **'Live2D'**
  String get moduleLive2dTitle;

  /// No description provided for @live2dChooseModel.
  ///
  /// In en, this message translates to:
  /// **'Model folder'**
  String get live2dChooseModel;

  /// No description provided for @live2dNoModel.
  ///
  /// In en, this message translates to:
  /// **'No model selected'**
  String get live2dNoModel;

  /// No description provided for @live2dClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get live2dClear;

  /// No description provided for @live2dPickHint.
  ///
  /// In en, this message translates to:
  /// **'Choose a Live2D model folder in settings.'**
  String get live2dPickHint;

  /// No description provided for @live2dNoModelJson.
  ///
  /// In en, this message translates to:
  /// **'No .model3.json found in that folder.'**
  String get live2dNoModelJson;

  /// No description provided for @live2dLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the model.'**
  String get live2dLoadFailed;

  /// No description provided for @live2dUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Live2D isn\'t available on this device.'**
  String get live2dUnavailable;

  /// No description provided for @timerHours.
  ///
  /// In en, this message translates to:
  /// **'Hours'**
  String get timerHours;

  /// No description provided for @timerMinutes.
  ///
  /// In en, this message translates to:
  /// **'Minutes'**
  String get timerMinutes;

  /// No description provided for @timerSeconds.
  ///
  /// In en, this message translates to:
  /// **'Seconds'**
  String get timerSeconds;

  /// No description provided for @timerDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get timerDone;

  /// No description provided for @timerName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get timerName;

  /// No description provided for @timerSound.
  ///
  /// In en, this message translates to:
  /// **'Sound'**
  String get timerSound;

  /// No description provided for @timerVibrate.
  ///
  /// In en, this message translates to:
  /// **'Vibrate'**
  String get timerVibrate;

  /// No description provided for @timerAdd.
  ///
  /// In en, this message translates to:
  /// **'Add timer'**
  String get timerAdd;

  /// No description provided for @timerDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get timerDelete;

  /// No description provided for @timerNewName.
  ///
  /// In en, this message translates to:
  /// **'Timer'**
  String get timerNewName;

  /// No description provided for @timerEmpty.
  ///
  /// In en, this message translates to:
  /// **'No timers'**
  String get timerEmpty;

  /// No description provided for @timerDefaultCountdown.
  ///
  /// In en, this message translates to:
  /// **'Countdown'**
  String get timerDefaultCountdown;

  /// No description provided for @timerDefaultPomodoro.
  ///
  /// In en, this message translates to:
  /// **'Pomodoro'**
  String get timerDefaultPomodoro;

  /// No description provided for @timerDefaultFocus.
  ///
  /// In en, this message translates to:
  /// **'Focus'**
  String get timerDefaultFocus;

  /// No description provided for @timerDefaultShortBreak.
  ///
  /// In en, this message translates to:
  /// **'Short Break'**
  String get timerDefaultShortBreak;

  /// No description provided for @timerDefaultLongBreak.
  ///
  /// In en, this message translates to:
  /// **'Long Break'**
  String get timerDefaultLongBreak;

  /// No description provided for @timerPomodoro.
  ///
  /// In en, this message translates to:
  /// **'Pomodoro'**
  String get timerPomodoro;

  /// No description provided for @timerShortBreak.
  ///
  /// In en, this message translates to:
  /// **'Short break'**
  String get timerShortBreak;

  /// No description provided for @timerLongBreak.
  ///
  /// In en, this message translates to:
  /// **'Long break'**
  String get timerLongBreak;

  /// No description provided for @timerLongBreakEvery.
  ///
  /// In en, this message translates to:
  /// **'Long break every'**
  String get timerLongBreakEvery;

  /// No description provided for @timerStats.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get timerStats;

  /// No description provided for @timerStatsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No focus sessions yet'**
  String get timerStatsEmpty;

  /// No description provided for @timerStatsSessions.
  ///
  /// In en, this message translates to:
  /// **'{count} sessions'**
  String timerStatsSessions(int count);

  /// No description provided for @moduleControlsTitle.
  ///
  /// In en, this message translates to:
  /// **'Controls'**
  String get moduleControlsTitle;

  /// No description provided for @moduleWidgetsTitle.
  ///
  /// In en, this message translates to:
  /// **'Widgets'**
  String get moduleWidgetsTitle;

  /// No description provided for @controlsPower.
  ///
  /// In en, this message translates to:
  /// **'Power'**
  String get controlsPower;

  /// No description provided for @controlsOn.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get controlsOn;

  /// No description provided for @controlsOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get controlsOff;

  /// No description provided for @clockUse24Hour.
  ///
  /// In en, this message translates to:
  /// **'24-hour time'**
  String get clockUse24Hour;

  /// No description provided for @clockShowSeconds.
  ///
  /// In en, this message translates to:
  /// **'Show seconds'**
  String get clockShowSeconds;

  /// No description provided for @clockShowDate.
  ///
  /// In en, this message translates to:
  /// **'Show date'**
  String get clockShowDate;

  /// No description provided for @clockShowWeather.
  ///
  /// In en, this message translates to:
  /// **'Show weather'**
  String get clockShowWeather;

  /// No description provided for @weatherCity.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get weatherCity;

  /// No description provided for @weatherCityHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Shanghai'**
  String get weatherCityHint;

  /// No description provided for @weatherUnitsCelsius.
  ///
  /// In en, this message translates to:
  /// **'Celsius (°C)'**
  String get weatherUnitsCelsius;

  /// No description provided for @weatherUnitsFahrenheit.
  ///
  /// In en, this message translates to:
  /// **'Fahrenheit (°F)'**
  String get weatherUnitsFahrenheit;

  /// No description provided for @weatherError.
  ///
  /// In en, this message translates to:
  /// **'Weather unavailable'**
  String get weatherError;

  /// No description provided for @weatherFetchFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t get weather for \"{city}\"'**
  String weatherFetchFailed(Object city);

  /// No description provided for @weatherFeelsLike.
  ///
  /// In en, this message translates to:
  /// **'Feels like {temp}'**
  String weatherFeelsLike(Object temp);

  /// No description provided for @weatherAirQuality.
  ///
  /// In en, this message translates to:
  /// **'Air quality'**
  String get weatherAirQuality;

  /// No description provided for @weatherAqiGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get weatherAqiGood;

  /// No description provided for @weatherAqiFair.
  ///
  /// In en, this message translates to:
  /// **'Fair'**
  String get weatherAqiFair;

  /// No description provided for @weatherAqiModerate.
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get weatherAqiModerate;

  /// No description provided for @weatherAqiPoor.
  ///
  /// In en, this message translates to:
  /// **'Poor'**
  String get weatherAqiPoor;

  /// No description provided for @weatherAqiVeryPoor.
  ///
  /// In en, this message translates to:
  /// **'Very poor'**
  String get weatherAqiVeryPoor;

  /// No description provided for @weatherAqiExtremelyPoor.
  ///
  /// In en, this message translates to:
  /// **'Extremely poor'**
  String get weatherAqiExtremelyPoor;

  /// No description provided for @picoViewOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open the LCD display.'**
  String get picoViewOpenFailed;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @trayShow.
  ///
  /// In en, this message translates to:
  /// **'Show NanoDash'**
  String get trayShow;

  /// No description provided for @trayHide.
  ///
  /// In en, this message translates to:
  /// **'Hide to tray'**
  String get trayHide;

  /// No description provided for @trayQuit.
  ///
  /// In en, this message translates to:
  /// **'Quit'**
  String get trayQuit;

  /// No description provided for @trayTooltip.
  ///
  /// In en, this message translates to:
  /// **'NanoDash'**
  String get trayTooltip;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
