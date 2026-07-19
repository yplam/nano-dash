import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../domain/models/calendar.dart';
import '../../../domain/models/timer.dart';
import '../../../l10n/app_localizations.dart';
import '../../dashboard/cubit/dashboard_cubit.dart';
import '../../modules/timer_module.dart';
import '../../timer/cubit/timer_cubit.dart';
import '../../widgets/panel_empty.dart';
import '../../widgets/panel_text.dart';
import '../../widgets/panel_theme.dart';
import '../cubit/calendar_cubit.dart';

/// How long the "added" confirmation toast lingers before fading out.
const Duration _kToastDuration = Duration(milliseconds: 1600);

/// How many days ahead the agenda lists (events past this are dropped from the
/// panel even if the repository fetched further for recurrence).
const int _kAgendaDays = 14;

/// The full calendar page shown by `CalendarModule`: an upcoming-events agenda,
/// one event per card, rendered from [CalendarCubit]. Every spacing/size comes
/// from [PanelTheme] so it scales with the panel and reads as one surface with
/// the other modules.
class CalendarDetailView extends StatefulWidget {
  const CalendarDetailView({super.key});

  @override
  State<CalendarDetailView> createState() => _CalendarDetailViewState();
}

class _CalendarDetailViewState extends State<CalendarDetailView> {
  // Captured from the tree while this widget is active.
  late final CalendarCubit _cubit;

  /// The event whose long-press context menu is open, or null when none is.
  /// The menu and the confirmation toast render in-tree (the mirrored panel
  /// subtree has no route Overlay of its own, so a `showMenu`/`SnackBar` would
  /// only appear in the desktop window and never on the physical panel).
  CalendarEvent? _menuEvent;

  /// The transient confirmation message shown after an action, or null.
  String? _toast;
  Timer? _toastTimer;

  @override
  void initState() {
    super.initState();
    _cubit = context.read<CalendarCubit>();
    _cubit.onViewActive();
  }

  @override
  void dispose() {
    _toastTimer?.cancel();
    _cubit.onViewInactive();
    super.dispose();
  }

  void _openMenu(CalendarEvent event) => setState(() => _menuEvent = event);

  void _closeMenu() {
    if (_menuEvent != null) setState(() => _menuEvent = null);
  }

  /// Append a Pomodoro timer named after [event]'s title (25-min focus, the
  /// default 5/15-min breaks), then confirm with a toast.
  void _createPomodoro(CalendarEvent event) {
    final timerCubit = context.read<TimerCubit>();
    final timers = List<TimerConfig>.of(timerCubit.state.timers)
      ..add(
        TimerConfig(
          id: TimerConfig.newId(),
          name: event.title,
          duration: const Duration(minutes: 25),
          pomodoro: true,
        ),
      );
    timerCubit.saveTimers(timers);
    _showToast(AppLocalizations.of(context).calendarPomodoroCreated);
    _closeMenu();
    // Bring the timer page up so the freshly added timer is right there.
    context.read<DashboardCubit>().goToModule(TimerModule.kId);
  }

  void _showToast(String message) {
    _toastTimer?.cancel();
    setState(() => _toast = message);
    _toastTimer = Timer(_kToastDuration, () {
      if (mounted) setState(() => _toast = null);
    });
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
          builder: (context, state) => Stack(
            children: [
              _body(context, side, state),
              if (_menuEvent != null)
                _EventContextMenu(
                  side: side,
                  event: _menuEvent!,
                  onCreatePomodoro: () => _createPomodoro(_menuEvent!),
                  onDismiss: _closeMenu,
                ),
              if (_toast != null) _PanelToast(side: side, message: _toast!),
            ],
          ),
        );
      },
    );
  }

  Widget _body(BuildContext context, double side, CalendarState state) {
    final l10n = AppLocalizations.of(context);
    final m = PanelTheme.metricsOf(context, side, shape: PanelShape.landscape);

    final events = _eventsInRange(state.events, state.range);
    if (events.isEmpty) {
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
          for (var i = 0; i < events.length; i++) ...[
            if (i > 0) SizedBox(height: m.gap),
            _EventCard(
              side: side,
              event: events[i],
              localeName: localeName,
              l10n: l10n,
              onLongPress: _openMenu,
            ),
          ],
        ],
      ),
    );
  }

  /// The (already start-sorted) events falling from today through the window
  /// selected by [range] (capped at [_kAgendaDays]).
  static List<CalendarEvent> _eventsInRange(
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
    return [
      for (final e in events)
        if (!_dayOnly(e.start).isBefore(today) &&
            _dayOnly(e.start).isBefore(horizon))
          e,
    ];
  }

  static DateTime _dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}

