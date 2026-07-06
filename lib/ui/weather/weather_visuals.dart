import 'package:flutter/material.dart';

import '../../domain/models/weather.dart';

/// An icon + tint chosen for a weather condition. Shared by the inline weather
/// readout and the analog clock's hourly ring so they stay visually consistent.
class WeatherVisual {
  const WeatherVisual(this.icon, this.color);

  final IconData icon;
  final Color color;
}

/// Map a [WeatherCondition] to an icon and tint. The hue is semantic (it *is*
/// the condition cue), but the exact shade adapts to [brightness]: richer tones
/// on a light surface, more luminous ones on a dark surface.
///
/// [isDay] only changes the clear case (sun vs. moon); forecast hours that span
/// both can pass any value.
WeatherVisual weatherVisual(
  WeatherCondition condition, {
  bool isDay = true,
  Brightness brightness = Brightness.light,
}) {
  final dark = brightness == Brightness.dark;

  // For each condition, the first color reads on a light surface, the second on
  // a dark one.
  Color pick(Color onLight, Color onDark) => dark ? onDark : onLight;

  switch (condition) {
    case WeatherCondition.clear:
      return isDay
          ? WeatherVisual(
              Icons.wb_sunny,
              pick(Colors.amber.shade700, Colors.amber.shade300),
            )
          : WeatherVisual(
              Icons.nightlight_round,
              pick(Colors.indigo.shade400, Colors.indigo.shade200),
            );
    case WeatherCondition.partlyCloudy:
      return WeatherVisual(
        Icons.wb_cloudy,
        pick(Colors.blueGrey.shade500, Colors.blueGrey.shade200),
      );
    case WeatherCondition.cloudy:
      return WeatherVisual(
        Icons.cloud,
        pick(Colors.blueGrey.shade500, Colors.blueGrey.shade200),
      );
    case WeatherCondition.fog:
      return WeatherVisual(
        Icons.foggy,
        pick(Colors.blueGrey.shade400, Colors.blueGrey.shade200),
      );
    case WeatherCondition.drizzle:
      return WeatherVisual(
        Icons.grain,
        pick(Colors.lightBlue.shade600, Colors.lightBlue.shade200),
      );
    case WeatherCondition.rain:
      return WeatherVisual(
        Icons.water_drop,
        pick(Colors.lightBlue.shade700, Colors.lightBlue.shade200),
      );
    case WeatherCondition.snow:
      return WeatherVisual(
        Icons.ac_unit,
        pick(Colors.lightBlue.shade400, Colors.lightBlue.shade100),
      );
    case WeatherCondition.thunderstorm:
      return WeatherVisual(
        Icons.thunderstorm,
        pick(Colors.deepPurple.shade400, Colors.deepPurpleAccent.shade100),
      );
  }
}
