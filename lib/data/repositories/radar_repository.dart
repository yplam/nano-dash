import 'dart:ui' as ui;

import '../../domain/models/radar.dart';
import '../services/radar/base_map_service.dart';
import '../services/radar/radar_flight_service.dart';
import '../services/radar/rain_radar_service.dart';
import 'settings_repository.dart';

/// Owns the radar module's data: it persists [RadarConfig] through
/// [SettingsRepository] and fetches live aircraft ([RadarFlightService]), the
/// rain overlay ([RainRadarService]) and the basemap ([BaseMapService]), caching
/// the last good snapshots.
class RadarRepository {
  RadarRepository(this._settings, this._flights, this._rain, this._baseMap)
    : _config = _settings.load(radarSettingsKey);

  final SettingsRepository _settings;
  final RadarFlightService _flights;
  final RainRadarService _rain;
  final BaseMapService _baseMap;

  RadarConfig _config;
  List<Aircraft> _aircraft = const [];
  DateTime? _aircraftAt;

  /// Per-aircraft position trails, keyed by ICAO hex, built up from successive
  /// polls (the feed itself carries no history). Bounded per aircraft and
  /// pruned once a target has been gone from the scope for [_trailTtl].
  final Map<String, List<TrailPoint>> _trails = {};
  final Map<String, DateTime> _trailSeen = {};

  /// Cap on stored points per aircraft: at [RadarConfig.pollSeconds] cadence
  /// this is roughly the last ten minutes of track.
  static const int _maxTrailPoints = 60;

  /// How long a vanished aircraft's trail is kept before it's dropped.
  static const Duration _trailTtl = Duration(minutes: 5);

  /// The current persisted settings.
  RadarConfig get config => _config;

  /// The last successfully fetched aircraft list.
  List<Aircraft> get aircraft => _aircraft;

  /// When [aircraft] was fetched, or null if never.
  DateTime? get aircraftAt => _aircraftAt;

  /// All accumulated position trails, keyed by ICAO hex, each oldest fix first.
  /// The map is the live store (pruned as aircraft leave the scope); callers
  /// must not mutate it.
  Map<String, List<TrailPoint>> get trails => _trails;

  Future<void> save(RadarConfig config) {
    _config = config;
    return _settings.save(radarSettingsKey, config);
  }

  Future<List<Aircraft>> fetchAircraft() async {
    final c = _config;
    final data = await _flights.fetch(
      lat: c.centerLat,
      lon: c.centerLon,
      rangeKm: c.rangeKm,
      source: c.flightSource,
    );
    _aircraft = data;
    _aircraftAt = DateTime.now();
    _accumulateTrails(data);
    return data;
  }

  /// Append each aircraft's new fix to its trail (skipping unmoved reports),
  /// then drop trails for targets that have left the scope.
  void _accumulateTrails(List<Aircraft> data) {
    final now = DateTime.now();
    for (final ac in data) {
      if (ac.hex.isEmpty) continue;
      final points = _trails.putIfAbsent(ac.hex, () => <TrailPoint>[]);
      final last = points.isEmpty ? null : points.last;
      if (last == null || last.lat != ac.lat || last.lon != ac.lon) {
        points.add(TrailPoint(lat: ac.lat, lon: ac.lon));
        if (points.length > _maxTrailPoints) points.removeAt(0);
      }
      _trailSeen[ac.hex] = now;
    }
    _trailSeen.removeWhere((hex, seenAt) {
      final expired = now.difference(seenAt) > _trailTtl;
      if (expired) _trails.remove(hex);
      return expired;
    });
  }

  Future<RainResult?> fetchRain({required int side}) {
    final c = _config;
    return _rain.fetch(
      lat: c.centerLat,
      lon: c.centerLon,
      rangeKm: c.rangeKm,
      side: side,
    );
  }

  Future<ui.Image?> fetchBaseMap({required int side}) {
    final c = _config;
    return _baseMap.fetch(
      lat: c.centerLat,
      lon: c.centerLon,
      rangeKm: c.rangeKm,
      side: side,
      source: c.mapSource,
      apiKey: c.tiandituKey,
    );
  }
}
