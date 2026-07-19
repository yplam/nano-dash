part of 'radar_cubit.dart';

/// View state for the radar module.
class RadarState {
  const RadarState({
    required this.config,
    this.aircraft = const [],
    this.baseMapImage,
    this.rainImage,
    this.rainTime,
    this.loading = false,
    this.error,
    this.updatedAt,
    this.selectedHex,
    this.trails = const {},
  });

  final RadarConfig config;
  final List<Aircraft> aircraft;

  /// ICAO hex of the aircraft the user long-pressed to inspect, or null when
  /// nothing is selected. The selected target is emphasised (its trail and
  /// glyph brighten while the rest dim) and shows its callsign/flight-level
  /// label.
  final String? selectedHex;

  /// Every aircraft's accumulated position trail, keyed by ICAO hex, each
  /// oldest fix first. Trails are drawn for all on-scope aircraft, coloured per
  /// flight; empty until history has built up.
  final Map<String, List<TrailPoint>> trails;

  /// The composited basemap (a circular image) drawn under everything, or null
  /// until it loads. Owned by the cubit, which disposes it.
  final ui.Image? baseMapImage;

  /// The composited rain overlay (a circular image), or null when the rain
  /// layer is off or hasn't loaded yet. Owned by the cubit, which disposes it.
  final ui.Image? rainImage;

  /// Capture time of [rainImage].
  final DateTime? rainTime;

  final bool loading;

  /// The most recent flight-fetch error, or null if the last one succeeded.
  final Object? error;

  /// When the aircraft list was last refreshed.
  final DateTime? updatedAt;

  RadarState copyWith({
    RadarConfig? config,
    List<Aircraft>? aircraft,
    ui.Image? baseMapImage,
    ui.Image? rainImage,
    bool clearRain = false,
    DateTime? rainTime,
    bool? loading,
    Object? error,
    bool clearError = false,
    DateTime? updatedAt,
    String? selectedHex,
    Map<String, List<TrailPoint>>? trails,
    bool clearSelection = false,
  }) {
    return RadarState(
      config: config ?? this.config,
      aircraft: aircraft ?? this.aircraft,
      baseMapImage: baseMapImage ?? this.baseMapImage,
      rainImage: clearRain ? null : (rainImage ?? this.rainImage),
      rainTime: clearRain ? null : (rainTime ?? this.rainTime),
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
      updatedAt: updatedAt ?? this.updatedAt,
      selectedHex: clearSelection ? null : (selectedHex ?? this.selectedHex),
      trails: trails ?? this.trails,
    );
  }
}
