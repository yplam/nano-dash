import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/models/dashboard.dart';
import '../../domain/models/module.dart';
import '../../domain/models/voice.dart';
import '../../l10n/app_localizations.dart';
import '../voice/voice.dart';

/// A settings-only module for the full-duplex voice engine.
class VoiceModule extends Module {
  const VoiceModule();

  static const String kId = 'voice';

  @override
  String get id => kId;

  @override
  IconData get icon => Icons.mic_none;

  @override
  String title(AppLocalizations l10n) => l10n.moduleVoiceTitle;

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
    return BlocBuilder<VoiceCubit, VoiceState>(
      buildWhen: (prev, curr) =>
          prev.status != curr.status ||
          prev.error != curr.error ||
          prev.enrolling != curr.enrolling ||
          prev.enrollCount != curr.enrollCount ||
          prev.enrollMessage != curr.enrollMessage ||
          prev.enrollOk != curr.enrollOk,
      builder: (context, state) {
        final cubit = context.read<VoiceCubit>();
        return VoiceSettingsView(
          initialSettings: state.settings,
          status: state.status,
          statusHint: switch (state.status) {
            VoiceStatus.error => state.error,
            _ when state.status.isOpen => l10n.voiceRestartToApply,
            _ => null,
          },
          enrolling: state.enrolling,
          enrollCount: state.enrollCount,
          enrollMessage: state.enrollMessage,
          enrollOk: state.enrollOk,
          onEnrollStart: cubit.startEnroll,
          onEnrollStop: cubit.stopEnroll,
          onEnrollForget: cubit.forgetVoiceprint,
          onEnrollSessionEnd: cubit.endEnrollSession,
          onSettingsChanged: cubit.updateSettings,
        );
      },
    );
  }
}
