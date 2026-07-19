import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/services/location_service.dart';
import '../../../domain/models/radar.dart';
import '../../../l10n/app_localizations.dart';

/// Settings for the radar module: scope centre + range, and which layers (live
/// flights, rain) are on.
class RadarSettings extends StatefulWidget {
  const RadarSettings({
    super.key,
    required this.initialConfig,
    required this.onConfigChanged,
  });

  /// Seed for the controls. Read once in [initState]; later owner changes are
  /// ignored so they can't clobber in-progress edits.
  final RadarConfig initialConfig;

  /// Called with the full updated config whenever a control changes.
  final ValueChanged<RadarConfig> onConfigChanged;

  @override
  State<RadarSettings> createState() => _RadarSettingsState();
}

class _RadarSettingsState extends State<RadarSettings> {
  late RadarConfig _config;
  late final TextEditingController _latController;
  late final TextEditingController _lonController;
  late final TextEditingController _keyController;

  Timer? _debounce;
  Timer? _keyDebounce;
  static const Duration _debounceDelay = Duration(milliseconds: 600);

  bool _locating = false;

  @override
  void initState() {
    super.initState();
    _config = widget.initialConfig;
    _latController = TextEditingController(
      text: _config.hasLocation ? _config.centerLat.toStringAsFixed(4) : '',
    );
    _lonController = TextEditingController(
      text: _config.hasLocation ? _config.centerLon.toStringAsFixed(4) : '',
    );
    _keyController = TextEditingController(text: _config.tiandituKey);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _keyDebounce?.cancel();
    _latController.dispose();
    _lonController.dispose();
    _keyController.dispose();
    super.dispose();
  }

  /// Commit [next] immediately (for switches/sliders/segments).
  void _commit(RadarConfig next) {
    setState(() => _config = next);
    widget.onConfigChanged(next);
  }

  /// Parse the lat/lon fields and commit after a pause (for typing).
  void _commitCoordsDebounced() {
    _debounce?.cancel();
    _debounce = Timer(_debounceDelay, () {
      final lat = double.tryParse(_latController.text.trim());
      final lon = double.tryParse(_lonController.text.trim());
      if (lat == null || lon == null) return;
      if (lat.abs() > 90 || lon.abs() > 180) return;
      _commit(_config.copyWith(centerLat: lat, centerLon: lon));
    });
  }

  /// Commit the Tianditu API key after a pause (for typing).
  void _commitKeyDebounced() {
    _keyDebounce?.cancel();
    _keyDebounce = Timer(_debounceDelay, () {
      _commit(_config.copyWith(tiandituKey: _keyController.text.trim()));
    });
  }

  Future<void> _autoLocate() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final service = context.read<LocationService>();

    setState(() => _locating = true);
    try {
      final at = await service.currentLatLon();
      if (!mounted) return;
      _latController.text = at.lat.toStringAsFixed(4);
      _lonController.text = at.lon.toStringAsFixed(4);
      _debounce?.cancel();
      _commit(_config.copyWith(centerLat: at.lat, centerLon: at.lon));
    } on LocationException {
      messenger
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(l10n.radarLocationFailed)));
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _latController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.\-]')),
                  ],
                  decoration: InputDecoration(
                    labelText: l10n.radarLatitude,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (_) => _commitCoordsDebounced(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _lonController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.\-]')),
                  ],
                  decoration: InputDecoration(
                    labelText: l10n.radarLongitude,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (_) => _commitCoordsDebounced(),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                tooltip: l10n.radarUseMyLocation,
                onPressed: _locating ? null : _autoLocate,
                icon: _locating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${l10n.radarRange}: ${_config.rangeKm.round()} km',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          Slider(
            value: _config.rangeKm.clamp(
              RadarConfig.minRangeKm,
              RadarConfig.maxRangeKm,
            ),
            min: RadarConfig.minRangeKm,
            max: RadarConfig.maxRangeKm,
            divisions:
                ((RadarConfig.maxRangeKm - RadarConfig.minRangeKm) /
                        RadarConfig.rangeStepKm)
                    .round(),
            label: '${_config.rangeKm.round()} km',
            onChanged: (v) =>
                _commit(_config.copyWith(rangeKm: v.roundToDouble())),
          ),
          const Divider(),
          Row(
            children: [
              Expanded(child: Text(l10n.radarBasemap)),
              const SizedBox(width: 8),
              DropdownButton<RadarMapSource>(
                value: _config.mapSource,
                isDense: true,
                items: [
                  for (final s in RadarMapSource.values)
                    DropdownMenuItem(value: s, child: Text(s.label)),
                ],
                onChanged: (v) {
                  if (v != null) _commit(_config.copyWith(mapSource: v));
                },
              ),
            ],
          ),
          if (_config.mapSource.requiresKey) ...[
            const SizedBox(height: 8),
            TextField(
              controller: _keyController,
              decoration: InputDecoration(
                labelText: l10n.radarBasemapKey,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (_) => _commitKeyDebounced(),
            ),
          ],
          const Divider(),
          Text(l10n.radarFlightLayer),
          const SizedBox(height: 8),
          Builder(
            builder: (context) {
              // null = Off, followed by each flight source. ToggleButtons
              // (unlike SegmentedButton) sizes each button to its own content
              // instead of forcing every segment to the widest one's width.
              const sources = <RadarFlightSource?>[
                null,
                ...RadarFlightSource.values,
              ];
              final selectedSource = _config.flightEnabled
                  ? _config.flightSource
                  : null;
              return ToggleButtons(
                isSelected: [for (final s in sources) s == selectedSource],
                borderRadius: BorderRadius.circular(8),
                constraints: const BoxConstraints(minHeight: 36, minWidth: 48),
                onPressed: (index) {
                  final source = sources[index];
                  _commit(
                    source == null
                        ? _config.copyWith(flightEnabled: false)
                        : _config.copyWith(
                            flightEnabled: true,
                            flightSource: source,
                          ),
                  );
                },
                children: [
                  for (final s in sources)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(s == null ? l10n.controlsOff : s.label),
                    ),
                ],
              );
            },
          ),

          const Divider(),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.radarRainLayer),
            subtitle: Text(l10n.radarRainSubtitle),
            value: _config.rainEnabled,
            onChanged: (v) => _commit(_config.copyWith(rainEnabled: v)),
          ),
        ],
      ),
    );
  }
}
