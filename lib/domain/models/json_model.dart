/// A model that can serialize itself to a JSON-encodable map.
///
/// Settings models implement this so [SettingsRepository] can persist any of
/// them generically — `save` only needs `toJson`, and a matching [SettingKey]
/// carries the `fromJson` back.
abstract interface class JsonModel {
  Map<String, Object?> toJson();
}

/// A typed handle for one persisted settings object: the [SharedPreferences]
/// key it lives under, how to rebuild it from JSON, and the value to use when
/// nothing has been stored yet.
///
/// Modules declare a `const` key next to their settings model; the repository
/// stays generic and never names a concrete type. The string [key] keeps its
/// version suffix (e.g. `weather_config_v1`), so each module migrates on its own.
class SettingKey<T extends JsonModel> {
  const SettingKey(this.key, this.fromJson, {required this.defaults});

  final String key;
  final T Function(Map<String, Object?> json) fromJson;
  final T defaults;
}
