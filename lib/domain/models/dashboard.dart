import 'json_model.dart';

/// Settings for a single dashboard module. A plain JSON-friendly map so it can
/// be persisted as-is; modules own their keys.
typedef ModuleSettings = Map<String, Object?>;

/// How visible a module is on the LCD.
///
/// * [off] — not shown at all, and the voice assistant may not bring it up.
/// * [assistant] — kept out of the left/right carousel rotation, but the
///   assistant may show it on demand as a transient page (auto-returns to the
///   previous page).
/// * [carousel] — a normal carousel page the user swipes to; the assistant may
///   also jump straight to it.
enum ModuleVisibility {
  off,
  assistant,
  carousel;

  static ModuleVisibility fromName(String? name) {
    for (final v in ModuleVisibility.values) {
      if (v.name == name) return v;
    }
    return ModuleVisibility.off;
  }
}

/// Persisted configuration for one module instance. The position of a config
/// within the ordered list encodes its display order on the LCD.
class DashboardItemConfig implements JsonModel {
  const DashboardItemConfig({
    required this.moduleId,
    required this.visibility,
    this.settings = const {},
  });

  /// References [DashModule.id].
  final String moduleId;

  /// Where the module appears (or doesn't) on the LCD.
  final ModuleVisibility visibility;

  /// The module's persisted settings.
  final ModuleSettings settings;

  /// True when the module is a normal carousel page. Named [enabled] for
  /// continuity with the carousel-membership call sites (`pages`, `enabledItems`).
  bool get enabled => visibility == ModuleVisibility.carousel;

  /// True when the assistant is allowed to show the module — carousel pages and
  /// assistant-only pages, but not [ModuleVisibility.off].
  bool get assistantVisible => visibility != ModuleVisibility.off;

  DashboardItemConfig copyWith({
    ModuleVisibility? visibility,
    ModuleSettings? settings,
  }) {
    return DashboardItemConfig(
      moduleId: moduleId,
      visibility: visibility ?? this.visibility,
      settings: settings ?? this.settings,
    );
  }

  @override
  Map<String, Object?> toJson() => {
    'moduleId': moduleId,
    'visibility': visibility.name,
    // Kept for one release so an older build can still read the config after a
    // rollback; readers prefer `visibility` above.
    'enabled': enabled,
    'settings': settings,
  };

  factory DashboardItemConfig.fromJson(Map<String, Object?> json) {
    final rawSettings = json['settings'];
    // Prefer the tri-state `visibility`; fall back to the legacy boolean
    // `enabled` (true → carousel, false → off) for configs written before it.
    final rawVisibility = json['visibility'];
    final ModuleVisibility visibility;
    if (rawVisibility is String) {
      visibility = ModuleVisibility.fromName(rawVisibility);
    } else {
      visibility = (json['enabled'] as bool? ?? false)
          ? ModuleVisibility.carousel
          : ModuleVisibility.off;
    }
    return DashboardItemConfig(
      moduleId: json['moduleId'] as String,
      visibility: visibility,
      settings: rawSettings is Map
          ? Map<String, Object?>.from(rawSettings)
          : const {},
    );
  }
}

/// Persistence key for the dashboard config.
/// Read/written via `SettingsRepository.loadList`/`saveList`.
const dashboardConfigKey = 'dashboard_config_v1';
