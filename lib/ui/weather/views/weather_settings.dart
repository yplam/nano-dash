import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nano_dash/l10n/app_localizations.dart';

import '../../../../data/services/location_service.dart';
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

  /// True while an IP-geolocation lookup is in flight, to disable the button and
  /// show a spinner in its place.
  bool _locating = false;

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

  /// Detect the city from the host's public IP and commit it. Unlike typing,
  /// this is an explicit action with no half-typed input to protect, so we skip
  /// the debounce and commit immediately.
  Future<void> _autoLocate() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final service = context.read<LocationService>();

    setState(() => _locating = true);
    try {
      final city = await service.currentCity();
      if (!mounted) return;
      _cityController.text = city;
      _debounce?.cancel();
      widget.onConfigChanged(WeatherConfig(city: city));
    } on LocationException {
      messenger
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(l10n.weatherLocationFailed)));
    } finally {
      if (mounted) setState(() => _locating = false);
    }
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
          suffixIcon: IconButton(
            tooltip: l10n.weatherUseMyLocation,
            onPressed: _locating ? null : _autoLocate,
            icon: _locating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location),
          ),
        ),
        onChanged: (_) => _emit(),
      ),
    );
  }
}
