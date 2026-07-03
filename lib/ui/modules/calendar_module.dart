import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/models/calendar.dart';
import '../../domain/models/dashboard.dart';
import '../../domain/models/module.dart';
import '../../l10n/app_localizations.dart';
import '../calendar/calendar.dart';

/// The calendar page: an upcoming-events agenda merged from one or more
/// published CalDAV/ICS feeds.
class CalendarModule extends Module {
  const CalendarModule();

  static const String kId = 'calendar';

  @override
  String get id => kId;

  @override
  IconData get icon => Icons.event_outlined;

  @override
  String title(AppLocalizations l10n) => l10n.moduleCalendarTitle;

  @override
  bool get hasSettings => true;

  @override
  Widget build(BuildContext context, ModuleSettings settings) =>
      const CalendarDetailView();

  @override
  Widget buildSettings(
    BuildContext context,
    ModuleSettings settings,
    ValueChanged<ModuleSettings> onChanged,
  ) {
    return BlocBuilder<CalendarCubit, CalendarState>(
      builder: (context, state) => CalendarSettings(
        initialConfig: CalendarConfig(
          sources: state.sources,
          range: state.range,
        ),
        sourceErrors: state.sourceErrors,
        onConfigChanged: (config) =>
            context.read<CalendarCubit>().setConfig(config),
      ),
    );
  }
}
