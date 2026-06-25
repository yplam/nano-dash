import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../data/repositories/weather_repository.dart';
import '../../../../domain/models/weather.dart';
import '../../../../extensions/loggable.dart';

part 'weather_state.dart';

/// Owns the weather widget's settings state (city + display unit) and drives
/// polling: it restores and persists settings through [WeatherRepository],
/// fetches current conditions through it on a timer, and caches the last good
/// result in state. The module renders purely from [WeatherState].
class WeatherCubit extends Cubit<WeatherState> with Loggable {
  WeatherCubit(this._repository) : super(_restore(_repository)) {
    _fetch();
    _timer = Timer.periodic(_kRefreshInterval, (_) => _fetch());
  }

  final WeatherRepository _repository;

  /// How often to re-poll current conditions. Open-Meteo updates roughly every
  /// 15 minutes, so anything tighter just wastes requests.
  static const Duration _kRefreshInterval = Duration(minutes: 15);

  Timer? _timer;

  /// The geocoding/place-name language, supplied by the view from the current
  /// locale. `null` until the first [setLanguage], which triggers the initial
  /// fetch.
  String? _language;

  /// Guards against a slow in-flight fetch (e.g. for an old city) overwriting a
  /// newer one's result. Each fetch captures this; only the latest applies.
  int _requestId = 0;

  @override
  String get logIdentifier => '[WeatherCubit]';

  static WeatherState _restore(WeatherRepository repository) {
    final config = repository.config;
    return WeatherState(city: config.city, fahrenheit: config.fahrenheit);
  }

  /// Set the language used for geocoding and the returned place name. Called by
  /// the view with the current locale; drives the initial load and refetches
  /// whenever the locale changes.
  void setLanguage(String language) {
    if (language == _language) return;
    _language = language;
    _fetch();
  }

  /// Update the configured city, persist it, and refetch. An empty value falls
  /// back to [kDefaultCity].
  void setCity(String city) {
    final trimmed = city.trim();
    final next = trimmed.isEmpty ? WeatherConfig.defaultCity : trimmed;
    if (next == state.city) return;
    emit(state.copyWith(city: next));
    _persist();
    _fetch();
  }

  /// Toggle the display unit. Display-only: the cached data is always Celsius,
  /// so no refetch is needed.
  void setFahrenheit(bool fahrenheit) {
    if (fahrenheit == state.fahrenheit) return;
    emit(state.copyWith(fahrenheit: fahrenheit));
    _persist();
  }

  Future<void> _fetch() async {
    final language = _language ?? 'en';
    final city = state.city;
    final id = ++_requestId;
    emit(state.copyWith(loading: true));
    try {
      final data = await _repository.fetch(city, language: language);
      if (isClosed || id != _requestId) return;
      emit(state.copyWith(data: data, loading: false));
    } catch (e, s) {
      if (isClosed || id != _requestId) return;
      logWarning('fetch failed for "$city"', error: e, stackTrace: s);
      emit(state.copyWith(loading: false));
    }
  }

  void _persist() {
    _repository
        .save(WeatherConfig(city: state.city, fahrenheit: state.fahrenheit))
        .catchError((Object e, StackTrace s) {
          logError(
            'failed to persist weather settings',
            error: e,
            stackTrace: s,
          );
        });
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
