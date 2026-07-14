import 'dart:async';

import 'package:flutter/material.dart';

import '../../../domain/models/agent.dart';
import '../../../l10n/app_localizations.dart';

/// Settings for the agent module: the OpenAI-compatible endpoint and the two
/// model names behind the voice assistant.
class AgentSettingsView extends StatefulWidget {
  const AgentSettingsView({
    super.key,
    required this.initialSettings,
    required this.onSettingsChanged,
    this.statusHint,
  });

  /// The settings to seed the controls with. Read once, in [initState]; later
  /// changes from the owner are ignored so they can't clobber in-progress edits.
  final AgentSettings initialSettings;

  /// Called with the full updated settings whenever the user pauses editing.
  final ValueChanged<AgentSettings> onSettingsChanged;

  /// Shown under the title — e.g. "set an API key first".
  final String? statusHint;

  @override
  State<AgentSettingsView> createState() => _AgentSettingsViewState();
}

class _AgentSettingsViewState extends State<AgentSettingsView> {
  late AgentSettings _settings;

  late final Map<String, TextEditingController> _fields;

  /// Hold off committing until the user pauses typing, so a half-typed API key
  /// isn't persisted on every keystroke.
  Timer? _debounce;
  static const Duration _debounceDelay = Duration(milliseconds: 600);

  @override
  void initState() {
    super.initState();
    _settings = widget.initialSettings;
    _fields = {
      'apiKey': TextEditingController(text: _settings.apiKey),
      'baseUrl': TextEditingController(text: _settings.baseUrl),
      'proxy': TextEditingController(text: _settings.proxy),
      'lightModel': TextEditingController(text: _settings.lightModel),
      'proModel': TextEditingController(text: _settings.proModel),
      'persona': TextEditingController(text: _settings.persona),
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

  /// Commit a non-text edit (the enable switch) at once.
  void _commit(AgentSettings settings) {
    setState(() => _settings = settings);
    widget.onSettingsChanged(settings);
  }

  /// Commit the text fields once the user pauses typing.
  void _commitFieldsDebounced() {
    _debounce?.cancel();
    _debounce = Timer(_debounceDelay, () {
      final next = _settings.copyWith(
        apiKey: _fields['apiKey']!.text.trim(),
        baseUrl: _fields['baseUrl']!.text.trim(),
        proxy: _fields['proxy']!.text.trim(),
        lightModel: _fields['lightModel']!.text.trim(),
        proModel: _fields['proModel']!.text.trim(),
        persona: _fields['persona']!.text.trim(),
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
        SwitchListTile(
          secondary: const Icon(Icons.smart_toy_outlined),
          title: Text(l10n.agentEnable),
          subtitle: Text(l10n.agentEnableHint),
          value: _settings.enabled,
          onChanged: (v) => _commit(_settings.copyWith(enabled: v)),
        ),
        if (_settings.enabled) ...[
          _field('apiKey', l10n.agentApiKey, obscure: true),
          _field('baseUrl', l10n.agentBaseUrl),
          _field('proxy', l10n.agentProxy),
          _field(
            'lightModel',
            l10n.agentLightModel,
            help: l10n.agentLightModelHint,
          ),
          _field('proModel', l10n.agentProModel, help: l10n.agentProModelHint),
          _field(
            'persona',
            l10n.agentPersona,
            help: l10n.agentPersonaHint,
            lines: 3,
          ),
        ],
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _field(
    String key,
    String label, {
    bool obscure = false,
    String? help,
    int lines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: TextField(
        controller: _fields[key],
        obscureText: obscure,
        minLines: lines,
        maxLines: lines,
        decoration: InputDecoration(
          labelText: label,
          helperText: help,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        onChanged: (_) => _commitFieldsDebounced(),
      ),
    );
  }
}
