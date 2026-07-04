import 'dart:ui' show Color;

import 'json_model.dart';

/// App-wide configuration.
class AppConfig implements JsonModel {
  const AppConfig({
    this.backgroundPath = '',
    this.localeTag = systemLocaleTag,
    this.themeSeed = defaultThemeSeed,
    this.lcdBrightness = defaultLcdBrightness,
    this.alertEffect = defaultAlertEffect,
  });

  /// [localeTag] value meaning "follow the operating system".
  static const String systemLocaleTag = 'system';

  static const int defaultThemeSeed = 0xFF3F51B5;

  /// LCD backlight range, matching the device's `SetParam.brightness`
  /// (0 = off … 255 = full). A ~10% floor keeps the panel from ever going
  /// fully dark; fresh installs start at ~80%.
  static const int minLcdBrightness = 26;
  static const int maxLcdBrightness = 255;
  static const int defaultLcdBrightness = 204;

  /// DRV2605L ROM waveform id played for alerts. Matches
  /// [AlertEffect.fallback] (a short click); see [AlertEffect] for the presets.
  static const int defaultAlertEffect = 1;

  static const String _kBackground = 'background';
  static const String _kLocale = 'locale';
  static const String _kThemeSeed = 'themeSeed';
  static const String _kLcdBrightness = 'lcdBrightness';
  static const String _kAlertEffect = 'alertEffect';

  /// Absolute path to the chosen background file, or empty to use the bundled `assets/bg.png`.
  final String backgroundPath;

  /// BCP-47 language tag, or [systemLocaleTag].
  final String localeTag;

  /// ARGB value of the theme seed colour.
  final int themeSeed;

  /// LCD backlight level sent to the panel, clamped to
  /// [[minLcdBrightness], [maxLcdBrightness]].
  final int lcdBrightness;

  /// DRV2605L ROM waveform id played for alerts (0 = none). One of the
  /// [AlertEffect] preset ids; sent verbatim as `HapticsPlay.effect`.
  final int alertEffect;

  Color get themeColor => Color(themeSeed);

  /// Whether the app should follow the OS language.
  bool get followsSystemLocale => localeTag == systemLocaleTag;

  factory AppConfig.fromJson(Map<String, Object?> json) => AppConfig(
    backgroundPath: json[_kBackground] as String? ?? '',
    localeTag: json[_kLocale] as String? ?? systemLocaleTag,
    themeSeed: json[_kThemeSeed] as int? ?? defaultThemeSeed,
    lcdBrightness: _clampBrightness(
      json[_kLcdBrightness] as int? ?? defaultLcdBrightness,
    ),
    alertEffect: json[_kAlertEffect] as int? ?? defaultAlertEffect,
  );

  @override
  Map<String, Object?> toJson() => {
    _kBackground: backgroundPath,
    _kLocale: localeTag,
    _kThemeSeed: themeSeed,
    _kLcdBrightness: lcdBrightness,
    _kAlertEffect: alertEffect,
  };

  AppConfig copyWith({
    String? backgroundPath,
    String? localeTag,
    int? themeSeed,
    int? lcdBrightness,
    int? alertEffect,
  }) => AppConfig(
    backgroundPath: backgroundPath ?? this.backgroundPath,
    localeTag: localeTag ?? this.localeTag,
    themeSeed: themeSeed ?? this.themeSeed,
    lcdBrightness: lcdBrightness == null
        ? this.lcdBrightness
        : _clampBrightness(lcdBrightness),
    alertEffect: alertEffect ?? this.alertEffect,
  );

  static int _clampBrightness(int value) =>
      value.clamp(minLcdBrightness, maxLcdBrightness);

  @override
  bool operator ==(Object other) =>
      other is AppConfig &&
      other.backgroundPath == backgroundPath &&
      other.localeTag == localeTag &&
      other.themeSeed == themeSeed &&
      other.lcdBrightness == lcdBrightness &&
      other.alertEffect == alertEffect;

  @override
  int get hashCode => Object.hash(
    backgroundPath,
    localeTag,
    themeSeed,
    lcdBrightness,
    alertEffect,
  );
}

/// Persistence handle for [AppConfig].
const appConfigKey = SettingKey<AppConfig>(
  'app_config_v1',
  AppConfig.fromJson,
  defaults: AppConfig(),
);
