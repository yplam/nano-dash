import 'dart:async';

import 'package:flutter/material.dart';

import '../../../domain/models/usage_monitor.dart';
import '../../../l10n/app_localizations.dart';

/// Settings control for the usage monitor: an enable switch and an optional
/// proxy field for each provider, so the two coding agents can be toggled and
/// routed independently.
class UsageMonitorSettings extends StatefulWidget {
  const UsageMonitorSettings({
    super.key,
    required this.initialConfig,
    required this.onConfigChanged,
  });

  /// The settings to seed the control with.
  final UsageMonitorConfig initialConfig;

  /// Called with the full updated config whenever the user pauses editing.
  final ValueChanged<UsageMonitorConfig> onConfigChanged;

  @override
  State<UsageMonitorSettings> createState() => _UsageMonitorSettingsState();
}

class _UsageMonitorSettingsState extends State<UsageMonitorSettings> {
  late bool _claudeEnabled;
  late bool _codexEnabled;
  late final TextEditingController _claudeProxy;
  late final TextEditingController _codexProxy;

  /// Hold off committing proxy edits until the user pauses typing.
  Timer? _debounce;
  static const Duration _debounceDelay = Duration(milliseconds: 600);

  @override
  void initState() {
    super.initState();
    _claudeEnabled = widget.initialConfig.claudeEnabled;
    _codexEnabled = widget.initialConfig.codexEnabled;
    _claudeProxy = TextEditingController(
      text: widget.initialConfig.claudeProxy ?? '',
    );
    _codexProxy = TextEditingController(
      text: widget.initialConfig.codexProxy ?? '',
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _claudeProxy.dispose();
    _codexProxy.dispose();
    super.dispose();
  }

  UsageMonitorConfig get _current => UsageMonitorConfig(
    claudeEnabled: _claudeEnabled,
    claudeProxy: _claudeProxy.text.trim(),
    codexEnabled: _codexEnabled,
    codexProxy: _codexProxy.text.trim(),
  );

  /// Toggles commit immediately; proxy edits debounce.
  void _emit({bool immediate = false}) {
    _debounce?.cancel();
    if (immediate) {
      widget.onConfigChanged(_current);
      return;
    }
    _debounce = Timer(_debounceDelay, () => widget.onConfigChanged(_current));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _providerSection(
            l10n,
            name: UsageMonitorProvider.claude.displayName,
            enabled: _claudeEnabled,
            proxy: _claudeProxy,
            onEnabled: (v) {
              setState(() => _claudeEnabled = v);
              _emit(immediate: true);
            },
          ),
          const SizedBox(height: 8),
          _providerSection(
            l10n,
            name: UsageMonitorProvider.codex.displayName,
            enabled: _codexEnabled,
            proxy: _codexProxy,
            onEnabled: (v) {
              setState(() => _codexEnabled = v);
              _emit(immediate: true);
            },
          ),
        ],
      ),
    );
  }

  Widget _providerSection(
    AppLocalizations l10n, {
    required String name,
    required bool enabled,
    required TextEditingController proxy,
    required ValueChanged<bool> onEnabled,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(name),
          value: enabled,
          onChanged: onEnabled,
        ),
        TextField(
          controller: proxy,
          enabled: enabled,
          keyboardType: TextInputType.url,
          decoration: InputDecoration(
            labelText: l10n.usageMonitorProxy,
            hintText: l10n.usageMonitorProxyHint,
            isDense: true,
            border: const OutlineInputBorder(),
          ),
          onChanged: (_) => _emit(),
        ),
      ],
    );
  }
}
