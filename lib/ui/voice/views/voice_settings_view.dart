import 'dart:async';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import '../../../domain/models/voice.dart';
import '../../../l10n/app_localizations.dart';

/// Settings for the voice module: where the models live, how the mic is
/// processed, and which synthesizer speaks.
class VoiceSettingsView extends StatefulWidget {
  const VoiceSettingsView({
    super.key,
    required this.initialSettings,
    required this.onSettingsChanged,
    this.statusHint,
  });

  final VoiceSettings initialSettings;

  /// Called with the full updated settings whenever the user pauses editing.
  final ValueChanged<VoiceSettings> onSettingsChanged;

  /// Shown under the title — e.g. "restart the mic to apply", or the reason the
  /// last start failed.
  final String? statusHint;

  @override
  State<VoiceSettingsView> createState() => _VoiceSettingsViewState();
}

class _VoiceSettingsViewState extends State<VoiceSettingsView> {
  late VoiceSettings _settings;

  late final Map<String, TextEditingController> _fields;

  /// Hold off committing until the user pauses typing.
  Timer? _debounce;
  static const Duration _debounceDelay = Duration(milliseconds: 600);

  @override
  void initState() {
    super.initState();
    _settings = widget.initialSettings;
    _fields = {
      'apiKey': TextEditingController(text: _settings.ttsApiKey),
      'baseUrl': TextEditingController(text: _settings.ttsBaseUrl),
      'resourceId': TextEditingController(text: _settings.ttsResourceId),
      'speaker': TextEditingController(text: _settings.ttsSpeaker),
      'model': TextEditingController(text: _settings.ttsModel),
      'language': TextEditingController(text: _settings.ttsLanguage),
      'instructions': TextEditingController(text: _settings.ttsInstructions),
      'proxy': TextEditingController(text: _settings.ttsProxy),
    };
  }

