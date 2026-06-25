import 'package:flutter/material.dart';
import 'package:nano_dash/l10n/app_localizations.dart';

import '../../../../domain/models/weather.dart';

/// Settings controls for the weather readout: the configured city and the
/// display unit. A pure widget — it owns no state beyond the in-progress text
/// edit, seeds itself from [initialConfig], and reports every change through
/// [onConfigChanged]. The owner (e.g. a `WeatherCubit`) persists and applies it.
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
  late bool _fahrenheit;

  @override
  void initState() {
    super.initState();
    _cityController = TextEditingController(text: widget.initialConfig.city);
    _fahrenheit = widget.initialConfig.fahrenheit;
  }

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

  void _emit() {
    widget.onConfigChanged(
      WeatherConfig(city: _cityController.text, fahrenheit: _fahrenheit),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
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
        ),
        RadioGroup<bool>(
          groupValue: _fahrenheit,
          onChanged: (v) {
            setState(() => _fahrenheit = v ?? false);
            _emit();
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<bool>(
                title: Text(l10n.weatherUnitsCelsius),
                value: false,
              ),
              RadioListTile<bool>(
                title: Text(l10n.weatherUnitsFahrenheit),
                value: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
