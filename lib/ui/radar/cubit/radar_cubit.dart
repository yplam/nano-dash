import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/radar_repository.dart';
import '../../../data/services/location_service.dart';
import '../../../domain/models/radar.dart';
import '../../../extensions/loggable.dart';

part 'radar_state.dart';

/// Owns the radar module's state and drives the two independent polling loops:
/// live aircraft (on [RadarConfig.pollSeconds]) and the rain overlay (every
/// [_kRainInterval]). Each layer polls only while it's enabled.
class RadarCubit extends Cubit<RadarState> with Loggable {
  RadarCubit(this._repository, this._location)
    : super(RadarState(config: _repository.config)) {
    _init();
  }

  final RadarRepository _repository;
  final LocationService _location;

  /// RainViewer publishes a new frame roughly every 10 minutes; poll at half
  /// that so we pick it up promptly without hammering the API.
  static const Duration _kRainInterval = Duration(minutes: 5);

  /// The rain overlay is composited once at this fixed resolution; the view
  /// scales the resulting circular image into whatever the panel size is.
  static const int _kRainSide = 512;

  /// The basemap is composited once at this fixed resolution, like the rain
  /// overlay.
  static const int _kBaseMapSide = 512;

  Timer? _flightTimer;
  Timer? _rainTimer;

  int _flightRequestId = 0;
  int _rainRequestId = 0;
  int _baseMapRequestId = 0;

  /// The centre/range the current basemap was built for, so we only refetch it
  /// when the geography actually changes.
  String? _baseMapKey;

  @override
  String get logIdentifier => '[RadarCubit]';

  Future<void> _init() async {
    // First run with no centre yet: try to place the scope over the host's
    // approximate location before starting the loops.
    if (!state.config.hasLocation) {
      try {
        final at = await _location.currentLatLon();
        if (isClosed) return;
        final next = state.config.copyWith(
          centerLat: at.lat,
          centerLon: at.lon,
        );
        await _repository.save(next);
        if (isClosed) return;
        emit(state.copyWith(config: next));
      } on LocationException catch (e) {
        logWarning('initial auto-locate failed', error: e);
      }
    }
    _restartTimers();
  }

  /// Persist [config] and restart whichever loops its changes affect.
  Future<void> setConfig(RadarConfig config) async {
    if (config == state.config) return;
    emit(state.copyWith(config: config));
    try {
      await _repository.save(config);
    } catch (e, s) {
      logError('failed to persist radar settings', error: e, stackTrace: s);
    }
    _restartTimers();
  }

  /// Select the aircraft [hex] for inspection (route + label), or pass null to
  /// clear the current selection.
  void selectFlight(String? hex) {
    if (hex == null) {
      if (state.selectedHex == null) return;
      emit(state.copyWith(clearSelection: true));
      return;
    }
    if (hex == state.selectedHex) return;
    emit(state.copyWith(selectedHex: hex));
  }

  /// Auto-detect the scope centre from the host's public IP and commit it.
  Future<({double lat, double lon})> autoLocate() async {
    final at = await _location.currentLatLon();
    await setConfig(
      state.config.copyWith(centerLat: at.lat, centerLon: at.lon),
    );
    return at;
  }

  void _restartTimers() {
    _flightTimer?.cancel();
    _rainTimer?.cancel();

    final c = state.config;
    if (c.hasLocation) _fetchBaseMap();

    if (c.hasLocation && c.flightEnabled) {
      _fetchFlights();
      _flightTimer = Timer.periodic(
        const Duration(seconds: RadarConfig.pollSeconds),
        (_) => _fetchFlights(),
      );
    } else if (state.aircraft.isNotEmpty || state.selectedHex != null) {
      emit(
        state.copyWith(
          aircraft: const [],
          trails: const {},
          clearSelection: true,
        ),
      );
    }

    if (c.hasLocation && c.rainEnabled) {
      _fetchRain();
      _rainTimer = Timer.periodic(_kRainInterval, (_) => _fetchRain());
    } else if (state.rainImage != null) {
      _clearRain();
    }
  }

  Future<void> _fetchFlights() async {
    final id = ++_flightRequestId;
    emit(state.copyWith(loading: true, clearError: true));
    try {
      final data = await _repository.fetchAircraft();
      if (isClosed || id != _flightRequestId) return;
      emit(
        state.copyWith(
          aircraft: data,
          loading: false,
          updatedAt: DateTime.now(),
          clearError: true,
          // Snapshot the repo's live trail store so the view can draw every
          // on-scope flight's track; a fresh map so state stays comparable.
          trails: Map.of(_repository.trails),
        ),
      );
    } catch (e, s) {
      if (isClosed || id != _flightRequestId) return;
      logWarning('flight fetch failed', error: e, stackTrace: s);
      emit(state.copyWith(loading: false, error: e));
    }
  }

  Future<void> _fetchRain() async {
    final id = ++_rainRequestId;
    try {
      final result = await _repository.fetchRain(side: _kRainSide);
      if (isClosed || id != _rainRequestId) {
        result?.image.dispose();
        return;
      }
      if (result == null) return; // Keep the previous frame on a soft failure.
      final old = state.rainImage;
      emit(state.copyWith(rainImage: result.image, rainTime: result.time));
      old?.dispose();
    } catch (e, s) {
      logWarning('rain fetch failed', error: e, stackTrace: s);
    }
  }

  /// Fetch and cache the basemap. It only changes with centre/range/source, so
  /// skip the fetch when none of those moved since the current image was built.
  Future<void> _fetchBaseMap() async {
    final c = state.config;
    final key =
        '${c.centerLat},${c.centerLon},${c.rangeKm},'
        '${c.mapSource.name},${c.tiandituKey}';
    if (key == _baseMapKey && state.baseMapImage != null) return;

    final id = ++_baseMapRequestId;
    try {
      final image = await _repository.fetchBaseMap(side: _kBaseMapSide);
      if (isClosed || id != _baseMapRequestId) {
        image?.dispose();
        return;
      }
      if (image == null) return; // Keep the previous map on a soft failure.
      _baseMapKey = key;
      final old = state.baseMapImage;
      emit(state.copyWith(baseMapImage: image));
      old?.dispose();
    } catch (e, s) {
      logWarning('base map fetch failed', error: e, stackTrace: s);
    }
  }

  void _clearRain() {
    final old = state.rainImage;
    emit(state.copyWith(clearRain: true));
    old?.dispose();
  }

  @override
  Future<void> close() {
    _flightTimer?.cancel();
    _rainTimer?.cancel();
    state.rainImage?.dispose();
    state.baseMapImage?.dispose();
    return super.close();
  }
}
