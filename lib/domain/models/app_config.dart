import 'dart:ui' show Color;

import 'json_model.dart';

/// App-wide configuration.
class AppConfig implements JsonModel {
  const AppConfig({
    this.backgroundPath = '',
    this.localeTag = systemLocaleTag,
    this.themeSeed = defaultThemeSeed,
  });

  /// [localeTag] value meaning "follow the operating system".
  static const String systemLocaleTag = 'system';

  static const int defaultThemeSeed = 0xFF3F51B5;

  static const String _kBackground = 'background';
  static const String _kLocale = 'locale';
  static const String _kThemeSeed = 'themeSeed';

  /// Absolute path to the chosen background file, or empty to use the bundled `assets/bg.png`.
  final String backgroundPath;

  /// BCP-47 language tag, or [systemLocaleTag].
  final String localeTag;

  /// ARGB value of the theme seed colour.
  final int themeSeed;

  Color get themeColor => Color(themeSeed);

  /// Whether the app should follow the OS language.
  bool get followsSystemLocale => localeTag == systemLocaleTag;

  factory AppConfig.fromJson(Map<String, Object?> json) => AppConfig(
    backgroundPath: json[_kBackground] as String? ?? '',
    localeTag: json[_kLocale] as String? ?? systemLocaleTag,
    themeSeed: json[_kThemeSeed] as int? ?? defaultThemeSeed,
  );

  @override
  Map<String, Object?> toJson() => {
    _kBackground: backgroundPath,
    _kLocale: localeTag,
    _kThemeSeed: themeSeed,
  };

  AppConfig copyWith({
    String? backgroundPath,
    String? localeTag,
    int? themeSeed,
  }) => AppConfig(
    backgroundPath: backgroundPath ?? this.backgroundPath,
    localeTag: localeTag ?? this.localeTag,
    themeSeed: themeSeed ?? this.themeSeed,
  );

  @override
  bool operator ==(Object other) =>
      other is AppConfig &&
      other.backgroundPath == backgroundPath &&
      other.localeTag == localeTag &&
      other.themeSeed == themeSeed;

  @override
  int get hashCode => Object.hash(backgroundPath, localeTag, themeSeed);
}

/// Persistence handle for [AppConfig].
const appConfigKey = SettingKey<AppConfig>(
  'app_config_v1',
  AppConfig.fromJson,
  defaults: AppConfig(),
);
