import 'package:dio/dio.dart';

import '../../domain/models/weather.dart';

/// Thrown when the weather lookup can't complete (e.g. unknown city).
class WeatherException implements Exception {
  WeatherException(this.message);

  final String message;

  @override
  String toString() => 'WeatherException: $message';
}

/// Fetches live current weather from the free, key-less
/// [Open-Meteo](https://open-meteo.com) APIs: a geocoding lookup turns the city
/// name into coordinates, then a forecast call returns the current conditions.
class WeatherService {
  WeatherService(this._dio);

  final Dio _dio;

  Future<Map<String, Object?>> _getJson(Uri uri) async {
    final res = await _dio.getUri<Object?>(uri);
    final data = res.data;
    if (data is Map<String, Object?>) return data;
    if (data is Map) return Map<String, Object?>.from(data);
    throw WeatherException('Unexpected response from $uri');
  }

  static const String _geocodingHost = 'geocoding-api.open-meteo.com';
  static const String _forecastHost = 'api.open-meteo.com';
  static const String _airQualityHost = 'air-quality-api.open-meteo.com';

  /// Resolve [city] and return its current conditions and (best-effort) air
  /// quality.
  Future<WeatherData> fetch(String city, {String language = 'en'}) async {
    final place = await _geocode(city, language);

    final results = await Future.wait([
      _fetchForecast(place),
      _fetchAirQuality(place),
    ]);
    final forecast = results[0] as WeatherData;
    return forecast.copyWith(airQuality: results[1] as AirQuality?);
  }

  /// How many days of daily/hourly forecast to request.
  static const int _forecastDays = 7;

  Future<WeatherData> _fetchForecast(_Place place) async {
    final forecast = await _getJson(
      Uri.https(_forecastHost, '/v1/forecast', {
        'latitude': '${place.latitude}',
        'longitude': '${place.longitude}',
        'current':
            'temperature_2m,relative_humidity_2m,apparent_temperature,weather_code,wind_speed_10m,is_day',
        'hourly':
            'temperature_2m,weather_code,precipitation_probability,is_day',
        'daily':
            'weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max,sunrise,sunset',
        'forecast_days': '$_forecastDays',
        'timezone': 'auto',
      }),
    );

    final current = forecast['current'] as Map<String, Object?>?;
    if (current == null) {
      throw WeatherException('No current weather for "${place.name}"');
    }

    // The provider stamps `current` with the panel-local time; use it as "now"
    // so we can trim the hourly series to upcoming hours.
    final now =
        DateTime.tryParse(current['time'] as String? ?? '') ?? DateTime.now();

    return WeatherData(
      city: place.name,
      temperatureC: (current['temperature_2m'] as num).toDouble(),
      condition: _conditionFromCode((current['weather_code'] as num).toInt()),
      apparentTemperatureC: (current['apparent_temperature'] as num?)
          ?.toDouble(),
      humidity: (current['relative_humidity_2m'] as num?)?.round(),
      windSpeedKmh: (current['wind_speed_10m'] as num?)?.toDouble(),
      isDay: (current['is_day'] as num?)?.toInt() != 0,
      hourly: _parseHourly(forecast['hourly'], now),
      daily: _parseDaily(forecast['daily']),
    );
  }

  /// Parse Open-Meteo's parallel-array `hourly` block, keeping only the entries
  /// from the current hour onward. Returns an empty list if the block is absent
  /// or malformed.
  static List<HourlyForecast> _parseHourly(Object? raw, DateTime now) {
    if (raw is! Map) return const [];
    final times = raw['time'] as List<Object?>?;
    final temps = raw['temperature_2m'] as List<Object?>?;
    final codes = raw['weather_code'] as List<Object?>?;
    final pops = raw['precipitation_probability'] as List<Object?>?;
    final days = raw['is_day'] as List<Object?>?;
    if (times == null || temps == null || codes == null) return const [];

    final cutoff = DateTime(now.year, now.month, now.day, now.hour);
    final out = <HourlyForecast>[];
    for (var i = 0; i < times.length; i++) {
      final t = DateTime.tryParse(times[i] as String? ?? '');
      final temp = (temps[i] as num?)?.toDouble();
      final code = (codes[i] as num?)?.toInt();
      if (t == null || t.isBefore(cutoff) || temp == null || code == null) {
        continue;
      }
      out.add(
        HourlyForecast(
          time: t,
          temperatureC: temp,
          condition: _conditionFromCode(code),
          isDay: (days?[i] as num?)?.toInt() != 0,
          precipitationProbability: (pops?[i] as num?)?.round(),
        ),
      );
    }
    return out;
  }

