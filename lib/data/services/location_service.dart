import 'package:dio/dio.dart';

/// Thrown when the host's approximate location can't be determined.
class LocationException implements Exception {
  LocationException(this.message);

  final String message;

  @override
  String toString() => 'LocationException: $message';
}

/// Resolves the host's approximate location from its public IP address.
///
/// Desktop platforms have no reliable GPS, and Flutter's `geolocator` plugin
/// doesn't support Linux at all. An IP lookup needs no native plugin, no OS
/// permission prompt, and returns a city name directly — which is exactly the
/// shape [WeatherConfig] stores, so the result drops straight into the existing
/// city-keyed weather pipeline. Accuracy is only city-level (and can be wrong
/// behind a VPN), so callers should treat it as a convenience, not ground truth.
class LocationService {
  LocationService(this._dio);

  final Dio _dio;

  /// Keyless, no-signup IP geolocation. Returns `{ success, city, ... }`.
  static const String _host = 'ipwho.is';

  /// The current city name for this host's public IP. Throws
  /// [LocationException] if the lookup fails or returns no city.
  Future<String> currentCity() async {
    final Response<Object?> res;
    try {
      res = await _dio.getUri<Object?>(Uri.https(_host, '/'));
    } on DioException catch (e) {
      throw LocationException('Location lookup failed: ${e.message}');
    }

    final data = res.data;
    final map = data is Map ? Map<String, Object?>.from(data) : null;
    // ipwho.is always returns 200; failures are flagged by `success: false`.
    if (map == null || map['success'] == false) {
      throw LocationException('Location lookup returned no result');
    }
    final city = (map['city'] as String?)?.trim();
    if (city == null || city.isEmpty) {
      throw LocationException('Location lookup returned no city');
    }
    return city;
  }

  /// The approximate latitude/longitude for this host's public IP.
  Future<({double lat, double lon})> currentLatLon() async {
    final Response<Object?> res;
    try {
      res = await _dio.getUri<Object?>(Uri.https(_host, '/'));
    } on DioException catch (e) {
      throw LocationException('Location lookup failed: ${e.message}');
    }

    final data = res.data;
    final map = data is Map ? Map<String, Object?>.from(data) : null;
    if (map == null || map['success'] == false) {
      throw LocationException('Location lookup returned no result');
    }
    final lat = (map['latitude'] as num?)?.toDouble();
    final lon = (map['longitude'] as num?)?.toDouble();
    if (lat == null || lon == null) {
      throw LocationException('Location lookup returned no coordinates');
    }
    return (lat: lat, lon: lon);
  }
}
