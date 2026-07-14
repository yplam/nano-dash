import '../../domain/models/usage_monitor.dart';
import '../services/usage_monitor/usage_monitor_service.dart';
import 'settings_repository.dart';

/// Owns the usage monitor's persisted [UsageMonitorConfig] and the last fetched
/// snapshot, delegating the actual fetch to [UsageMonitorService].
class UsageMonitorRepository {
  UsageMonitorRepository(this._settings, this._service)
    : _config = _settings.load(usageMonitorSettingsKey);

  final SettingsRepository _settings;
  final UsageMonitorService _service;

  UsageMonitorConfig _config;
  List<UsageMonitorProviderData>? _current;

  /// The current persisted settings.
  UsageMonitorConfig get config => _config;

  /// The last fetched per-provider usage, or null until the first fetch.
  List<UsageMonitorProviderData>? get current => _current;

  Future<void> save(UsageMonitorConfig config) {
    _config = config;
    return _settings.save(usageMonitorSettingsKey, config);
  }

  Future<List<UsageMonitorProviderData>> fetch() async {
    final usage = await _service.fetch(_config);
    _current = usage;
    return usage;
  }
}
