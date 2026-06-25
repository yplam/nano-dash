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

/// One day of forecast. Temperatures are Celsius (the canonical unit), matching
/// [WeatherData]; the display unit is applied at format time.
class DailyForecast {
  const DailyForecast({
    required this.date,
    required this.condition,
    required this.highC,
    required this.lowC,
    this.precipitationProbability,
  });

  final DateTime date;
  final WeatherCondition condition;
  final double highC;
  final double lowC;

  /// Max chance of precipitation for the day, in percent (0–100), or `null`.
  final int? precipitationProbability;

  /// A short, human-readable name for [condition]. Unlike
  /// [WeatherData.conditionLabel] there's no day/night split — a forecast day
  /// spans both.
  String get conditionLabel {
    switch (condition) {
      case WeatherCondition.clear:
        return 'clear';
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
    this.forecast = const [],
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

  /// Multi-day daily forecast (today first), or empty if none was requested.
  final List<DailyForecast> forecast;

  WeatherData copyWith({
    AirQuality? airQuality,
    List<DailyForecast>? forecast,
  }) {
    return WeatherData(
      city: city,
      temperatureC: temperatureC,
      condition: condition,
      apparentTemperatureC: apparentTemperatureC,
      humidity: humidity,
      windSpeedKmh: windSpeedKmh,
      isDay: isDay,
      airQuality: airQuality ?? this.airQuality,
      forecast: forecast ?? this.forecast,
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
  /// agent as context. [fahrenheit] selects the temperature unit; the stored
  /// value is always Celsius, so the caller passes the user's current
  /// preference at format time.
  String summary({bool fahrenheit = false}) {
    final unit = fahrenheit ? '°F' : '°C';
    String fmt(double c) => '${(fahrenheit ? c * 9 / 5 + 32 : c).round()}$unit';
    final parts = <String>[
      '$city: ${fmt(temperatureC)}',
      conditionLabel,
      if (apparentTemperatureC != null) 'feels like ${fmt(apparentTemperatureC!)}',
      if (humidity != null) 'humidity $humidity%',
      if (windSpeedKmh != null) 'wind ${windSpeedKmh!.round()} km/h',
      if (airQuality != null) 'air quality ${airQuality!.levelLabel}',
    ];
    var result = parts.join(', ');

    if (forecast.isNotEmpty) {
      const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      final days = forecast
          .map(
            (d) =>
                '${weekdays[d.date.weekday - 1]} ${d.conditionLabel} '
                '${fmt(d.highC)}/${fmt(d.lowC)}',
          )
          .join('; ');
      result = '$result. Forecast: $days';
    }
    return result;
  }
}

/// The weather readout's user settings: the place to look up and the display
/// unit. Persisted via [SettingsRepository] (under [weatherSettingsKey]) and
/// cached by `WeatherRepository`; edited through the settings widget.
class WeatherConfig implements JsonModel {
  const WeatherConfig({this.city = defaultCity, this.fahrenheit = false});

  /// Used when nothing has been persisted yet and as the fallback for a blank
  /// city.
  static const String defaultCity = 'Guangzhou';

  final String city;
  final bool fahrenheit;

  WeatherConfig copyWith({String? city, bool? fahrenheit}) => WeatherConfig(
    city: city ?? this.city,
    fahrenheit: fahrenheit ?? this.fahrenheit,
  );

  factory WeatherConfig.fromJson(Map<String, Object?> json) => WeatherConfig(
    city: json['city'] as String? ?? defaultCity,
    fahrenheit: json['fahrenheit'] == true,
  );

  @override
  Map<String, Object?> toJson() => {'city': city, 'fahrenheit': fahrenheit};

  @override
  bool operator ==(Object other) =>
      other is WeatherConfig &&
      other.city == city &&
      other.fahrenheit == fahrenheit;

  @override
  int get hashCode => Object.hash(city, fahrenheit);
}

/// Persistence handle for [WeatherConfig]. The `_v1` suffix matches the key the
/// former `WeatherRepository` storage used, so existing settings still load.
const weatherSettingsKey = SettingKey<WeatherConfig>(
  'weather_config_v1',
  WeatherConfig.fromJson,
  defaults: WeatherConfig(),
);
