import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../../../domain/models/app_config.dart';
import '../../../domain/models/haptic_effect.dart';
import '../../../l10n/app_localizations.dart';

/// Settings body for the app-wide [AppConfig].
class SettingsView extends StatelessWidget {
  const SettingsView({
    super.key,
    required this.config,
    required this.onChanged,
    this.onPreviewEffect,
    this.advanced,
  });

  final AppConfig config;
  final ValueChanged<AppConfig> onChanged;

  /// Plays a haptic effect id on the panel so the user feels a choice as they
  /// make it. Null when no device handle is available (e.g. web / tests).
  final ValueChanged<int>? onPreviewEffect;

  /// Optional device-maintenance controls (e.g. firmware update) rendered under
  /// an "Advanced" header, separate from the everyday settings. Null on targets
  /// with no device handle (web / tests).
  final Widget? advanced;

  /// The seed colours offered for the theme.
  static const List<Color> _seeds = <Color>[
    Colors.indigo,
    Colors.blue,
    Colors.teal,
    Colors.green,
    Colors.amber,
    Colors.deepOrange,
    Colors.red,
    Colors.purple,
    Colors.pink,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // The background is a filesystem file, which the web build can't pick.
        if (!kIsWeb) _section(l10n.settingsBackground, _backgroundTile(l10n)),
        _section(l10n.settingsLanguage, _languageControl(l10n)),
        _section(l10n.settingsThemeColor, _themeControl()),
        _section(l10n.settingsBrightness, _brightnessControl()),
        _section(l10n.settingsAlertEffect, _alertEffectControl(l10n)),
        if (advanced != null) _section(l10n.settingsAdvanced, advanced!),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _section(String title, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Builder(
            builder: (context) => Text(
              title,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }

  Widget _backgroundTile(AppLocalizations l10n) {
    final path = config.backgroundPath;
    return ListTile(
      leading: const Icon(Icons.image_outlined),
      title: Text(
        path.isEmpty ? l10n.settingsBackgroundDefault : _basename(path),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(l10n.settingsBackgroundHint),
      trailing: path.isEmpty
          ? null
          : IconButton(
              icon: const Icon(Icons.clear),
              tooltip: l10n.clear,
              onPressed: _clearBackground,
            ),
      onTap: _pickBackground,
    );
  }

  Widget _languageControl(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SegmentedButton<String>(
        segments: [
          ButtonSegment(
            value: AppConfig.systemLocaleTag,
            label: Text(l10n.settingsLanguageSystem),
          ),
          const ButtonSegment(value: 'en', label: Text('English')),
          const ButtonSegment(value: 'zh', label: Text('中文')),
        ],
        selected: {config.localeTag},
        showSelectedIcon: false,
        onSelectionChanged: (s) =>
            onChanged(config.copyWith(localeTag: s.first)),
      ),
    );
  }

  Widget _themeControl() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          for (final color in _seeds)
            _Swatch(
              color: color,
              selected: config.themeSeed == color.toARGB32(),
              onTap: () =>
                  onChanged(config.copyWith(themeSeed: color.toARGB32())),
            ),
        ],
      ),
    );
  }

  Widget _brightnessControl() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: _BrightnessSlider(
        value: config.lcdBrightness,
        onChanged: (v) => onChanged(config.copyWith(lcdBrightness: v)),
      ),
    );
  }

  /// Curated haptic-alert presets. Selecting one persists it and plays it once
  /// (via [onPreviewEffect]) so the choice can be felt in real time.
  Widget _alertEffectControl(AppLocalizations l10n) {
    final selected = AlertEffect.fromEffect(config.alertEffect);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final effect in AlertEffect.values)
            ChoiceChip(
              label: Text(_alertEffectLabel(l10n, effect)),
              selected: effect == selected,
              onSelected: (_) {
                onChanged(config.copyWith(alertEffect: effect.effect));
                onPreviewEffect?.call(effect.effect);
              },
            ),
        ],
      ),
    );
  }

  static String _alertEffectLabel(AppLocalizations l10n, AlertEffect effect) {
    switch (effect) {
      case AlertEffect.none:
        return l10n.alertEffectNone;
      case AlertEffect.click:
        return l10n.alertEffectClick;
      case AlertEffect.tick:
        return l10n.alertEffectTick;
      case AlertEffect.doubleClick:
        return l10n.alertEffectDoubleClick;
      case AlertEffect.buzz:
        return l10n.alertEffectBuzz;
      case AlertEffect.strongBuzz:
        return l10n.alertEffectStrongBuzz;
      case AlertEffect.alert750:
        return l10n.alertEffectAlert750;
      case AlertEffect.alert1000:
        return l10n.alertEffectAlert1000;
      case AlertEffect.pulsing:
        return l10n.alertEffectPulsing;
    }
  }

  /// Pick an image and copy it into app storage, so the reference survives the
  /// original being moved or deleted.
  Future<void> _pickBackground() async {
    const group = XTypeGroup(
      label: 'images',
      extensions: <String>['png', 'jpg', 'jpeg', 'webp', 'gif', 'bmp'],
    );
    final file = await openFile(acceptedTypeGroups: const [group]);
    if (file == null) return;

    final support = await getApplicationSupportDirectory();
    final dir = Directory('${support.path}/backgrounds');
    await dir.create(recursive: true);
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final dest = '${dir.path}/bg_$stamp${_extension(file.name)}';
    await File(file.path).copy(dest);

    final previous = config.backgroundPath;
    onChanged(config.copyWith(backgroundPath: dest));
    await _deleteQuietly(previous, keep: dest);
  }

  Future<void> _clearBackground() async {
    final previous = config.backgroundPath;
    onChanged(config.copyWith(backgroundPath: ''));
    await _deleteQuietly(previous);
  }

  /// Remove a previously copied background, ignoring failures.
  Future<void> _deleteQuietly(String path, {String? keep}) async {
    if (path.isEmpty || path == keep) return;
    try {
      await File(path).delete();
    } catch (_) {
      // Best-effort cleanup; a leftover file is harmless.
    }
  }

  static String _basename(String path) => path.split(RegExp(r'[/\\]')).last;

  static String _extension(String name) {
    final dot = name.lastIndexOf('.');
    return dot < 0 ? '' : name.substring(dot).toLowerCase();
  }
}

