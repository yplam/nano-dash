import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/models/dashboard.dart';
import '../../domain/models/module.dart';
import '../../domain/models/weather.dart';
import '../../l10n/app_localizations.dart';
import '../weather/weather.dart';

/// The full weather page: current conditions plus an hourly and multi-day forecast.
class WeatherModule extends Module {
  const WeatherModule();

  static const String kId = 'weather';

  @override
  String get id => kId;

  @override
  IconData get icon => Icons.cloud_outlined;

  @override
  String title(AppLocalizations l10n) => l10n.moduleWeatherTitle;

  @override
  bool get hasSettings => true;

  @override
  Widget build(BuildContext context, ModuleSettings settings) =>
      const WeatherDetailView();

  @override
  Widget buildSettings(
    BuildContext context,
    ModuleSettings settings,
    ValueChanged<ModuleSettings> onChanged,
  ) {
    final l10n = AppLocalizations.of(context);
    return BlocConsumer<WeatherCubit, WeatherState>(
      listenWhen: (prev, curr) =>
          curr.error != null && !identical(curr.error, prev.error),
      listener: (context, state) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(content: Text(l10n.weatherFetchFailed(state.city))),
          );
      },
      builder: (context, state) => WeatherSettings(
        initialConfig: WeatherConfig(city: state.city),
        onConfigChanged: (config) =>
            context.read<WeatherCubit>().setCity(config.city),
      ),
    );
  }
}
