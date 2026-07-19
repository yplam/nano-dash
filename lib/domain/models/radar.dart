import 'dart:math' as math;

import 'json_model.dart';

/// A live flight source. Both entries speak the keyless readsb `/v2/point`
/// dialect (same JSON shape, imperial units), differing only by host — so the
/// [RadarFlightService] treats them uniformly and just swaps the host.
enum RadarFlightSource {
  adsbLol('api.adsb.lol', 'adsb.lol'),
  airplanesLive('api.airplanes.live', 'airplanes.live');

  const RadarFlightSource(this.host, this.label);

  /// API host, e.g. `api.adsb.lol`.
  final String host;

  /// Short human label shown in the UI.
  final String label;

  static RadarFlightSource fromName(String? name) {
    for (final s in RadarFlightSource.values) {
      if (s.name == name) return s;
    }
    return RadarFlightSource.adsbLol;
  }
}

/// A basemap tile source for the radar scope. Each is a keyless public raster
/// provider except [tianditu], which needs a free API key (`tk`). [dark] tells
/// the view whether to scrim the map with a light or a dark overlay so the grid
/// and aircraft stay legible; [attribution] is the credit line drawn on the rim.
enum RadarMapSource {
  cartoDark('CARTO Dark', dark: true, attribution: '© OSM © CARTO'),
  cartoVoyager('CARTO Voyager', dark: false, attribution: '© OSM © CARTO'),
  openStreetMap('OpenStreetMap', dark: false, attribution: '© OpenStreetMap'),
  tianditu(
    '天地图',
    dark: false,
    attribution: '© 天地图',
    requiresKey: true,
  );

  const RadarMapSource(
    this.label, {
    required this.dark,
    required this.attribution,
    this.requiresKey = false,
  });

  /// Short human label shown in the UI.
  final String label;

  /// Whether the map is dark-on-light (`false`) or a dark map (`true`); picks the
  /// scrim tint so overlaid grid/aircraft stay readable.
  final bool dark;

  /// Credit line the scope renders on the rim.
  final String attribution;

  /// Whether the source needs a user-supplied API key (Tianditu).
  final bool requiresKey;

  static RadarMapSource fromName(String? name) {
    for (final s in RadarMapSource.values) {
      if (s.name == name) return s;
    }
    return RadarMapSource.cartoDark;
  }
}

/// One aircraft, in **metric** units regardless of the source (the readsb feeds
/// report imperial; the service converts on the way in so the UI is
/// source-agnostic, mirroring the ESP32 reference).
class Aircraft {
  const Aircraft({
    required this.hex,
    required this.callsign,
    required this.lat,
    required this.lon,
    this.track,
    this.velocityMps,
    this.altitudeM,
    this.verticalRateMps,
    this.lastContact,
  });

  /// ICAO 24-bit address (hex), the stable identifier for the target.
  final String hex;

  /// Trimmed callsign / flight number, or empty if the aircraft isn't
  /// broadcasting one.
  final String callsign;

  final double lat;
  final double lon;

  /// True track over ground, degrees clockwise from north.
  final double? track;

  /// Ground speed, m/s.
  final double? velocityMps;

  /// Barometric altitude, metres.
  final double? altitudeM;

  /// Vertical rate, m/s (positive = climbing).
  final double? verticalRateMps;

  /// Epoch seconds of the last position report; used to grey out stale targets.
  final int? lastContact;

  /// Flight level (hundreds of feet), e.g. `350` for FL350, or null if altitude
  /// is unknown.
  int? get flightLevel =>
      altitudeM == null ? null : (altitudeM! / 0.3048 / 100).round();

  /// Ground speed in knots, or null if unknown.
  int? get speedKt =>
      velocityMps == null ? null : (velocityMps! / 0.514444).round();

  /// Great-circle distance in km from ([lat0], [lon0]) using the haversine
  /// formula.
  double distanceKm(double lat0, double lon0) {
    const r = 6371.0088;
    final dLat = _rad(lat - lat0);
    final dLon = _rad(lon - lon0);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_rad(lat0)) *
            math.cos(_rad(lat)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  static double _rad(double deg) => deg * math.pi / 180;
}

/// One recorded position in an aircraft's accumulated trail. Points are stored
/// oldest-first, so a fading line can brighten toward the newest fix.
class TrailPoint {
  const TrailPoint({required this.lat, required this.lon});

  final double lat;
  final double lon;
}

/// A composited rain-radar snapshot: the frame's capture time. The pixels live
/// in a `ui.Image` held separately (it isn't JSON-serialisable and is rebuilt
/// each poll).
class RainSnapshot {
  const RainSnapshot({required this.time});

