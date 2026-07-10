import '../../domain/models/markets.dart';
import '../services/markets/markets_service.dart';
import 'settings_repository.dart';

class MarketsRepository {
  MarketsRepository(this._settings, this._service)
    : _config = _settings.load(marketsSettingsKey);

  final SettingsRepository _settings;
  final MarketsService _service;

  MarketsConfig _config;
  List<Quote>? _current;

  /// The current persisted settings.
  MarketsConfig get config => _config;

  /// The last successfully fetched quotes, or `null` until the first fetch succeeds.
  List<Quote>? get current => _current;

  Future<void> save(MarketsConfig config) {
    _config = config;
    return _settings.save(marketsSettingsKey, config);
  }

  Future<List<Quote>> fetch() async {
    final quotes = await _service.fetch(_config);
    _current = quotes;
    return quotes;
  }
}
