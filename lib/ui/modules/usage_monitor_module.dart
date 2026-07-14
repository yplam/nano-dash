import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/models/dashboard.dart';
import '../../domain/models/module.dart';
import '../../l10n/app_localizations.dart';
import '../usage_monitor/usage_monitor.dart';

/// The usage monitor page: rolling rate-limit usage (5h / 7d) for the local
/// Claude Code and Codex CLIs, rendered as per-provider bar meters.
class UsageMonitorModule extends Module {
  const UsageMonitorModule();

  static const String kId = 'usage_monitor';

  @override
  String get id => kId;

  @override
  IconData get icon => Icons.data_usage;

  @override
  String title(AppLocalizations l10n) => l10n.moduleUsageMonitorTitle;

  @override
  bool get hasSettings => true;

  @override
  Widget build(BuildContext context, ModuleSettings settings) =>
      const UsageMonitorView();

  @override
  Widget buildSettings(
    BuildContext context,
    ModuleSettings settings,
    ValueChanged<ModuleSettings> onChanged,
  ) {
    return BlocBuilder<UsageMonitorCubit, UsageMonitorState>(
      buildWhen: (prev, curr) => prev.config != curr.config,
      builder: (context, state) => UsageMonitorSettings(
        initialConfig: state.config,
        onConfigChanged: (config) =>
            context.read<UsageMonitorCubit>().setConfig(config),
      ),
    );
  }
}
