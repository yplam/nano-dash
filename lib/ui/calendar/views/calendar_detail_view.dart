import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../domain/models/calendar.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/panel_empty.dart';
import '../../widgets/panel_text.dart';
import '../../widgets/panel_theme.dart';
import '../cubit/calendar_cubit.dart';

/// How many days ahead the agenda lists (events past this are dropped from the
/// panel even if the repository fetched further for recurrence).
const int _kAgendaDays = 14;

/// The full calendar page shown by `CalendarModule`: an upcoming-events agenda
/// grouped by day, rendered from [CalendarCubit]. Every spacing/size comes from
/// [PanelTheme] so it scales with the panel and reads as one surface with the
/// other modules.
class CalendarDetailView extends StatefulWidget {
  const CalendarDetailView({super.key});

  @override
  State<CalendarDetailView> createState() => _CalendarDetailViewState();
}

class _CalendarDetailViewState extends State<CalendarDetailView> {
  @override
  void initState() {
    super.initState();
    // The page is keyed in the LCD carousel, so this fires each time the user
    // switches onto the calendar. Refresh if the data has gone stale.
    context.read<CalendarCubit>().refreshIfStale();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = math.min(
          constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : constraints.maxHeight,
          constraints.maxHeight.isFinite
              ? constraints.maxHeight
              : constraints.maxWidth,
        );
        return BlocBuilder<CalendarCubit, CalendarState>(
          builder: (context, state) => _body(context, side, state),
        );
      },
    );
  }

  Widget _body(BuildContext context, double side, CalendarState state) {
    final l10n = AppLocalizations.of(context);
    final m = PanelTheme.metricsOf(context, side, shape: PanelShape.landscape);

    final groups = _group(state.events, state.range);
    if (groups.isEmpty) {
      if (state.loading) {
        return const Center(child: CircularProgressIndicator());
      }
      final failed = state.error != null;
      return PanelEmpty(
        side: side,
        icon: failed ? Icons.error_outline : Icons.event_busy_outlined,
        label: failed ? l10n.calendarError : l10n.calendarEmpty,
      );
    }

    final localeName = Localizations.localeOf(context).toString();

    return SingleChildScrollView(
      padding: m.pageInset,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < groups.length; i++) ...[
            if (i > 0) SizedBox(height: m.gap),
            _DayCard(
              side: side,
              group: groups[i],
              localeName: localeName,
              l10n: l10n,
            ),
          ],
        ],
      ),
    );
  }

  /// Group the (already start-sorted) events by calendar day, keeping only days
  /// from today through the window selected by [range] (capped at
  /// [_kAgendaDays]).
  static List<_DayGroup> _group(
    List<CalendarEvent> events,
    CalendarRange range,
  ) {
    final today = _dayOnly(DateTime.now());
    final spanDays = switch (range) {
      CalendarRange.today => 1,
      CalendarRange.todayAndTomorrow => 2,
      CalendarRange.all => _kAgendaDays,
    };
    final horizon = today.add(Duration(days: spanDays));
    final byDay = <DateTime, List<CalendarEvent>>{};
    for (final e in events) {
      final day = _dayOnly(e.start);
      if (day.isBefore(today) || !day.isBefore(horizon)) continue;
      byDay.putIfAbsent(day, () => []).add(e);
    }
    final days = byDay.keys.toList()..sort();
    return [for (final d in days) _DayGroup(day: d, events: byDay[d]!)];
  }

  static DateTime _dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}

class _DayGroup {
  const _DayGroup({required this.day, required this.events});

  final DateTime day;
  final List<CalendarEvent> events;
}

/// One day's card: a day header followed by that day's events.
class _DayCard extends StatelessWidget {
  const _DayCard({
    required this.side,
    required this.group,
    required this.localeName,
    required this.l10n,
  });

  final double side;
  final _DayGroup group;
  final String localeName;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final m = PanelTheme.metricsOf(context, side);

    return Material(
      color: colors.surface.withValues(alpha: m.cardAlpha),
      borderRadius: BorderRadius.circular(m.cardRadius),
      child: Padding(
        padding: m.cardPaddingMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _dayLabel(),
              style: panelFont(
                m.fontXs,
                m.weightMedium,
                colors.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 4),
            for (var i = 0; i < group.events.length; i++)
              Padding(
                padding: EdgeInsets.only(top: i == 0 ? 0 : 6),
                child: _EventRow(
                  side: side,
                  event: group.events[i],
                  localeName: localeName,
                  allDayLabel: l10n.calendarAllDay,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _dayLabel() {
    final today = DateTime.now();
    final t = DateTime(today.year, today.month, today.day);
    final diff = group.day.difference(t).inDays;
    if (diff == 0) return l10n.calendarToday;
    if (diff == 1) return l10n.calendarTomorrow;
    return DateFormat.MMMMEEEEd(localeName).format(group.day);
  }
}

/// One event row: a coloured calendar dot, the time (or "all day"), the title,
/// and an optional location line.
class _EventRow extends StatelessWidget {
  const _EventRow({
    required this.side,
    required this.event,
    required this.localeName,
    required this.allDayLabel,
  });

  final double side;
  final CalendarEvent event;
  final String localeName;
  final String allDayLabel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final m = PanelTheme.metricsOf(context, side);
    final timeFmt = DateFormat.jm(localeName);

    final timeLabel = event.allDay ? allDayLabel : timeFmt.format(event.start);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: 4),
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Color(event.color),
              shape: BoxShape.circle,
            ),
          ),
        ),
        SizedBox(width: 4),
        Padding(
          padding: EdgeInsets.only(top: 2),
          child: SizedBox(
            width: 48,
            child: Text(
              timeLabel,
              style: panelFont(m.fontSm, m.weightMedium, colors.onSurface),
            ),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event.title,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: panelFont(m.fontMd, m.weightRegular, colors.onSurface),
              ),
              if (event.location != null && event.location!.isNotEmpty)
                Text(
                  event.location!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: panelFont(
                    m.fontXs,
                    m.weightRegular,
                    colors.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
