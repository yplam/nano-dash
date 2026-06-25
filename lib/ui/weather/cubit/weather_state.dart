part of 'weather_cubit.dart';

/// View state for the weather widget. [data] is the last good snapshot (kept on
/// screen across refreshes and failures); [loading] marks an in-flight fetch.
/// Temperature in [data] is always Celsius — [fahrenheit] only affects display.
class WeatherState {
  const WeatherState({
    required this.city,
    this.fahrenheit = false,
    this.data,
    this.loading = false,
  });

  final String city;
  final bool fahrenheit;
  final WeatherData? data;
  final bool loading;

  WeatherState copyWith({
    String? city,
    bool? fahrenheit,
    WeatherData? data,
    bool? loading,
  }) {
    return WeatherState(
      city: city ?? this.city,
      fahrenheit: fahrenheit ?? this.fahrenheit,
      data: data ?? this.data,
      loading: loading ?? this.loading,
    );
  }
}
