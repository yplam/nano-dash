import 'json_model.dart';

/// One broad weather condition, derived from the WMO weather-interpretation code
/// returned by the weather provider. Modules map this to an icon/label without
/// needing to know the raw code table.
enum WeatherCondition {
  clear,
  partlyCloudy,
  cloudy,
  fog,
  drizzle,
  rain,
  snow,
  thunderstorm,
}

/// A coarse air-quality band, derived from the European AQI returned by
/// Open-Meteo's air-quality API. Modules map this to a label/colour without
/// needing to know the numeric bands.
enum AirQualityLevel {
  good,
  fair,
  moderate,
  poor,
  veryPoor,
  extremelyPoor;

  /// Map a European AQI value to a band. See
  /// https://open-meteo.com/en/docs/air-quality-api for the 0–100+ scale.
  static AirQualityLevel fromEuropeanAqi(num aqi) {
    if (aqi <= 20) return AirQualityLevel.good;
    if (aqi <= 40) return AirQualityLevel.fair;
    if (aqi <= 60) return AirQualityLevel.moderate;
    if (aqi <= 80) return AirQualityLevel.poor;
    if (aqi <= 100) return AirQualityLevel.veryPoor;
    return AirQualityLevel.extremelyPoor;
  }
}

/// An air-quality reading for a place. [europeanAqi] drives [level]; the
/// particulate readings (µg/m³) are kept for callers that want detail.
class AirQuality {
  const AirQuality({
    required this.level,
    this.europeanAqi,
    this.pm2_5,
    this.pm10,
  });

  final AirQualityLevel level;
  final int? europeanAqi;
  final double? pm2_5;
  final double? pm10;

  /// A short English label for [level], used in plain-text summaries; the UI
  /// localizes the enum separately.
  String get levelLabel {
    switch (level) {
      case AirQualityLevel.good:
        return 'good';
      case AirQualityLevel.fair:
        return 'fair';
      case AirQualityLevel.moderate:
        return 'moderate';
      case AirQualityLevel.poor:
        return 'poor';
      case AirQualityLevel.veryPoor:
        return 'very poor';
      case AirQualityLevel.extremelyPoor:
        return 'extremely poor';
    }
  }
}

/// A current-conditions snapshot for a place. Temperature is always stored as
/// Celsius (the canonical unit); callers pick the display unit when formatting,
/// so a unit toggle never needs a refetch and a cached snapshot never goes
/// stale against the user's chosen unit.
class WeatherData {
  const WeatherData({
    required this.city,
    required this.temperatureC,
    required this.condition,
    this.apparentTemperatureC,
    this.humidity,
    this.windSpeedKmh,
    this.isDay = true,
    this.airQuality,
  });

  final String city;
  final double temperatureC;
  final WeatherCondition condition;

  /// The "feels like" temperature in Celsius, or `null` if not reported.
  final double? apparentTemperatureC;
  final int? humidity;
  final double? windSpeedKmh;
  final bool isDay;

  /// Air-quality reading, or `null` if the (best-effort) lookup didn't return
  /// one — it must never fail the current-conditions fetch.
  final AirQuality? airQuality;

  WeatherData copyWith({AirQuality? airQuality}) {
    return WeatherData(
      city: city,
      temperatureC: temperatureC,
      condition: condition,
      apparentTemperatureC: apparentTemperatureC,
      humidity: humidity,
      windSpeedKmh: windSpeedKmh,
      isDay: isDay,
      airQuality: airQuality ?? this.airQuality,
    );
  }

  /// A short, human-readable name for [condition] (factoring in [isDay] for
  /// clear skies). Used for plain-text summaries; the UI maps the enum to icons
  /// separately.
  String get conditionLabel {
    switch (condition) {
      case WeatherCondition.clear:
        return isDay ? 'clear sky' : 'clear night';
      case WeatherCondition.partlyCloudy:
        return 'partly cloudy';
      case WeatherCondition.cloudy:
        return 'cloudy';
      case WeatherCondition.fog:
        return 'fog';
      case WeatherCondition.drizzle:
        return 'drizzle';
      case WeatherCondition.rain:
        return 'rain';
      case WeatherCondition.snow:
        return 'snow';
      case WeatherCondition.thunderstorm:
        return 'thunderstorm';
    }
  }

  /// A one-line summary of these conditions, suitable for feeding to the chat
  /// agent as context. Temperatures are always Celsius.
  String summary() {
    String fmt(double c) => '${c.round()}°C';
    final parts = <String>[
      '$city: ${fmt(temperatureC)}',
      conditionLabel,
      if (apparentTemperatureC != null)
        'feels like ${fmt(apparentTemperatureC!)}',
      if (humidity != null) 'humidity $humidity%',
      if (windSpeedKmh != null) 'wind ${windSpeedKmh!.round()} km/h',
      if (airQuality != null) 'air quality ${airQuality!.levelLabel}',
    ];
    return parts.join(', ');
  }
}

class WeatherConfig implements JsonModel {
  const WeatherConfig({this.city = defaultCity});

  /// Used when nothing has been persisted yet and as the fallback for a blank city.
  static const String defaultCity = 'Guangzhou';

  final String city;

  WeatherConfig copyWith({String? city}) =>
      WeatherConfig(city: city ?? this.city);

  factory WeatherConfig.fromJson(Map<String, Object?> json) =>
      WeatherConfig(city: json['city'] as String? ?? defaultCity);

  @override
  Map<String, Object?> toJson() => {'city': city};

  @override
  bool operator ==(Object other) =>
      other is WeatherConfig && other.city == city;

  @override
  int get hashCode => city.hashCode;
}

/// Persistence handle for [WeatherConfig].
const weatherSettingsKey = SettingKey<WeatherConfig>(
  'weather_config_v1',
  WeatherConfig.fromJson,
  defaults: WeatherConfig(),
);