  /// Parse Open-Meteo's parallel-array `daily` block. Returns an empty list if
  /// the block is absent or malformed.
  static List<DailyForecast> _parseDaily(Object? raw) {
    if (raw is! Map) return const [];
    final times = raw['time'] as List<Object?>?;
    final codes = raw['weather_code'] as List<Object?>?;
    final maxes = raw['temperature_2m_max'] as List<Object?>?;
    final mins = raw['temperature_2m_min'] as List<Object?>?;
    final pops = raw['precipitation_probability_max'] as List<Object?>?;
    final sunrises = raw['sunrise'] as List<Object?>?;
    final sunsets = raw['sunset'] as List<Object?>?;
    if (times == null || codes == null || maxes == null || mins == null) {
      return const [];
    }

    final out = <DailyForecast>[];
    for (var i = 0; i < times.length; i++) {
      final d = DateTime.tryParse(times[i] as String? ?? '');
      final code = (codes[i] as num?)?.toInt();
      final hi = (maxes[i] as num?)?.toDouble();
      final lo = (mins[i] as num?)?.toDouble();
      if (d == null || code == null || hi == null || lo == null) continue;
      out.add(
        DailyForecast(
          date: d,
          condition: _conditionFromCode(code),
          tempMaxC: hi,
          tempMinC: lo,
          precipitationProbability: (pops?[i] as num?)?.round(),
          sunrise: DateTime.tryParse(sunrises?[i] as String? ?? ''),
          sunset: DateTime.tryParse(sunsets?[i] as String? ?? ''),
        ),
      );
    }
    return out;
  }

  /// Best-effort air-quality lookup. Returns `null` on any failure so the
  /// caller can still surface current conditions.
  Future<AirQuality?> _fetchAirQuality(_Place place) async {
    try {
      final res = await _getJson(
        Uri.https(_airQualityHost, '/v1/air-quality', {
          'latitude': '${place.latitude}',
          'longitude': '${place.longitude}',
          'current': 'european_aqi,pm2_5,pm10',
        }),
      );

      final current = res['current'] as Map<String, Object?>?;
      final aqi = current?['european_aqi'] as num?;
      if (current == null || aqi == null) return null;
      return AirQuality(
        level: AirQualityLevel.fromEuropeanAqi(aqi),
        europeanAqi: aqi.round(),
        pm2_5: (current['pm2_5'] as num?)?.toDouble(),
        pm10: (current['pm10'] as num?)?.toDouble(),
      );
    } catch (_) {
      return null;
    }
  }

  Future<_Place> _geocode(String city, String language) async {
    final geo = await _getJson(
      Uri.https(_geocodingHost, '/v1/search', {
        'name': city,
        'count': '1',
        'language': language,
        'format': 'json',
      }),
    );

    final results = geo['results'] as List<Object?>?;
    if (results == null || results.isEmpty) {
      throw WeatherException('City not found: "$city"');
    }
    final first = results.first as Map<String, Object?>;
    return _Place(
      name: first['name'] as String? ?? city,
      latitude: (first['latitude'] as num).toDouble(),
      longitude: (first['longitude'] as num).toDouble(),
    );
  }

  /// Map a WMO weather-interpretation code to a coarse [WeatherCondition].
  /// See https://open-meteo.com/en/docs for the full table.
  static WeatherCondition _conditionFromCode(int code) {
    if (code == 0) return WeatherCondition.clear;
    if (code == 1 || code == 2) return WeatherCondition.partlyCloudy;
    if (code == 3) return WeatherCondition.cloudy;
    if (code == 45 || code == 48) return WeatherCondition.fog;
    if (code >= 51 && code <= 57) return WeatherCondition.drizzle;
    if ((code >= 61 && code <= 67) || (code >= 80 && code <= 82)) {
      return WeatherCondition.rain;
    }
    if ((code >= 71 && code <= 77) || (code >= 85 && code <= 86)) {
      return WeatherCondition.snow;
    }
    if (code >= 95) return WeatherCondition.thunderstorm;
    return WeatherCondition.cloudy;
  }
}

class _Place {
  const _Place({
    required this.name,
    required this.latitude,
    required this.longitude,
  });

  final String name;
  final double latitude;
  final double longitude;
}
