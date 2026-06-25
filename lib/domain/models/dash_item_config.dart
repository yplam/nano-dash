import 'dash_module.dart';
import 'json_model.dart';

/// Persisted configuration for one module instance. The position of a config
/// within the ordered list encodes its display order on the LCD.
class DashItemConfig implements JsonModel {
  const DashItemConfig({
    required this.moduleId,
    required this.enabled,
    this.settings = const {},
  });

  /// References [DashModule.id].
  final String moduleId;

  /// Whether the module is shown on the LCD.
  final bool enabled;

  /// The module's persisted settings.
  final DashSettings settings;

  DashItemConfig copyWith({bool? enabled, DashSettings? settings}) {
    return DashItemConfig(
      moduleId: moduleId,
      enabled: enabled ?? this.enabled,
      settings: settings ?? this.settings,
    );
  }

  @override
  Map<String, Object?> toJson() => {
    'moduleId': moduleId,
    'enabled': enabled,
    'settings': settings,
  };

  factory DashItemConfig.fromJson(Map<String, Object?> json) {
    final rawSettings = json['settings'];
    return DashItemConfig(
      moduleId: json['moduleId'] as String,
      enabled: json['enabled'] as bool? ?? false,
      settings: rawSettings is Map
          ? Map<String, Object?>.from(rawSettings)
          : const {},
    );
  }
}

/// Persistence key for the dashboard config (an ordered list of
/// [DashItemConfig]). Read/written via `SettingsRepository.loadList`/`saveList`.
const dashboardConfigKey = 'dashboard_config_v1';
