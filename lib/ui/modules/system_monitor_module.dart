import 'package:flutter/material.dart';

import '../../domain/models/dashboard.dart';
import '../../domain/models/module.dart';
import '../../l10n/app_localizations.dart';
import '../system_monitor/views/system_monitor_view.dart';

/// Live host telemetry (CPU, memory, network) rendered as a scrollable stack of
/// cards.
class SystemMonitorModule extends Module {
  const SystemMonitorModule();

  static const String kId = 'system';

  @override
  String get id => kId;

  @override
  IconData get icon => Icons.monitor_heart_outlined;

  @override
  String title(AppLocalizations l10n) => l10n.moduleSystemTitle;

  @override
  Widget build(BuildContext context, ModuleSettings settings) =>
      const SystemMonitorView();
}
