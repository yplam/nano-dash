import 'package:flutter/material.dart';

import '../../domain/models/dashboard.dart';
import '../../domain/models/module.dart';
import '../../l10n/app_localizations.dart';
import '../stopwatch/views/stopwatch_view.dart';

/// A stopwatch with a sweeping ring (one turn per minute), a centisecond
/// readout, and start/pause + reset controls.
class StopwatchModule extends Module {
  const StopwatchModule();

  static const String kId = 'stopwatch';

  @override
  String get id => kId;

  @override
  IconData get icon => Icons.timer_outlined;

  @override
  String title(AppLocalizations l10n) => l10n.moduleStopwatchTitle;

  @override
  Widget build(BuildContext context, ModuleSettings settings) =>
      const StopwatchView();
}
