import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/weather_cubit.dart';
import '../weather_visuals.dart';

/// A compact current-conditions readout that renders purely from [WeatherCubit].
///
/// Laid out left-to-right: a condition icon on the left, temperature and
/// humidity stacked on the right. Designed to sit inline beneath other content
/// (e.g. the clock's time and date) rather than fill a card on its own.
class WeatherDisplay extends StatefulWidget {
  const WeatherDisplay({super.key});

  @override
  State<WeatherDisplay> createState() => _WeatherDisplayState();
}

class _WeatherDisplayState extends State<WeatherDisplay> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Feed the current locale to the cubit; this also kicks off the first fetch
    // and refetches when the locale changes.
    final language = Localizations.localeOf(context).languageCode;
    context.read<WeatherCubit>().setLanguage(language);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return BlocBuilder<WeatherCubit, WeatherState>(
      builder: (context, state) => _buildBody(context, colors, state),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ColorScheme colors,
    WeatherState state,
  ) {
    final data = state.data;
    // Nothing to show: no city, still loading, or the last fetch failed.
    if (data == null) return const SizedBox.shrink();

    final visual = weatherVisual(
      data.condition,
      isDay: data.isDay,
      brightness: Theme.of(context).brightness,
    );

    String temp(double celsius) => '${celsius.round()}';

    // The numbers carry the reading; the unit symbols sit smaller alongside.
    const unitStyle = TextStyle(fontSize: 13);
    final spans = <InlineSpan>[
      TextSpan(text: temp(data.temperatureC)),
      const TextSpan(text: '°C', style: unitStyle),
    ];
    if (data.humidity != null) {
      spans.add(const TextSpan(text: ' '));
      spans.add(TextSpan(text: '${data.humidity}'));
      spans.add(const TextSpan(text: '%', style: unitStyle));
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(visual.icon, color: visual.color, size: 32),
            const SizedBox(width: 8),
            Text.rich(
              TextSpan(children: spans),
              style: TextStyle(
                color: colors.onSurfaceVariant,
                fontSize: 24,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
