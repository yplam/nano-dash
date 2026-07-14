import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/models/dashboard.dart';
import '../../domain/models/module.dart';
import '../../l10n/app_localizations.dart';
import '../timer/cubit/timer_cubit.dart';
import '../timer/views/timer_settings_view.dart';
import '../timer/views/timer_view.dart';

/// A set of named countdown timers, each with its own duration and
/// sound/vibrate preferences. Defaults to a plain countdown plus a Pomodoro.
///
/// The presets live in `TimerRepository` (its own settings key), not in this
/// module's settings map — they must be reachable by the voice agent, which
/// runs below the module layer. Legacy presets stored here are migrated by the
/// repository on first run.
class TimerModule extends Module {
  const TimerModule();

  static const String kId = 'timer';

  @override
  String get id => kId;

  @override
  IconData get icon => Icons.hourglass_empty;

  @override
  String title(AppLocalizations l10n) => l10n.moduleTimerTitle;

  @override
  bool get hasSettings => true;

  @override
  Widget build(BuildContext context, ModuleSettings settings) =>
      const TimerView();

  @override
  Widget buildSettings(
    BuildContext context,
    ModuleSettings settings,
    ValueChanged<ModuleSettings> onChanged,
  ) {
    return BlocBuilder<TimerCubit, TimerState>(
      buildWhen: (prev, curr) => prev.timers != curr.timers,
      builder: (context, state) => TimerSettingsView(
        timers: state.timers,
        onChanged: context.read<TimerCubit>().saveTimers,
      ),
    );
  }
}