/// One event card: a two-row surface whose whole area is long-pressable to
/// spin up a Pomodoro timer. Row one is a coloured calendar dot followed by the
/// day and time (or "all day"); row two is the title, two lines max.
class _EventCard extends StatelessWidget {
  const _EventCard({
    required this.side,
    required this.event,
    required this.localeName,
    required this.l10n,
    required this.onLongPress,
  });

  final double side;
  final CalendarEvent event;
  final String localeName;
  final AppLocalizations l10n;

  /// Invoked when this card is long-pressed (opens the context menu).
  final ValueChanged<CalendarEvent> onLongPress;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final m = PanelTheme.metricsOf(context, side);

    return Material(
      color: colors.surface.withValues(alpha: m.cardAlpha),
      borderRadius: BorderRadius.circular(m.cardRadius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onLongPress: () => onLongPress(event),
        child: Padding(
          padding: m.cardPaddingMd,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Color(event.color),
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _whenLabel(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: panelFont(
                        m.fontSm,
                        m.weightMedium,
                        colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4),
              Text(
                event.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: panelFont(m.fontMd, m.weightRegular, colors.onSurface),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// "Today 3:00 PM", "Tomorrow all day", or "Mon, Jul 21 3:00 PM".
  String _whenLabel() {
    final t = DateTime.now();
    final today = DateTime(t.year, t.month, t.day);
    final day = DateTime(event.start.year, event.start.month, event.start.day);
    final diff = day.difference(today).inDays;
    final String dayLabel;
    if (diff == 0) {
      dayLabel = l10n.calendarToday;
    } else if (diff == 1) {
      dayLabel = l10n.calendarTomorrow;
    } else {
      dayLabel = DateFormat.MMMEd(localeName).format(event.start);
    }
    final timeLabel = event.allDay
        ? l10n.calendarAllDay
        : DateFormat.jm(localeName).format(event.start);
    return '$dayLabel  $timeLabel';
  }
}

/// The in-tree context menu shown when a calendar event is long-pressed: a
/// tap-to-dismiss scrim behind a centered card that names the event and offers
/// the "Create Pomodoro timer" action. Rendered inside the mirrored subtree so
/// it appears on the panel, and sized/centered to stay clear of the round rim.
class _EventContextMenu extends StatelessWidget {
  const _EventContextMenu({
    required this.side,
    required this.event,
    required this.onCreatePomodoro,
    required this.onDismiss,
  });

  final double side;
  final CalendarEvent event;
  final VoidCallback onCreatePomodoro;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final m = PanelTheme.metricsOf(context, side, shape: PanelShape.square);

    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onDismiss,
        child: ColoredBox(
          color: Colors.black.withValues(alpha: 0.45),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: side * 0.62),
              child: GestureDetector(
                // Swallow taps on the card so they don't dismiss the menu.
                onTap: () {},
                child: Material(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(m.cardRadius),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: m.cardPaddingMd,
                        child: Text(
                          event.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: panelFont(
                            m.fontSm,
                            m.weightMedium,
                            colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                      Divider(height: 1, color: colors.outlineVariant),
                      InkWell(
                        onTap: onCreatePomodoro,
                        child: Padding(
                          padding: m.cardPaddingMd,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.local_cafe_outlined,
                                size: m.fontMd,
                                color: colors.primary,
                              ),
                              SizedBox(width: m.gap),
                              Flexible(
                                child: Text(
                                  l10n.calendarCreatePomodoro,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: panelFont(
                                    m.fontMd,
                                    m.weightMedium,
                                    colors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A brief, self-dismissing confirmation pill anchored near the foot of the
/// panel. In-tree (see [_EventContextMenu]) so it shows on the physical panel.
class _PanelToast extends StatelessWidget {
  const _PanelToast({required this.side, required this.message});

  final double side;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final m = PanelTheme.metricsOf(context, side, shape: PanelShape.square);

    return Positioned.fill(
      child: IgnorePointer(
        child: Align(
          alignment: const Alignment(0, 0.72),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: side * 0.7),
            child: Material(
              color: colors.inverseSurface,
              borderRadius: BorderRadius.circular(m.cardRadius),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: m.cardPaddingMd.left,
                  vertical: m.cardPaddingMd.top * 0.7,
                ),
                child: Text(
                  message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: panelFont(m.fontSm, m.weightMedium, colors.onInverseSurface),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
