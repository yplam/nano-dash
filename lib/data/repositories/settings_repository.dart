import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/json_model.dart';

/// The single persistence backend for every module's settings, over
/// [SharedPreferences]. Each settings object lives under its own key (a
/// [SettingKey]); this repository only encodes/decodes JSON and never names a
/// concrete settings type, so adding a module's settings means declaring a key
/// and a [JsonModel] — no new repository.
///
/// Replaces the former per-module repositories (agent/voice/dashboard); the one
/// key per module preserves their independent version suffixes and migration.
class SettingsRepository {
  const SettingsRepository(this._prefs);

  final SharedPreferences _prefs;

  /// Returns the stored value for [k], or [SettingKey.defaults] if nothing has
  /// been persisted yet (or the stored JSON isn't a map).
  T load<T extends JsonModel>(SettingKey<T> k) {
    final raw = _prefs.getString(k.key);
    if (raw == null) return k.defaults;
    final decoded = jsonDecode(raw);
    return decoded is Map
        ? k.fromJson(Map<String, Object?>.from(decoded))
        : k.defaults;
  }

  Future<void> save<T extends JsonModel>(SettingKey<T> k, T value) =>
      _prefs.setString(k.key, jsonEncode(value.toJson()));

  /// Returns the stored ordered list under [key], or an empty list if nothing
  /// has been persisted yet (or the stored JSON isn't a list). Used for the
  /// dashboard config, whose payload is a list rather than a single object.
  List<T> loadList<T extends JsonModel>(
    String key,
    T Function(Map<String, Object?> json) fromJson,
  ) {
    final raw = _prefs.getString(key);
    if (raw == null) return const [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];
    return decoded
        .whereType<Map>()
        .map((e) => fromJson(Map<String, Object?>.from(e)))
        .toList();
  }

  Future<void> saveList<T extends JsonModel>(String key, List<T> items) =>
      _prefs.setString(key, jsonEncode([for (final i in items) i.toJson()]));
}