  final DateTime time;
}

/// Persisted radar settings: where the scope is centred, how far it reaches, and
/// which layers are on.
class RadarConfig implements JsonModel {
  const RadarConfig({
    this.centerLat = defaultLat,
    this.centerLon = defaultLon,
    this.rangeKm = defaultRangeKm,
    this.flightEnabled = true,
    this.flightSource = RadarFlightSource.adsbLol,
    this.rainEnabled = false,
    this.mapSource = RadarMapSource.cartoDark,
    this.tiandituKey = '',
  });

  /// Sentinel centre used before the user (or first-run IP auto-locate) picks a
  /// real one. `(0, 0)` is in the ocean off Africa, so it doubles as "unset".
  static const double defaultLat = 0;
  static const double defaultLon = 0;
  static const double defaultRangeKm = 180;

  /// Fixed flight poll cadence, in seconds. Not user-configurable: the keyless
  /// adsb.lol / airplanes.live community feeds ask clients not to poll faster
  /// than ~1/s, so 10 s stays polite while the scope still feels live (targets
  /// go stale after [pollSeconds] × 3).
  static const int pollSeconds = 10;

  /// Range clamps: the slider steps in [rangeStepKm] increments from
  /// [minRangeKm] to [maxRangeKm]. The readsb point query caps at 250 nm ≈
  /// 463 km, so 240 km stays well within range.
  static const double minRangeKm = 30;
  static const double maxRangeKm = 240;
  static const double rangeStepKm = 30;

  final double centerLat;
  final double centerLon;
  final double rangeKm;
  final bool flightEnabled;
  final RadarFlightSource flightSource;
  final bool rainEnabled;

  /// Which basemap provider tiles the scope.
  final RadarMapSource mapSource;

  /// API key for [RadarMapSource.tianditu]; empty for the keyless providers.
  final String tiandituKey;

  /// Whether a real centre has been set (not the `(0, 0)` sentinel).
  bool get hasLocation => centerLat != defaultLat || centerLon != defaultLon;

  RadarConfig copyWith({
    double? centerLat,
    double? centerLon,
    double? rangeKm,
    bool? flightEnabled,
    RadarFlightSource? flightSource,
    bool? rainEnabled,
    RadarMapSource? mapSource,
    String? tiandituKey,
  }) => RadarConfig(
    centerLat: centerLat ?? this.centerLat,
    centerLon: centerLon ?? this.centerLon,
    rangeKm: rangeKm ?? this.rangeKm,
    flightEnabled: flightEnabled ?? this.flightEnabled,
    flightSource: flightSource ?? this.flightSource,
    rainEnabled: rainEnabled ?? this.rainEnabled,
    mapSource: mapSource ?? this.mapSource,
    tiandituKey: tiandituKey ?? this.tiandituKey,
  );

  factory RadarConfig.fromJson(Map<String, Object?> json) => RadarConfig(
    centerLat: (json['centerLat'] as num?)?.toDouble() ?? defaultLat,
    centerLon: (json['centerLon'] as num?)?.toDouble() ?? defaultLon,
    rangeKm: (json['rangeKm'] as num?)?.toDouble() ?? defaultRangeKm,
    flightEnabled: json['flightEnabled'] as bool? ?? true,
    flightSource: RadarFlightSource.fromName(json['flightSource'] as String?),
    rainEnabled: json['rainEnabled'] as bool? ?? false,
    mapSource: RadarMapSource.fromName(json['mapSource'] as String?),
    tiandituKey: json['tiandituKey'] as String? ?? '',
  );

  @override
  Map<String, Object?> toJson() => {
    'centerLat': centerLat,
    'centerLon': centerLon,
    'rangeKm': rangeKm,
    'flightEnabled': flightEnabled,
    'flightSource': flightSource.name,
    'rainEnabled': rainEnabled,
    'mapSource': mapSource.name,
    'tiandituKey': tiandituKey,
  };

  @override
  bool operator ==(Object other) =>
      other is RadarConfig &&
      other.centerLat == centerLat &&
      other.centerLon == centerLon &&
      other.rangeKm == rangeKm &&
      other.flightEnabled == flightEnabled &&
      other.flightSource == flightSource &&
      other.rainEnabled == rainEnabled &&
      other.mapSource == mapSource &&
      other.tiandituKey == tiandituKey;

  @override
  int get hashCode => Object.hash(
    centerLat,
    centerLon,
    rangeKm,
    flightEnabled,
    flightSource,
    rainEnabled,
    mapSource,
    tiandituKey,
  );
}

/// Persistence handle for [RadarConfig].
const radarSettingsKey = SettingKey<RadarConfig>(
  'radar_config_v1',
  RadarConfig.fromJson,
  defaults: RadarConfig(),
);
