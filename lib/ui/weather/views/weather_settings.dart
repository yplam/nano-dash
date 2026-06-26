import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nano_dash/l10n/app_localizations.dart';

import '../../../../domain/models/weather.dart';

/// Settings controls for the weather readout: the configured city.
class WeatherSettings extends StatefulWidget {
  const WeatherSettings({
    super.key,
    required this.initialConfig,
    required this.onConfigChanged,
  });

  /// The settings to seed the controls with. Read once, in [initState]; later
  /// changes from the owner are ignored so they can't clobber in-progress edits.
  final WeatherConfig initialConfig;

  /// Called with the full updated config whenever the user edits a control.
  final ValueChanged<WeatherConfig> onConfigChanged;

  @override
  State<WeatherSettings> createState() => _WeatherSettingsState();
}

class _WeatherSettingsState extends State<WeatherSettings> {
  late final TextEditingController _cityController;

  /// Hold off committing the city until the user pauses typing, so we don't
  /// fetch (and report errors for) every half-typed city name.
  Timer? _debounce;
  static const Duration _debounceDelay = Duration(milliseconds: 600);

  @override
  void initState() {
    super.initState();
    _cityController = TextEditingController(text: widget.initialConfig.city);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _cityController.dispose();
    super.dispose();
  }

  void _emit() {
    _debounce?.cancel();
    _debounce = Timer(_debounceDelay, () {
      widget.onConfigChanged(WeatherConfig(city: _cityController.text));
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: TextField(
        controller: _cityController,
        decoration: InputDecoration(
          labelText: l10n.weatherCity,
          hintText: l10n.weatherCityHint,
          border: const OutlineInputBorder(),
        ),
        onChanged: (_) => _emit(),
      ),
    );
  }
}
