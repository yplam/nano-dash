import 'package:dio/dio.dart';

import '../../../domain/models/radar.dart';

/// Thrown when a flight fetch can't complete.
class RadarFlightException implements Exception {
  RadarFlightException(this.message);

  final String message;

  @override
  String toString() => 'RadarFlightException: $message';
}

/// Fetches live aircraft around a point from the free, keyless readsb `/v2/point`
/// feeds ([RadarFlightSource.adsbLol] / [RadarFlightSource.airplanesLive]).
class RadarFlightService {
  RadarFlightService(this._dio);

  final Dio _dio;

  /// The point query's radius is expressed in nautical miles and capped by the
  /// providers at 250 nm.
  static const double _maxRadiusNm = 250;

  /// Aircraft within [rangeKm] of ([lat], [lon]) from [source]. Aircraft on the
  /// ground or without a position are skipped.
  Future<List<Aircraft>> fetch({
    required double lat,
    required double lon,
    required double rangeKm,
    required RadarFlightSource source,
  }) async {
    final radiusNm = (rangeKm / 1.852).clamp(1.0, _maxRadiusNm);
    final uri = Uri.https(
      source.host,
      '/v2/point/${lat.toStringAsFixed(4)}/${lon.toStringAsFixed(4)}/'
      '${radiusNm.toStringAsFixed(0)}',
    );

    final Response<Object?> res;
    try {
      res = await _dio.getUri<Object?>(uri);
    } on DioException catch (e) {
      throw RadarFlightException('Flight fetch failed: ${e.message}');
    }

    final data = res.data;
    final map = data is Map ? Map<String, Object?>.from(data) : null;
    if (map == null) {
      throw RadarFlightException('Unexpected response from $uri');
    }

    // `now` is epoch milliseconds; combined with each aircraft's `seen` (age in
    // seconds) it reconstructs an absolute last-contact time.
    final nowSec = (map['now'] as num?) != null
        ? (map['now'] as num) / 1000.0
        : DateTime.now().millisecondsSinceEpoch / 1000.0;

    final list = map['ac'];
    if (list is! List) return const [];

    final out = <Aircraft>[];
    for (final raw in list) {
      if (raw is! Map) continue;
      final ac = Map<String, Object?>.from(raw);

      final acLat = (ac['lat'] as num?)?.toDouble();
      final acLon = (ac['lon'] as num?)?.toDouble();
      if (acLat == null || acLon == null) continue;

      // `alt_baro` is a number in feet, or the string "ground" for a taxiing
      // aircraft — skip the latter (and anything non-numeric).
      final altRaw = ac['alt_baro'];
      if (altRaw is! num) continue;
      final altitudeM = altRaw.toDouble() * 0.3048;

      final gsKt = (ac['gs'] as num?)?.toDouble();
      final baroRate = (ac['baro_rate'] as num?)?.toDouble();
      final seen = (ac['seen'] as num?)?.toDouble() ?? 0;

      out.add(
        Aircraft(
          hex: (ac['hex'] as String?)?.trim() ?? '',
          callsign: (ac['flight'] as String?)?.trim() ?? '',
          lat: acLat,
          lon: acLon,
          track: (ac['track'] as num?)?.toDouble(),
          velocityMps: gsKt == null ? null : gsKt * 0.514444,
          altitudeM: altitudeM,
          verticalRateMps: baroRate == null ? null : baroRate * 0.00508,
          lastContact: (nowSec - seen).round(),
        ),
      );
    }
    return out;
  }
}