/// Backlight slider, shown as a percentage but storing the raw 0–255 value the
/// device expects. Tracks the drag locally and only commits (persist + device
/// command) on release, so a drag doesn't flood the engine with `SetParam`s.
class _BrightnessSlider extends StatefulWidget {
  const _BrightnessSlider({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  State<_BrightnessSlider> createState() => _BrightnessSliderState();
}

class _BrightnessSliderState extends State<_BrightnessSlider> {
  late double _value = widget.value.toDouble();

  @override
  void didUpdateWidget(_BrightnessSlider old) {
    super.didUpdateWidget(old);
    // Reflect an external change (e.g. a reset) unless the user is dragging.
    if (old.value != widget.value && widget.value.toDouble() != _value) {
      _value = widget.value.toDouble();
    }
  }

  int get _percent =>
      (_value / AppConfig.maxLcdBrightness * 100).round();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.brightness_low, size: 20),
        Expanded(
          child: Slider(
            value: _value,
            min: AppConfig.minLcdBrightness.toDouble(),
            max: AppConfig.maxLcdBrightness.toDouble(),
            label: '$_percent%',
            divisions:
                AppConfig.maxLcdBrightness - AppConfig.minLcdBrightness,
            onChanged: (v) => setState(() => _value = v),
            onChangeEnd: (v) => widget.onChanged(v.round()),
          ),
        ),
        const Icon(Icons.brightness_high, size: 20),
        SizedBox(
          width: 44,
          child: Text(
            '$_percent%',
            textAlign: TextAlign.end,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final onColor =
        ThemeData.estimateBrightnessForColor(color) == Brightness.dark
        ? Colors.white
        : Colors.black;
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected
                ? Theme.of(context).colorScheme.onSurface
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: selected ? Icon(Icons.check, size: 20, color: onColor) : null,
      ),
    );
  }
}
