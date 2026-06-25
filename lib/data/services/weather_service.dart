import '../../domain/models/weather.dart';
import 'http_client.dart';

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
  WeatherService(this._http);

  final AppHttpClient _http;

  static const String _geocodingHost = 'geocoding-api.open-meteo.com';
  static const String _forecastHost = 'api.open-meteo.com';
  static const String _airQualityHost = 'air-quality-api.open-meteo.com';

  /// How many days of daily forecast to request (today included).
  static const int _forecastDays = 3;

  /// Resolve [city] and return its current conditions, a [_forecastDays]-day
  /// forecast, and (best-effort) air quality. [language] steers the returned
  /// place name (and matching) for the geocoder.
  Future<WeatherData> fetch(String city, {String language = 'en'}) async {
    final place = await _geocode(city, language);

    // Run the forecast and air-quality lookups concurrently; air quality is
    // supplementary, so a failure there must not sink the whole fetch.
    final results = await Future.wait([
      _fetchForecast(place),
      _fetchAirQuality(place),
    ]);
    final forecast = results[0] as WeatherData;
    return forecast.copyWith(airQuality: results[1] as AirQuality?);
  }

  Future<WeatherData> _fetchForecast(_Place place) async {
    final forecast =
        await _http.getJson(
              Uri.https(_forecastHost, '/v1/forecast', {
                'latitude': '${place.latitude}',
                'longitude': '${place.longitude}',
                'current':
                    'temperature_2m,relative_humidity_2m,apparent_temperature,weather_code,wind_speed_10m,is_day',
                'daily':
                    'weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max',
                'forecast_days': '$_forecastDays',
                'timezone': 'auto',
              }),
            )
            as Map<String, Object?>;

    final current = forecast['current'] as Map<String, Object?>?;
    if (current == null) {
      throw WeatherException('No current weather for "${place.name}"');
    }

    return WeatherData(
      city: place.name,
      temperatureC: (current['temperature_2m'] as num).toDouble(),
      condition: _conditionFromCode((current['weather_code'] as num).toInt()),
      apparentTemperatureC: (current['apparent_temperature'] as num?)
          ?.toDouble(),
      humidity: (current['relative_humidity_2m'] as num?)?.round(),
      windSpeedKmh: (current['wind_speed_10m'] as num?)?.toDouble(),
      isDay: (current['is_day'] as num?)?.toInt() != 0,
      forecast: _parseDaily(forecast['daily'] as Map<String, Object?>?),
    );
  }

  /// Parse the parallel daily arrays into per-day records. Returns empty if the
  /// block is missing or malformed — the forecast is supplementary.
  static List<DailyForecast> _parseDaily(Map<String, Object?>? daily) {
    if (daily == null) return const [];
    final times = daily['time'] as List<Object?>?;
    final codes = daily['weather_code'] as List<Object?>?;
    final highs = daily['temperature_2m_max'] as List<Object?>?;
    final lows = daily['temperature_2m_min'] as List<Object?>?;
    final precip = daily['precipitation_probability_max'] as List<Object?>?;
    if (times == null || codes == null || highs == null || lows == null) {
      return const [];
    }

    final out = <DailyForecast>[];
    for (var i = 0; i < times.length; i++) {
      final date = DateTime.tryParse(times[i] as String? ?? '');
      if (date == null) continue;
      out.add(
        DailyForecast(
          date: date,
          condition: _conditionFromCode((codes[i] as num).toInt()),
          highC: (highs[i] as num).toDouble(),
          lowC: (lows[i] as num).toDouble(),
          precipitationProbability: (precip?[i] as num?)?.round(),
        ),
      );
    }
    return out;
  }

  /// Best-effort air-quality lookup. Returns `null` on any failure so the
  /// caller can still surface current conditions.
  Future<AirQuality?> _fetchAirQuality(_Place place) async {
    try {
      final res =
          await _http.getJson(
                Uri.https(_airQualityHost, '/v1/air-quality', {
                  'latitude': '${place.latitude}',
                  'longitude': '${place.longitude}',
                  'current': 'european_aqi,pm2_5,pm10',
                }),
              )
              as Map<String, Object?>;

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
    final geo =
        await _http.getJson(
              Uri.https(_geocodingHost, '/v1/search', {
                'name': city,
                'count': '1',
                'language': language,
                'format': 'json',
              }),
            )
            as Map<String, Object?>;

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
