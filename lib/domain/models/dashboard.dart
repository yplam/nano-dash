import 'json_model.dart';

/// Settings for a single dashboard module. A plain JSON-friendly map so it can
/// be persisted as-is; modules own their keys.
typedef ModuleSettings = Map<String, Object?>;

/// Persisted configuration for one module instance. The position of a config
/// within the ordered list encodes its display order on the LCD.
class DashboardItemConfig implements JsonModel {
  const DashboardItemConfig({
    required this.moduleId,
    required this.enabled,
    this.settings = const {},
  });

  /// References [DashModule.id].
  final String moduleId;

  /// Whether the module is shown on the LCD.
  final bool enabled;

  /// The module's persisted settings.
  final ModuleSettings settings;

  DashboardItemConfig copyWith({bool? enabled, ModuleSettings? settings}) {
    return DashboardItemConfig(
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

  factory DashboardItemConfig.fromJson(Map<String, Object?> json) {
    final rawSettings = json['settings'];
    return DashboardItemConfig(
      moduleId: json['moduleId'] as String,
      enabled: json['enabled'] as bool? ?? false,
      settings: rawSettings is Map
          ? Map<String, Object?>.from(rawSettings)
          : const {},
    );
  }
}

/// Persistence key for the dashboard config.
/// Read/written via `SettingsRepository.loadList`/`saveList`.
const dashboardConfigKey = 'dashboard_config_v1';
