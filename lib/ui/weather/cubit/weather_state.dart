part of 'weather_cubit.dart';

/// View state for the weather widget.
class WeatherState {
  const WeatherState({
    required this.city,
    this.data,
    this.loading = false,
    this.error,
  });

  final String city;
  final WeatherData? data;
  final bool loading;

  /// The error from the most recent failed fetch, or `null` if the last fetch
  /// succeeded (or none has been attempted). Each failure carries a fresh
  /// instance so listeners can tell one failure from the next.
  final Object? error;

  WeatherState copyWith({
    String? city,
    WeatherData? data,
    bool clearData = false,
    bool? loading,
    Object? error,
    bool clearError = false,
  }) {
    return WeatherState(
      city: city ?? this.city,
      data: clearData ? null : (data ?? this.data),
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}
