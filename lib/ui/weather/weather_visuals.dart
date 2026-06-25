import 'package:flutter/material.dart';

import '../../domain/models/weather.dart';

/// An icon + tint chosen for a weather condition. Shared by the inline weather
/// readout and the analog clock's hourly ring so they stay visually consistent.
class WeatherVisual {
  const WeatherVisual(this.icon, this.color);

  final IconData icon;
  final Color color;
}

/// Map a [WeatherCondition] to an icon and tint. [isDay] only changes the clear
/// case (sun vs. moon); forecast hours that span both can pass any value.
WeatherVisual weatherVisual(WeatherCondition condition, {bool isDay = true}) {
  switch (condition) {
    case WeatherCondition.clear:
      return isDay
          ? const WeatherVisual(Icons.wb_sunny, Colors.amber)
          : const WeatherVisual(Icons.nightlight_round, Colors.indigoAccent);
    case WeatherCondition.partlyCloudy:
      return const WeatherVisual(Icons.wb_cloudy, Colors.blueGrey);
    case WeatherCondition.cloudy:
      return const WeatherVisual(Icons.cloud, Colors.blueGrey);
    case WeatherCondition.fog:
      return const WeatherVisual(Icons.foggy, Colors.blueGrey);
    case WeatherCondition.drizzle:
      return const WeatherVisual(Icons.grain, Colors.lightBlue);
    case WeatherCondition.rain:
      return const WeatherVisual(Icons.water_drop, Colors.lightBlue);
    case WeatherCondition.snow:
      return const WeatherVisual(Icons.ac_unit, Colors.lightBlueAccent);
    case WeatherCondition.thunderstorm:
      return const WeatherVisual(Icons.thunderstorm, Colors.deepPurpleAccent);
  }
}
