import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../data/repositories/weather_repository.dart';
import '../../../../domain/models/weather.dart';
import '../../../../extensions/loggable.dart';

part 'weather_state.dart';

/// Owns the weather widget's settings state and drives polling.
class WeatherCubit extends Cubit<WeatherState> with Loggable {
  WeatherCubit(this._repository) : super(_restore(_repository)) {
    _fetch();
    _timer = Timer.periodic(_kRefreshInterval, (_) => _fetch());
  }

  final WeatherRepository _repository;

  /// How often to re-poll current conditions.
  static const Duration _kRefreshInterval = Duration(minutes: 15);

  Timer? _timer;

  String? _language;

  /// Guards against a slow in-flight fetch overwriting a newer one's result.
  int _requestId = 0;

  @override
  String get logIdentifier => '[WeatherCubit]';

  static WeatherState _restore(WeatherRepository repository) {
    return WeatherState(city: repository.config.city);
  }

  /// Set the language used for geocoding and the returned place name.
  void setLanguage(String language) {
    if (language == _language) return;
    _language = language;
    _fetch();
  }

  /// Update the configured city, persist it, and refetch. An empty city clears
  /// the readout and stops polling until a city is set again.
  void setCity(String city) {
    final next = city.trim();
    if (next == state.city) return;
    // The old city's data no longer applies; drop it (and any error) so the
    // view doesn't show stale conditions while the new city loads.
    emit(state.copyWith(city: next, clearData: true, clearError: true));
    _persist();
    _fetch();
  }

  Future<void> _fetch() async {
    final city = state.city.trim();
    // No city configured: nothing to fetch or display.
    if (city.isEmpty) {
      emit(state.copyWith(clearData: true, loading: false, clearError: true));
      return;
    }

    final language = _language ?? 'en';
    final id = ++_requestId;
    emit(state.copyWith(loading: true, clearError: true));
    try {
      final data = await _repository.fetch(city, language: language);
      if (isClosed || id != _requestId) return;
      emit(state.copyWith(data: data, loading: false, clearError: true));
    } catch (e, s) {
      if (isClosed || id != _requestId) return;
      logWarning('fetch failed for "$city"', error: e, stackTrace: s);
      emit(state.copyWith(loading: false, error: e));
    }
  }

  void _persist() {
    _repository.save(WeatherConfig(city: state.city)).catchError((
      Object e,
      StackTrace s,
    ) {
      logError('failed to persist weather settings', error: e, stackTrace: s);
    });
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
