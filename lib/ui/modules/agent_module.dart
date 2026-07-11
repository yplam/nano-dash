import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/models/dashboard.dart';
import '../../domain/models/module.dart';
import '../../l10n/app_localizations.dart';
import '../agent/agent.dart';

/// A settings-only module for the LLM voice agent. It renders no LCD page: the
/// agent is shared infrastructure that answers through the voice engine and the
/// Live2D dialogue box. Registered only on desktop — it reads [AgentCubit],
/// which the web build never provides.
class AgentModule extends Module {
  const AgentModule();

  static const String kId = 'agent';

  @override
  String get id => kId;

  @override
  IconData get icon => Icons.smart_toy_outlined;

  @override
  String title(AppLocalizations l10n) => l10n.moduleAgentTitle;

  @override
  bool get hasDisplay => false;

  @override
  bool get hasSettings => true;

  @override
  Widget buildSettings(
    BuildContext context,
    ModuleSettings settings,
    ValueChanged<ModuleSettings> onChanged,
  ) {
    final l10n = AppLocalizations.of(context);
    return BlocBuilder<AgentCubit, AgentState>(
      // The sheet is seeded once from the cubit; rebuilding on every streamed
      // reply delta would fight the text fields.
      buildWhen: (prev, curr) => prev.settings != curr.settings,
      builder: (context, state) => AgentSettingsView(
        initialSettings: state.settings,
        statusHint:
            state.settings.enabled && state.settings.apiKey.trim().isEmpty
            ? l10n.agentNeedsApiKey
            : null,
        onSettingsChanged: (next) =>
            context.read<AgentCubit>().updateSettings(next),
      ),
    );
  }
}