  @override
  void dispose() {
    _debounce?.cancel();
    for (final c in _fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  /// Commit a non-text edit (switch, dropdown, slider) at once.
  void _commit(VoiceSettings settings) {
    setState(() => _settings = settings);
    widget.onSettingsChanged(settings);
  }

  /// Commit the text fields once the user pauses typing.
  void _commitFieldsDebounced() {
    _debounce?.cancel();
    _debounce = Timer(_debounceDelay, () {
      final next = _settings.copyWith(
        ttsApiKey: _fields['apiKey']!.text.trim(),
        ttsBaseUrl: _fields['baseUrl']!.text.trim(),
        ttsResourceId: _fields['resourceId']!.text.trim(),
        ttsSpeaker: _fields['speaker']!.text.trim(),
        ttsModel: _fields['model']!.text.trim(),
        ttsLanguage: _fields['language']!.text.trim(),
        ttsInstructions: _fields['instructions']!.text.trim(),
        ttsProxy: _fields['proxy']!.text.trim(),
      );
      _settings = next;
      widget.onSettingsChanged(next);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final hint = widget.statusHint;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hint != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Text(
              hint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
        ListTile(
          leading: const Icon(Icons.folder_open),
          title: Text(l10n.voiceModelsDir),
          subtitle: Text(
            _settings.modelsDir.isEmpty
                ? l10n.voiceNoModelsDir
                : _settings.modelsDir,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: _settings.modelsDir.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.clear),
                  tooltip: l10n.clear,
                  onPressed: () => _commit(_settings.copyWith(modelsDir: '')),
                ),
          onTap: () async {
            final dir = await getDirectoryPath();
            if (dir != null) _commit(_settings.copyWith(modelsDir: dir));
          },
        ),
        SwitchListTile(
          secondary: const Icon(Icons.record_voice_over_outlined),
          title: Text(l10n.voiceWakeWord),
          subtitle: Text(l10n.voiceWakeWordHint),
          value: _settings.enableWake,
          onChanged: (v) => _commit(_settings.copyWith(enableWake: v)),
        ),
        SwitchListTile(
          secondary: const Icon(Icons.noise_control_off),
          title: Text(l10n.voiceAec),
          subtitle: Text(l10n.voiceAecHint),
          value: _settings.enableAec,
          onChanged: (v) => _commit(_settings.copyWith(enableAec: v)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: DropdownButtonFormField<String>(
            initialValue: _settings.language,
            decoration: InputDecoration(
              labelText: l10n.voiceLanguage,
              border: const OutlineInputBorder(),
            ),
            items: [
              for (final code in VoiceSettings.languages)
                DropdownMenuItem(
                  value: code,
                  child: Text(
                    code == 'auto'
                        ? l10n.voiceLanguageAuto
                        : code.toUpperCase(),
                  ),
                ),
            ],
            onChanged: (v) =>
                v == null ? null : _commit(_settings.copyWith(language: v)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: DropdownButtonFormField<String>(
            initialValue: _settings.ttsBackend,
            decoration: InputDecoration(
              labelText: l10n.voiceTtsBackend,
              border: const OutlineInputBorder(),
            ),
            items: [
              for (final id in VoiceSettings.ttsBackends)
                DropdownMenuItem(
                  value: id,
                  child: Text(id == 'none' ? l10n.voiceTtsNone : id),
                ),
            ],
            onChanged: (v) =>
                v == null ? null : _commit(_settings.copyWith(ttsBackend: v)),
          ),
        ),
        ..._backendFields(l10n),
        // Multi-speaker VITS models index their voices by number; the online
        // backends name theirs, and take the "voice" field above instead.
        if (_settings.isLocalTts)
          ListTile(
            title: Text(l10n.voiceSpeakerId),
            trailing: SizedBox(
              width: 88,
              child: TextFormField(
                initialValue: '${_settings.sid}',
                keyboardType: TextInputType.number,
                textAlign: TextAlign.end,
                decoration: const InputDecoration(isDense: true),
                onChanged: (v) {
                  final sid = int.tryParse(v.trim());
                  if (sid != null && sid >= 0) {
                    _commit(_settings.copyWith(sid: sid));
                  }
                },
              ),
            ),
          ),
        // Speed only steers the synthesizer, so it is meaningless in text-only
        // mode.
        if (_settings.ttsEnabled)
          ListTile(
            title: Text(l10n.voiceSpeed),
            subtitle: Slider(
              value: _settings.speed.clamp(0.5, 2.0),
              min: 0.5,
              max: 2.0,
              divisions: 15,
              label: _settings.speed.toStringAsFixed(1),
              onChanged: (v) => _commit(_settings.copyWith(speed: v)),
            ),
            trailing: Text(_settings.speed.toStringAsFixed(1)),
          ),
      ],
    );
  }

  /// The credential/endpoint fields the selected backend actually reads. Local
  /// TTS needs none of them.
  List<Widget> _backendFields(AppLocalizations l10n) {
    final s = _settings;
    return [
      if (s.isOpenaiTts || s.isVllmTts || s.isVolcengineTts)
        _field('apiKey', l10n.voiceTtsApiKey, obscure: true),
      if (s.isOpenaiTts || s.isVllmTts) _field('baseUrl', l10n.voiceTtsBaseUrl),
      if (s.isVolcengineTts) _field('resourceId', l10n.voiceTtsResourceId),
      // Online backends name their voice/model; local uses a numeric speaker id
      // (below) and 'none' synthesizes nothing, so both fields stay hidden there.
      if (s.isOnlineTts) _field('speaker', l10n.voiceTtsSpeaker),
      if (s.isOnlineTts) _field('model', l10n.voiceTtsModel),
      if (s.isVllmTts) _field('language', l10n.voiceTtsLanguage),
      if (s.isOpenaiTts || s.isVllmTts)
        _field('instructions', l10n.voiceTtsInstructions),
      if (s.isOpenaiTts || s.isVllmTts) _field('proxy', l10n.voiceTtsProxy),
    ];
  }

  Widget _field(String key, String label, {bool obscure = false}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: TextField(
        controller: _fields[key],
        obscureText: obscure,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        onChanged: (_) => _commitFieldsDebounced(),
      ),
    );
  }
}
