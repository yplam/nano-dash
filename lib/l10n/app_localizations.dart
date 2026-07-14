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

  /// No description provided for @moduleVisibilityOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get moduleVisibilityOff;

  /// No description provided for @moduleVisibilityAssistant.
  ///
  /// In en, this message translates to:
  /// **'Assistant only'**
  String get moduleVisibilityAssistant;

  /// No description provided for @moduleVisibilityCarousel.
  ///
  /// In en, this message translates to:
  /// **'In carousel'**
  String get moduleVisibilityCarousel;

  /// No description provided for @moduleVisibilityTooltip.
  ///
  /// In en, this message translates to:
  /// **'Off: hidden. Assistant only: hidden from swiping, but the assistant can show it. In carousel: a normal swipe page.'**
  String get moduleVisibilityTooltip;

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

  /// No description provided for @moduleSystemTitle.
  ///
  /// In en, this message translates to:
  /// **'System Monitor'**
  String get moduleSystemTitle;

  /// No description provided for @moduleWeatherTitle.
  ///
  /// In en, this message translates to:
  /// **'Weather'**
  String get moduleWeatherTitle;

  /// No description provided for @moduleCalendarTitle.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get moduleCalendarTitle;

  /// No description provided for @moduleMarketsTitle.
  ///
  /// In en, this message translates to:
  /// **'Markets'**
  String get moduleMarketsTitle;

  /// No description provided for @moduleUsageMonitorTitle.
  ///
  /// In en, this message translates to:
  /// **'Usage Monitor'**
  String get moduleUsageMonitorTitle;

  /// No description provided for @moduleNowPlayingTitle.
  ///
  /// In en, this message translates to:
  /// **'Now Playing'**
  String get moduleNowPlayingTitle;

  /// No description provided for @moduleVoiceTitle.
  ///
  /// In en, this message translates to:
  /// **'Voice'**
  String get moduleVoiceTitle;

  /// No description provided for @moduleVideoTitle.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get moduleVideoTitle;

  /// No description provided for @moduleSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get moduleSettingsTitle;

  /// No description provided for @nowPlayingIdle.
  ///
  /// In en, this message translates to:
  /// **'Nothing playing'**
  String get nowPlayingIdle;

  /// No description provided for @videoIdle.
  ///
  /// In en, this message translates to:
  /// **'No video'**
  String get videoIdle;

  /// No description provided for @videoPickHint.
  ///
  /// In en, this message translates to:
  /// **'Tap to choose a file'**
  String get videoPickHint;

  /// No description provided for @videoError.
  ///
  /// In en, this message translates to:
  /// **'Playback error'**
  String get videoError;

  /// No description provided for @videoPlaying.
  ///
  /// In en, this message translates to:
  /// **'Playing on panel'**
  String get videoPlaying;

  /// No description provided for @videoStopHint.
  ///
  /// In en, this message translates to:
  /// **'Tap to stop'**
  String get videoStopHint;

  /// No description provided for @videoPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get videoPause;

  /// No description provided for @videoResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get videoResume;

  /// No description provided for @videoStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get videoStop;

  /// No description provided for @videoRewind.
  ///
  /// In en, this message translates to:
  /// **'Back 10s'**
  String get videoRewind;

  /// No description provided for @videoForward.
  ///
  /// In en, this message translates to:
  /// **'Forward 10s'**
  String get videoForward;

  /// No description provided for @videoErrorFfmpeg.
  ///
  /// In en, this message translates to:
  /// **'FFmpeg not found — set its path in Settings'**
  String get videoErrorFfmpeg;

  /// No description provided for @videoErrorPanel.
  ///
  /// In en, this message translates to:
  /// **'Unknown panel size'**
  String get videoErrorPanel;

  /// No description provided for @videoErrorDecode.
  ///
  /// In en, this message translates to:
  /// **'Playback stopped'**
  String get videoErrorDecode;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @settingsBackground.
  ///
  /// In en, this message translates to:
  /// **'Background'**
  String get settingsBackground;

  /// No description provided for @settingsBackgroundDefault.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get settingsBackgroundDefault;

  /// No description provided for @settingsBackgroundHint.
  ///
  /// In en, this message translates to:
  /// **'Image, GIF or animated WebP'**
  String get settingsBackgroundHint;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsLanguageSystem;

  /// No description provided for @settingsThemeColor.
  ///
  /// In en, this message translates to:
  /// **'Theme color'**
  String get settingsThemeColor;

  /// No description provided for @settingsThemeMode.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsThemeMode;

  /// No description provided for @settingsThemeModeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsThemeModeSystem;

  /// No description provided for @settingsThemeModeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeModeLight;

  /// No description provided for @settingsThemeModeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeModeDark;

  /// No description provided for @settingsBrightness.
  ///
  /// In en, this message translates to:
  /// **'Brightness'**
  String get settingsBrightness;

  /// No description provided for @settingsAlertEffect.
  ///
  /// In en, this message translates to:
  /// **'Alert effect'**
  String get settingsAlertEffect;

  /// No description provided for @settingsFfmpeg.
  ///
  /// In en, this message translates to:
  /// **'FFmpeg'**
  String get settingsFfmpeg;

  /// No description provided for @settingsFfmpegAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto-detect'**
  String get settingsFfmpegAuto;

  /// No description provided for @settingsFfmpegHint.
  ///
  /// In en, this message translates to:
  /// **'Used by the Video module to decode files'**
  String get settingsFfmpegHint;

  /// No description provided for @settingsFfmpegNotFound.
  ///
  /// In en, this message translates to:
  /// **'Not found on PATH — tap to choose'**
  String get settingsFfmpegNotFound;

  /// No description provided for @alertEffectNone.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get alertEffectNone;

  /// No description provided for @alertEffectBump.
  ///
  /// In en, this message translates to:
  /// **'Bump'**
  String get alertEffectBump;

  /// No description provided for @alertEffectPulse.
  ///
  /// In en, this message translates to:
  /// **'Pulse'**
  String get alertEffectPulse;

  /// No description provided for @alertEffectMediumBuzz.
  ///
  /// In en, this message translates to:
  /// **'Medium buzz'**
  String get alertEffectMediumBuzz;

  /// No description provided for @alertEffectBuzz.
  ///
  /// In en, this message translates to:
  /// **'Buzz'**
  String get alertEffectBuzz;

  /// No description provided for @alertEffectStrongBuzz.
  ///
  /// In en, this message translates to:
  /// **'Strong buzz'**
  String get alertEffectStrongBuzz;

  /// No description provided for @alertEffectAlert750.
  ///
  /// In en, this message translates to:
  /// **'Alert 750 ms'**
  String get alertEffectAlert750;

  /// No description provided for @alertEffectAlert1000.
  ///
  /// In en, this message translates to:
  /// **'Alert 1000 ms'**
  String get alertEffectAlert1000;

  /// No description provided for @alertEffectPulsing.
  ///
  /// In en, this message translates to:
  /// **'Pulsing'**
  String get alertEffectPulsing;

  /// No description provided for @settingsReset.
  ///
  /// In en, this message translates to:
  /// **'Reset to default'**
  String get settingsReset;

  /// No description provided for @settingsResetConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset all settings?'**
  String get settingsResetConfirmTitle;

  /// No description provided for @settingsResetConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This restores every setting to its default and removes the chosen background.'**
  String get settingsResetConfirmBody;

  /// No description provided for @settingsAdvanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get settingsAdvanced;

  /// No description provided for @settingsFirmwareUpdate.
  ///
  /// In en, this message translates to:
  /// **'Firmware update'**
  String get settingsFirmwareUpdate;

  /// No description provided for @settingsFirmwareUpdateHint.
  ///
  /// In en, this message translates to:
  /// **'Flash a .bin to the panel over USB'**
  String get settingsFirmwareUpdateHint;

  /// No description provided for @settingsFirmwareUpdateNotConnected.
  ///
  /// In en, this message translates to:
  /// **'Connect the panel to update'**
  String get settingsFirmwareUpdateNotConnected;

  /// No description provided for @firmwareCurrentVersion.
  ///
  /// In en, this message translates to:
  /// **'Installed: {version}'**
  String firmwareCurrentVersion(String version);

  /// No description provided for @firmwareInvalidImage.
  ///
  /// In en, this message translates to:
  /// **'That file isn\'t a valid ESP32 firmware image.'**
  String get firmwareInvalidImage;

  /// No description provided for @firmwareConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Update panel firmware?'**
  String get firmwareConfirmTitle;

  /// No description provided for @firmwareConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'The panel will reboot into the new firmware. Keep it plugged in until the update finishes.'**
  String get firmwareConfirmBody;

  /// No description provided for @firmwareUpdate.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get firmwareUpdate;

  /// No description provided for @firmwareReceiving.
  ///
  /// In en, this message translates to:
  /// **'Sending firmware…'**
  String get firmwareReceiving;

  /// No description provided for @firmwareVerifying.
  ///
  /// In en, this message translates to:
  /// **'Verifying…'**
  String get firmwareVerifying;

  /// No description provided for @firmwareDone.
  ///
  /// In en, this message translates to:
  /// **'Firmware updated. The panel is rebooting.'**
  String get firmwareDone;

  /// No description provided for @firmwareFailed.
  ///
  /// In en, this message translates to:
  /// **'Update failed (error {code}).'**
  String firmwareFailed(int code);

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @systemCpu.
  ///
  /// In en, this message translates to:
  /// **'CPU'**
  String get systemCpu;

  /// No description provided for @systemMemory.
  ///
  /// In en, this message translates to:
  /// **'Memory'**
  String get systemMemory;

  /// No description provided for @systemNetwork.
  ///
  /// In en, this message translates to:
  /// **'Network'**
  String get systemNetwork;

  /// No description provided for @systemTemperature.
  ///
  /// In en, this message translates to:
  /// **'Temp'**
  String get systemTemperature;

  /// No description provided for @systemUnavailable.
  ///
  /// In en, this message translates to:
  /// **'System info unavailable'**
  String get systemUnavailable;

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

  /// No description provided for @live2dZoom.
  ///
  /// In en, this message translates to:
  /// **'Zoom'**
  String get live2dZoom;

  /// No description provided for @live2dVerticalOffset.
  ///
  /// In en, this message translates to:
  /// **'Vertical offset'**
  String get live2dVerticalOffset;

  /// No description provided for @voiceModelsDir.
  ///
  /// In en, this message translates to:
  /// **'Models folder'**
  String get voiceModelsDir;

  /// No description provided for @voiceNoModelsDir.
  ///
  /// In en, this message translates to:
  /// **'No folder selected'**
  String get voiceNoModelsDir;

  /// No description provided for @voiceWakeWord.
  ///
  /// In en, this message translates to:
  /// **'Wake word'**
  String get voiceWakeWord;

  /// No description provided for @voiceWakeWordHint.
  ///
  /// In en, this message translates to:
  /// **'Listen for the wake word before transcribing. Off keeps the mic transcribing continuously.'**
  String get voiceWakeWordHint;

  /// No description provided for @voiceAec.
  ///
  /// In en, this message translates to:
  /// **'Echo cancellation'**
  String get voiceAec;

  /// No description provided for @voiceAecHint.
  ///
  /// In en, this message translates to:
  /// **'Remove the spoken reply from the microphone, so it can be interrupted while it talks.'**
  String get voiceAecHint;

  /// No description provided for @voiceLanguage.
  ///
  /// In en, this message translates to:
  /// **'Recognition language'**
  String get voiceLanguage;

  /// No description provided for @voiceLanguageAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get voiceLanguageAuto;

  /// No description provided for @voiceTtsBackend.
  ///
  /// In en, this message translates to:
  /// **'Speech backend'**
  String get voiceTtsBackend;

  /// No description provided for @voiceTtsNone.
  ///
  /// In en, this message translates to:
  /// **'None (text only)'**
  String get voiceTtsNone;

  /// No description provided for @voiceTtsApiKey.
  ///
  /// In en, this message translates to:
  /// **'API key'**
  String get voiceTtsApiKey;

  /// No description provided for @voiceTtsBaseUrl.
  ///
  /// In en, this message translates to:
  /// **'Base URL'**
  String get voiceTtsBaseUrl;

  /// No description provided for @voiceTtsResourceId.
  ///
  /// In en, this message translates to:
  /// **'Resource id'**
  String get voiceTtsResourceId;

  /// No description provided for @voiceTtsSpeaker.
  ///
  /// In en, this message translates to:
  /// **'Voice'**
  String get voiceTtsSpeaker;

  /// No description provided for @voiceTtsModel.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get voiceTtsModel;

  /// No description provided for @voiceTtsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Speech language'**
  String get voiceTtsLanguage;

  /// No description provided for @voiceTtsInstructions.
  ///
  /// In en, this message translates to:
  /// **'Voice instructions'**
  String get voiceTtsInstructions;

  /// No description provided for @voiceTtsProxy.
  ///
  /// In en, this message translates to:
  /// **'Proxy'**
  String get voiceTtsProxy;

  /// No description provided for @voiceSpeakerId.
  ///
  /// In en, this message translates to:
  /// **'Speaker id'**
  String get voiceSpeakerId;

  /// No description provided for @voiceSpeed.
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get voiceSpeed;

  /// No description provided for @voiceRestartToApply.
  ///
  /// In en, this message translates to:
  /// **'Turn the microphone off and on again to apply these settings.'**
  String get voiceRestartToApply;

  /// No description provided for @voiceSpeakerYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get voiceSpeakerYou;

  /// No description provided for @voiceSpeakerIdent.
  ///
  /// In en, this message translates to:
  /// **'Speaker identification'**
  String get voiceSpeakerIdent;

  /// No description provided for @voiceSpeakerIdentHint.
  ///
  /// In en, this message translates to:
  /// **'Load the speaker model and answer only your enrolled voice.'**
  String get voiceSpeakerIdentHint;

  /// No description provided for @voiceVoiceprint.
  ///
  /// In en, this message translates to:
  /// **'Voiceprint'**
  String get voiceVoiceprint;

  /// No description provided for @voiceEnrollRecord.
  ///
  /// In en, this message translates to:
  /// **'Record'**
  String get voiceEnrollRecord;

  /// No description provided for @voiceEnrollStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get voiceEnrollStop;

  /// No description provided for @voiceEnrollForget.
  ///
  /// In en, this message translates to:
  /// **'Forget'**
  String get voiceEnrollForget;

  /// No description provided for @voiceEnrollStarting.
  ///
  /// In en, this message translates to:
  /// **'Starting…'**
  String get voiceEnrollStarting;

  /// No description provided for @voiceEnrollRecording.
  ///
  /// In en, this message translates to:
  /// **'Recording… speak now, then tap Stop.'**
  String get voiceEnrollRecording;

  /// No description provided for @voiceEnrollPrompt.
  ///
  /// In en, this message translates to:
  /// **'Record your voiceprint so the assistant knows your voice.'**
  String get voiceEnrollPrompt;

  /// No description provided for @voiceEnrollCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No voiceprint recorded yet} =1{1 sample enrolled} other{{count} samples enrolled}}'**
  String voiceEnrollCount(int count);

  /// No description provided for @voiceEnrollFailed.
  ///
  /// In en, this message translates to:
  /// **'Enrollment failed: {reason}'**
  String voiceEnrollFailed(String reason);

  /// No description provided for @moduleAgentTitle.
  ///
  /// In en, this message translates to:
  /// **'Assistant'**
  String get moduleAgentTitle;

  /// No description provided for @agentEnable.
  ///
  /// In en, this message translates to:
  /// **'Enable assistant'**
  String get agentEnable;

  /// No description provided for @agentEnableHint.
  ///
  /// In en, this message translates to:
  /// **'Answer questions heard by the microphone with an AI model.'**
  String get agentEnableHint;

  /// No description provided for @agentApiKey.
  ///
  /// In en, this message translates to:
  /// **'API key'**
  String get agentApiKey;

  /// No description provided for @agentBaseUrl.
  ///
  /// In en, this message translates to:
  /// **'Base URL'**
  String get agentBaseUrl;

  /// No description provided for @agentProxy.
  ///
  /// In en, this message translates to:
  /// **'Proxy'**
  String get agentProxy;

  /// No description provided for @agentLightModel.
  ///
  /// In en, this message translates to:
  /// **'Quick model'**
  String get agentLightModel;

  /// No description provided for @agentLightModelHint.
  ///
  /// In en, this message translates to:
  /// **'Hears every question and answers the simple ones.'**
  String get agentLightModelHint;

  /// No description provided for @agentProModel.
  ///
  /// In en, this message translates to:
  /// **'Smart model'**
  String get agentProModel;

  /// No description provided for @agentProModelHint.
  ///
  /// In en, this message translates to:
  /// **'Takes over complex questions, with data tools.'**
  String get agentProModelHint;

  /// No description provided for @agentPersona.
  ///
  /// In en, this message translates to:
  /// **'Persona'**
  String get agentPersona;

  /// No description provided for @agentPersonaHint.
  ///
  /// In en, this message translates to:
  /// **'Optional character description for the assistant.'**
  String get agentPersonaHint;

  /// No description provided for @agentNeedsApiKey.
  ///
  /// In en, this message translates to:
  /// **'Set an API key for the assistant to answer.'**
  String get agentNeedsApiKey;

  /// No description provided for @agentErrorLine.
  ///
  /// In en, this message translates to:
  /// **'Sorry, something went wrong.'**
  String get agentErrorLine;

  /// No description provided for @agentReminderLine.
  ///
  /// In en, this message translates to:
  /// **'Reminder: {text}'**
  String agentReminderLine(String text);

  /// No description provided for @agentReminderMissedLine.
  ///
  /// In en, this message translates to:
  /// **'While I was off you missed a reminder: {text}'**
  String agentReminderMissedLine(String text);

  /// No description provided for @reminderNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Reminder'**
  String get reminderNotificationTitle;

  /// No description provided for @reminderNotificationMissedTitle.
  ///
  /// In en, this message translates to:
  /// **'Missed reminder'**
  String get reminderNotificationMissedTitle;

  /// No description provided for @agentSpeakerName.
  ///
  /// In en, this message translates to:
  /// **'Assistant'**
  String get agentSpeakerName;

  /// No description provided for @agentStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get agentStop;

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

  /// No description provided for @timerNotificationFinished.
  ///
  /// In en, this message translates to:
  /// **'Timer finished'**
  String get timerNotificationFinished;

  /// No description provided for @timerNotificationFocusDone.
  ///
  /// In en, this message translates to:
  /// **'Focus complete — time for a break'**
  String get timerNotificationFocusDone;

  /// No description provided for @timerNotificationBreakDone.
  ///
  /// In en, this message translates to:
  /// **'Break over — back to focus'**
  String get timerNotificationBreakDone;

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

  /// No description provided for @weatherUseMyLocation.
  ///
  /// In en, this message translates to:
  /// **'Use my location'**
  String get weatherUseMyLocation;

  /// No description provided for @weatherLocationFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t detect your location'**
  String get weatherLocationFailed;

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

  /// No description provided for @weatherConditionClearDay.
  ///
  /// In en, this message translates to:
  /// **'Clear sky'**
  String get weatherConditionClearDay;

  /// No description provided for @weatherConditionClearNight.
  ///
  /// In en, this message translates to:
  /// **'Clear night'**
  String get weatherConditionClearNight;

  /// No description provided for @weatherConditionPartlyCloudy.
  ///
  /// In en, this message translates to:
  /// **'Partly cloudy'**
  String get weatherConditionPartlyCloudy;

  /// No description provided for @weatherConditionCloudy.
  ///
  /// In en, this message translates to:
  /// **'Cloudy'**
  String get weatherConditionCloudy;

  /// No description provided for @weatherConditionFog.
  ///
  /// In en, this message translates to:
  /// **'Fog'**
  String get weatherConditionFog;

  /// No description provided for @weatherConditionDrizzle.
  ///
  /// In en, this message translates to:
  /// **'Drizzle'**
  String get weatherConditionDrizzle;

  /// No description provided for @weatherConditionRain.
  ///
  /// In en, this message translates to:
  /// **'Rain'**
  String get weatherConditionRain;

  /// No description provided for @weatherConditionSnow.
  ///
  /// In en, this message translates to:
  /// **'Snow'**
  String get weatherConditionSnow;

  /// No description provided for @weatherConditionThunderstorm.
  ///
  /// In en, this message translates to:
  /// **'Thunderstorm'**
  String get weatherConditionThunderstorm;

  /// No description provided for @weatherNow.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get weatherNow;

  /// No description provided for @weatherToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get weatherToday;

  /// No description provided for @weatherDaily.
  ///
  /// In en, this message translates to:
  /// **'7-day forecast'**
  String get weatherDaily;

  /// No description provided for @marketsError.
  ///
  /// In en, this message translates to:
  /// **'Market data unavailable'**
  String get marketsError;

  /// No description provided for @marketsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No symbols in your watchlist'**
  String get marketsEmpty;

  /// No description provided for @marketsFetchFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t refresh market data'**
  String get marketsFetchFailed;

  /// No description provided for @marketsWatchlist.
  ///
  /// In en, this message translates to:
  /// **'Watchlist'**
  String get marketsWatchlist;

  /// No description provided for @marketsWatchlistHint.
  ///
  /// In en, this message translates to:
  /// **'AAPL\n^GSPC\nBTC-USD'**
  String get marketsWatchlistHint;

  /// No description provided for @marketsWatchlistHelp.
  ///
  /// In en, this message translates to:
  /// **'One ticker per line, in Yahoo Finance form: ^ for indices (^GSPC), -USD for crypto (BTC-USD), and =X for FX (EURUSD=X).'**
  String get marketsWatchlistHelp;

  /// No description provided for @marketsProxyYahoo.
  ///
  /// In en, this message translates to:
  /// **'Yahoo Finance proxy (optional)'**
  String get marketsProxyYahoo;

  /// No description provided for @marketsProxyHint.
  ///
  /// In en, this message translates to:
  /// **'host:port or socks5://host:port'**
  String get marketsProxyHint;

  /// No description provided for @usageMonitorEmpty.
  ///
  /// In en, this message translates to:
  /// **'No providers enabled'**
  String get usageMonitorEmpty;

  /// No description provided for @usageMonitorNoData.
  ///
  /// In en, this message translates to:
  /// **'No usage data'**
  String get usageMonitorNoData;

  /// No description provided for @usageMonitorNotSignedIn.
  ///
  /// In en, this message translates to:
  /// **'Not signed in'**
  String get usageMonitorNotSignedIn;

  /// No description provided for @usageMonitorAuthExpired.
  ///
  /// In en, this message translates to:
  /// **'Login expired'**
  String get usageMonitorAuthExpired;

  /// No description provided for @usageMonitorRateLimited.
  ///
  /// In en, this message translates to:
  /// **'Rate limited'**
  String get usageMonitorRateLimited;

  /// No description provided for @usageMonitorNetworkError.
  ///
  /// In en, this message translates to:
  /// **'Network error'**
  String get usageMonitorNetworkError;

  /// No description provided for @usageMonitorUpstreamError.
  ///
  /// In en, this message translates to:
  /// **'Service unavailable'**
  String get usageMonitorUpstreamError;

  /// No description provided for @usageMonitorUnknownError.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get usageMonitorUnknownError;

  /// No description provided for @usageMonitorResetsSoon.
  ///
  /// In en, this message translates to:
  /// **'resetting…'**
  String get usageMonitorResetsSoon;

  /// No description provided for @usageMonitorResetsIn.
  ///
  /// In en, this message translates to:
  /// **'resets in {time}'**
  String usageMonitorResetsIn(String time);

  /// No description provided for @usageMonitorProxy.
  ///
  /// In en, this message translates to:
  /// **'Proxy (optional)'**
  String get usageMonitorProxy;

  /// No description provided for @usageMonitorProxyHint.
  ///
  /// In en, this message translates to:
  /// **'host:port or socks5://host:port'**
  String get usageMonitorProxyHint;

  /// No description provided for @calendarEmpty.
  ///
  /// In en, this message translates to:
  /// **'No upcoming events'**
  String get calendarEmpty;

  /// No description provided for @calendarError.
  ///
  /// In en, this message translates to:
  /// **'Calendar unavailable'**
  String get calendarError;

  /// No description provided for @calendarToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get calendarToday;

  /// No description provided for @calendarTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get calendarTomorrow;

  /// No description provided for @calendarAllDay.
  ///
  /// In en, this message translates to:
  /// **'All day'**
  String get calendarAllDay;

  /// No description provided for @calendarNoFeeds.
  ///
  /// In en, this message translates to:
  /// **'No calendars added yet.'**
  String get calendarNoFeeds;

  /// No description provided for @calendarAddFeed.
  ///
  /// In en, this message translates to:
  /// **'Add calendar'**
  String get calendarAddFeed;

  /// No description provided for @calendarRemoveFeed.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get calendarRemoveFeed;

  /// No description provided for @calendarFeedUrl.
  ///
  /// In en, this message translates to:
  /// **'Calendar URL'**
  String get calendarFeedUrl;

  /// No description provided for @calendarFeedUrlHint.
  ///
  /// In en, this message translates to:
  /// **'https://…/calendar.ics'**
  String get calendarFeedUrlHint;

  /// No description provided for @calendarFeedOptions.
  ///
  /// In en, this message translates to:
  /// **'Options'**
  String get calendarFeedOptions;

  /// No description provided for @calendarFeedLabel.
  ///
  /// In en, this message translates to:
  /// **'Name (optional)'**
  String get calendarFeedLabel;

  /// No description provided for @calendarFeedUsername.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get calendarFeedUsername;

  /// No description provided for @calendarFeedPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get calendarFeedPassword;

  /// No description provided for @calendarFeedProxy.
  ///
  /// In en, this message translates to:
  /// **'Proxy (optional)'**
  String get calendarFeedProxy;

  /// No description provided for @calendarFeedProxyHint.
  ///
  /// In en, this message translates to:
  /// **'host:port or socks5://host:port'**
  String get calendarFeedProxyHint;

  /// No description provided for @calendarRangeTitle.
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get calendarRangeTitle;

  /// No description provided for @calendarRangeToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get calendarRangeToday;

  /// No description provided for @calendarRangeTodayTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Today & tomorrow'**
  String get calendarRangeTodayTomorrow;

  /// No description provided for @calendarRangeAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get calendarRangeAll;

  /// No description provided for @picoViewOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open the LCD display.'**
  String get picoViewOpenFailed;

  /// No description provided for @picoViewUnauthorized.
  ///
  /// In en, this message translates to:
  /// **'This display is not a genuine device (or its firmware is too old), so it can\'t be used.'**
  String get picoViewUnauthorized;

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
