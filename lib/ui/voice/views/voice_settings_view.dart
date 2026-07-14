import 'dart:async';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import '../../../domain/models/voice.dart';
import '../../../l10n/app_localizations.dart';

/// Settings for the voice module, grouped into sections: where the models live
/// and how the mic listens (folder, wake word, language, speaker id), which
/// synthesizer speaks, and finally the audio processing (echo cancellation).
class VoiceSettingsView extends StatefulWidget {
  const VoiceSettingsView({
    super.key,
    required this.initialSettings,
    required this.onSettingsChanged,
    this.statusHint,
    this.status = VoiceStatus.off,
    this.enrolling = false,
    this.enrollCount,
    this.enrollMessage,
    this.enrollOk = true,
    this.onEnrollStart,
    this.onEnrollStop,
    this.onEnrollForget,
    this.onEnrollSessionEnd,
  });

  final VoiceSettings initialSettings;

  /// Called with the full updated settings whenever the user pauses editing.
  final ValueChanged<VoiceSettings> onSettingsChanged;

  /// Shown under the title — e.g. "restart the mic to apply", or the reason the
  /// last start failed.
  final String? statusHint;

  /// The live engine status. Enrolling a voiceprint only works while the engine
  /// is open, so the record controls are gated on this.
  final VoiceStatus status;

  /// Whether a voiceprint capture is currently in progress.
  final bool enrolling;

  /// Recordings enrolled after the last capture this session, or `null` before
  /// any enrollment has completed.
  final int? enrollCount;

  /// The failure reason from the last enrollment, or `null` on success.
  final String? enrollMessage;

  /// Whether the last enrollment succeeded.
  final bool enrollOk;

  /// Begin / end a voiceprint capture, and forget the enrolled voiceprint.
  /// Starting a capture powers the mic on when it is off.
  final VoidCallback? onEnrollStart;
  final VoidCallback? onEnrollStop;
  final VoidCallback? onEnrollForget;

  /// Called when this view is disposed (the settings sheet closed), so the mic
  /// can be released if [onEnrollStart] was the one that powered it on.
  final VoidCallback? onEnrollSessionEnd;

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
    widget.onEnrollSessionEnd?.call();
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

        // --- Models & listening ---------------------------------------------
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
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
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
        ..._speakerIdSection(context, l10n),

        // --- Speech ----------------------------------------------------------
        const Divider(height: 24),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
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

        // --- Audio -----------------------------------------------------------
        const Divider(height: 24),
        SwitchListTile(
          secondary: const Icon(Icons.noise_control_off),
          title: Text(l10n.voiceAec),
          subtitle: Text(l10n.voiceAecHint),
          value: _settings.enableAec,
          onChanged: (v) => _commit(_settings.copyWith(enableAec: v)),
        ),
      ],
    );
  }

  /// The speaker-identification controls: enable the model (which also gates the
  /// ASR to the enrolled voice) and record/forget the voiceprint. Grouped with
  /// the listening controls since it filters the mic input.
  List<Widget> _speakerIdSection(BuildContext context, AppLocalizations l10n) {
    return [
      SwitchListTile(
        secondary: const Icon(Icons.fingerprint),
        title: Text(l10n.voiceSpeakerIdent),
        subtitle: Text(l10n.voiceSpeakerIdentHint),
        value: _settings.enableSpeakerId,
        onChanged: (v) => _commit(_settings.copyWith(enableSpeakerId: v)),
      ),
      if (_settings.enableSpeakerId) _voiceprintRow(context, l10n),
    ];
  }

  /// The voiceprint status line plus the record/forget buttons. Recording powers
  /// the mic on itself, so Record works even when the engine is off; while it is
  /// opening the button shows a spinner. Forget still needs the running engine.
  Widget _voiceprintRow(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    final starting = widget.status == VoiceStatus.starting;
    final isOpen = widget.status.isOpen;

    final String statusText;
    if (starting) {
      statusText = l10n.voiceEnrollStarting;
    } else if (widget.enrolling) {
      statusText = l10n.voiceEnrollRecording;
    } else if (!widget.enrollOk && widget.enrollMessage != null) {
      statusText = l10n.voiceEnrollFailed(widget.enrollMessage!);
    } else if (widget.enrollCount != null) {
      statusText = l10n.voiceEnrollCount(widget.enrollCount!);
    } else {
      statusText = l10n.voiceEnrollPrompt;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.voiceVoiceprint, style: theme.textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(
            statusText,
            style: theme.textTheme.bodySmall?.copyWith(
              color: (!widget.enrollOk && widget.enrollMessage != null)
                  ? theme.colorScheme.error
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              FilledButton.tonalIcon(
                onPressed: starting
                    ? null
                    : (widget.enrolling
                          ? widget.onEnrollStop
                          : widget.onEnrollStart),
                icon: starting
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        widget.enrolling
                            ? Icons.stop
                            : Icons.fiber_manual_record,
                      ),
                label: Text(
                  starting
                      ? l10n.voiceEnrollStarting
                      : (widget.enrolling
                            ? l10n.voiceEnrollStop
                            : l10n.voiceEnrollRecord),
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: (isOpen && !widget.enrolling)
                    ? widget.onEnrollForget
                    : null,
                icon: const Icon(Icons.delete_outline),
                label: Text(l10n.voiceEnrollForget),
              ),
            ],
          ),
        ],
      ),
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
