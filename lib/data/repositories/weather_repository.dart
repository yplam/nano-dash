import '../../domain/models/weather.dart';
import '../services/weather_service.dart';
import 'settings_repository.dart';

/// Owns the weather widget's data: it persists the user [WeatherConfig] (city +
/// display unit) through [SettingsRepository] and fetches current conditions
/// through [WeatherService], caching the last good snapshot.
class WeatherRepository {
  WeatherRepository(this._settings, this._service)
    : _config = _settings.load(weatherSettingsKey);

  final SettingsRepository _settings;
  final WeatherService _service;

  WeatherConfig _config;
  WeatherData? _current;
  DateTime? _fetchedAt;

  /// The current persisted settings.
  WeatherConfig get config => _config;

  /// The last successfully fetched conditions, or `null` until the first fetch succeeds.
  WeatherData? get current => _current;

  /// When [current] was fetched, or `null` if nothing has been fetched. Used to
  /// stamp the freshness of the cached snapshot fed to the voice agent.
  DateTime? get fetchedAt => _fetchedAt;

  Future<void> save(WeatherConfig config) {
    _config = config;
    return _settings.save(weatherSettingsKey, config);
  }

  Future<WeatherData> fetch(String city, {String language = 'en'}) async {
    final data = await _service.fetch(city, language: language);
    _current = data;
    _fetchedAt = DateTime.now();
    return data;
  }
}
