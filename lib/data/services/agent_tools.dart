import 'dart:convert';

import '../../domain/models/calendar.dart';
import '../../domain/models/timer.dart';
import '../repositories/calendar_repository.dart';
import '../repositories/markets_repository.dart';
import '../repositories/reminder_repository.dart';
import '../repositories/timer_repository.dart';
import '../repositories/weather_repository.dart';
import 'agent_service.dart';
import 'panel_display_controller.dart';

const _weatherModuleId = 'weather';
const _calendarModuleId = 'calendar';
const _marketsModuleId = 'markets';
const _timerModuleId = 'timer';

List<AgentTool> buildAgentTools({
  WeatherRepository? weather,
  CalendarRepository? calendar,
  MarketsRepository? markets,
  TimerRepository? timers,
  ReminderRepository? reminders,
  PanelDisplayController? display,
  String Function(TimerConfig config)? timerName,
}) {
  // Resolves a preset's display name where no localization is available; a
  // caller with l10n access should pass the properly localized resolver.
  final nameOf =
      timerName ??
      ((TimerConfig t) => t.name.isNotEmpty ? t.name : (t.labelKey ?? t.id));
  return [
    AgentTool(
      name: 'get_current_time',
      description:
          'The current local date and time, with weekday and timezone.',
      parameters: const {'type': 'object', 'properties': {}},
      run: (_) async {
        final now = DateTime.now();
        const weekdays = [
          'Monday',
          'Tuesday',
          'Wednesday',
          'Thursday',
          'Friday',
          'Saturday',
          'Sunday',
        ];
        return jsonEncode({
          'local': now.toIso8601String(),
          'weekday': weekdays[now.weekday - 1],
          'timezone': now.timeZoneName,
        });
      },
    ),
    if (weather != null)
      AgentTool(
        name: 'get_weather',
        description:
            'Current conditions, air quality and a daily forecast for a city. '
            'Temperatures are Celsius. Omit city for the user\'s configured '
            'home city.',
        parameters: const {
          'type': 'object',
          'properties': {
            'city': {
              'type': 'string',
              'description': 'City name, e.g. "Tokyo". Omit for the home city.',
            },
          },
        },
        run: (args) async {
          final city = (args['city'] as String?)?.trim();
          final data = await weather.fetch(
            city == null || city.isEmpty ? weather.config.city : city,
          );
          display?.show(_weatherModuleId);
          return jsonEncode({
            'city': data.city,
            'temperatureC': data.temperatureC,
            'feelsLikeC': data.apparentTemperatureC,
            'condition': data.condition.name,
            'humidityPercent': data.humidity,
            'windSpeedKmh': data.windSpeedKmh,
            if (data.airQuality != null)
              'airQuality': data.airQuality!.levelLabel,
            'dailyForecast': [
              for (final day in data.daily)
                {
                  'date': day.date.toIso8601String().substring(0, 10),
                  'condition': day.condition.name,
                  'maxC': day.tempMaxC,
                  'minC': day.tempMinC,
                  if (day.precipitationProbability != null)
                    'precipitationPercent': day.precipitationProbability,
                },
            ],
          });
        },
      ),
    if (calendar != null)
      AgentTool(
        name: 'get_calendar_events',
        description:
            'The user\'s upcoming calendar events (title, start/end, '
            'location), soonest first.',
        parameters: const {'type': 'object', 'properties': {}},
        run: (_) async {
          final result = await calendar.fetch();
          display?.show(_calendarModuleId);
          final now = DateTime.now();
          final upcoming =
              result.events.where((e) => e.end.isAfter(now)).toList()
                ..sort((a, b) => a.start.compareTo(b.start));
          return jsonEncode({
            'events': [
              for (final event in upcoming.take(20))
                {
                  'title': event.title,
                  'start': event.start.toIso8601String(),
                  'end': event.end.toIso8601String(),
                  if (event.allDay) 'allDay': true,
                  if (event.location != null) 'location': event.location,
                },
            ],
            if (result.hasErrors)
              'note': 'some calendar sources failed to load',
          });
        },
      ),
    if (timers != null) ...[
      AgentTool(
        name: 'list_timers',
        description:
            'The configured countdown/Pomodoro timers by name, plus the state '
            'of the one currently armed (remaining time, running or not).',
        parameters: const {'type': 'object', 'properties': {}},
        run: (_) async {
          display?.show(_timerModuleId);
          return jsonEncode({
            'timers': [
              for (final t in timers.timers)
                {
                  'name': nameOf(t),
                  'minutes': t.duration.inSeconds / 60,
                  if (t.pomodoro) 'pomodoro': true,
                },
            ],
            'active': _timerStatus(timers, nameOf),
          });
        },
      ),
      AgentTool(
        name: 'create_timer',
        description:
            'Create a new named countdown (or Pomodoro) timer and, by '
            'default, start it immediately. For "a timer until 15:00", '
            'compute the minutes from the current time. The timer is saved '
            'to the user\'s timer list.',
        parameters: const {
          'type': 'object',
          'properties': {
            'name': {
              'type': 'string',
              'description': 'Short display name, in the user\'s language.',
            },
            'minutes': {
              'type': 'number',
              'description':
                  'Countdown length in minutes (the focus length for a '
                  'Pomodoro). Fractions allowed.',
            },
            'pomodoro': {
              'type': 'boolean',
              'description':
                  'Run as a Pomodoro cycle with breaks instead of a plain '
                  'countdown. Default false.',
            },
            'start': {
              'type': 'boolean',
              'description': 'Start it right away. Default true.',
            },
          },
          'required': ['name', 'minutes'],
        },
        run: (args) async {
          final name = (args['name'] as String?)?.trim() ?? '';
          final minutes = (args['minutes'] as num?)?.toDouble() ?? 0;
          if (name.isEmpty || minutes <= 0) {
            return 'Error: a name and a positive number of minutes are '
                'required.';
          }
          final config = TimerConfig(
            id: TimerConfig.newId(),
            name: name,
            duration: Duration(seconds: (minutes * 60).round()),
            pomodoro: args['pomodoro'] as bool? ?? false,
          );
          await timers.saveTimers([...timers.timers, config]);
          if (args['start'] as bool? ?? true) {
            timers.select(config.id, name);
            timers.start();
          }
          display?.show(_timerModuleId);
          return jsonEncode({
            'created': name,
            'active': _timerStatus(timers, nameOf),
          });
        },
      ),
      AgentTool(
        name: 'start_timer',
        description:
            'Start (or resume) one of the configured timers by name. Use '
            'list_timers to see the names; use create_timer for a length '
            'that has no preset.',
        parameters: const {
          'type': 'object',
          'properties': {
            'name': {
              'type': 'string',
              'description': 'The timer\'s name, as shown by list_timers.',
            },
          },
          'required': ['name'],
        },
        run: (args) async {
          final query = (args['name'] as String?)?.trim() ?? '';
          final match = _findTimer(timers.timers, nameOf, query);
          if (match == null) {
            final names = timers.timers.map(nameOf).join(', ');
            return 'No timer named "$query". Available: $names.';
          }
          timers.select(match.id, nameOf(match));
          timers.start();
          display?.show(_timerModuleId);
          return jsonEncode({'active': _timerStatus(timers, nameOf)});
        },
      ),
      AgentTool(
        name: 'pause_timer',
        description: 'Pause the running countdown, keeping its remaining time.',
        parameters: const {'type': 'object', 'properties': {}},
        run: (_) async {
          if (!timers.run.running) return 'No timer is running.';
          timers.pause();
          display?.show(_timerModuleId);
          return jsonEncode({'active': _timerStatus(timers, nameOf)});
        },
      ),
      AgentTool(
        name: 'reset_timer',
        description:
            'Stop the armed timer and restore its full configured duration.',
        parameters: const {'type': 'object', 'properties': {}},
        run: (_) async {
          if (timers.run.selectedId == null) return 'No timer is armed.';
          timers.reset();
          display?.show(_timerModuleId);
          return jsonEncode({'active': _timerStatus(timers, nameOf)});
        },
      ),
      AgentTool(
        name: 'get_pomodoro_stats',
        description:
            'Completed Pomodoro focus sessions per task per day, most recent '
            'first. History covers about two weeks.',
        parameters: const {
          'type': 'object',
          'properties': {
            'days': {
              'type': 'integer',
              'description': 'How many days back to include. Default 7.',
            },
          },
        },
        run: (args) async {
          final days = (args['days'] as num?)?.toInt() ?? 7;
          final cutoff = DateTime.now().subtract(Duration(days: days));
          final recent = [
            for (final log in timers.logs)
              if (log.completedAt.isAfter(cutoff)) log,
          ];
          return jsonEncode([
            for (final row in aggregateDaily(recent))
              {
                'task': row.name,
                'date': row.day.toIso8601String().substring(0, 10),
                'focusMinutes': row.focus.inMinutes,
                'sessions': row.sessions,
              },
          ]);
        },
      ),
    ],
    if (reminders != null) ...[
      AgentTool(
        name: 'set_reminder',
        description:
            'Schedule a spoken reminder for a specific time. The device will '
            'announce the text aloud when it comes due. Compute the absolute '
            'time from the current local time for relative requests like '
            '"in 20 minutes".',
        parameters: const {
          'type': 'object',
          'properties': {
            'text': {
              'type': 'string',
              'description':
                  'The reminder subject itself — the thing to be done or '
                  'noted — in the user\'s language, phrased for speaking '
                  'aloud. Extract just the substance of the request: drop the '
                  'meta-framing ("remind me to", "don\'t let me forget", '
                  '"tell me to") and the time phrase, keeping the core task. '
                  'E.g. "Remind me to start working in 5 minutes" -> "Start '
                  'working"; "Don\'t let me forget to call Mom tonight" -> '
                  '"Call Mom". Keep it short, like a to-do item, but never '
                  'invent details the user did not say.',
            },
            'time': {
              'type': 'string',
              'description':
                  'Local date-time in ISO 8601, e.g. "2026-07-11T15:30". '
                  'Must be in the future.',
            },
          },
          'required': ['text', 'time'],
        },
        run: (args) async {
          final text = (args['text'] as String?)?.trim() ?? '';
          final dueAt = DateTime.tryParse((args['time'] as String?) ?? '');
          if (text.isEmpty || dueAt == null) {
            return 'Error: text and an ISO 8601 time are required.';
          }
          final now = DateTime.now();
          if (!dueAt.isAfter(now)) {
            return 'Error: $dueAt is not in the future (now: $now).';
          }
          final reminder = await reminders.add(text, dueAt);
          return jsonEncode({
            'id': reminder.id,
            'text': reminder.text,
            'dueAt': reminder.dueAt.toIso8601String(),
          });
        },
      ),
      AgentTool(
        name: 'list_reminders',
        description: 'The pending reminders, soonest first.',
        parameters: const {'type': 'object', 'properties': {}},
        run: (_) async => jsonEncode([
          for (final reminder in reminders.reminders)
            {
              'id': reminder.id,
              'text': reminder.text,
              'dueAt': reminder.dueAt.toIso8601String(),
            },
        ]),
      ),
      AgentTool(
        name: 'cancel_reminder',
        description:
            'Cancel a pending reminder by id (get the id from '
            'list_reminders).',
        parameters: const {
          'type': 'object',
          'properties': {
            'id': {'type': 'string', 'description': 'The reminder\'s id.'},
          },
          'required': ['id'],
        },
        run: (args) async {
          final id = (args['id'] as String?)?.trim() ?? '';
          final removed = await reminders.cancel(id);
          return removed
              ? 'Cancelled.'
              : 'No pending reminder with id "$id". Use list_reminders.';
        },
      ),
    ],
    if (markets != null)
      AgentTool(
        name: 'get_market_quotes',
        description:
            'Latest prices for the market symbols the user follows (stocks, '
            'indices, crypto), with change from the previous close.',
        parameters: const {'type': 'object', 'properties': {}},
        run: (_) async {
          final quotes = await markets.fetch();
          display?.show(_marketsModuleId);
          return jsonEncode([
            for (final quote in quotes)
              {
                'symbol': quote.symbol,
                'name': quote.displayName,
                'price': quote.price,
                'change': quote.change,
                'changePercent': quote.changePercent,
                if (quote.currency != null) 'currency': quote.currency,
              },
          ]);
        },
      ),
  ];
}

/// The dedicated "put a page on the screen" tool, kept separate from the data
/// tools' auto-display so the assistant can show a page that needs no data fetch
/// (e.g. the clock) and so it can be offered to the light model too.
///
AgentTool buildDisplayTool(
  PanelDisplayController display, {
  required Map<String, String> modules,
}) {
  final ids = modules.keys.toList();
  final catalogue = [
    for (final entry in modules.entries) '${entry.key} (${entry.value})',
  ].join(', ');
  return AgentTool(
    name: 'show_on_screen',
    description:
        'Show a module\'s page on the device screen for the user to look at — '
        'use it when they ask to see something, or alongside your answer when '
        'a page would help. The page returns to the previous one on a swipe or '
        'after a short while. Modules (id and what it shows): $catalogue.',
    parameters: {
      'type': 'object',
      'properties': {
        'module': {
          'type': 'string',
          'enum': ids,
          'description': 'Which module page to show.',
        },
      },
      'required': ['module'],
    },
    run: (args) async {
      final id = (args['module'] as String?)?.trim() ?? '';
      if (!display.canShow(id)) {
        final available = display.displayable.join(', ');
        return 'Error: "$id" cannot be shown right now. Available: '
            '${available.isEmpty ? 'none' : available}.';
      }
      display.show(id);
      return jsonEncode({'shown': id});
    },
  );
}

/// A compact plain-text snapshot of the user's live device state.
String? buildAgentContext({
  WeatherRepository? weather,
  CalendarRepository? calendar,
  TimerRepository? timers,
  ReminderRepository? reminders,
  String Function(TimerConfig config)? timerName,
}) {
  final nameOf =
      timerName ??
      ((TimerConfig t) => t.name.isNotEmpty ? t.name : (t.labelKey ?? t.id));
  final now = DateTime.now();
  final sections = <String>[];

  final w = weather?.current;
  if (w != null) {
    final line = StringBuffer('Weather (as of ${_hhmm(weather!.fetchedAt)}): ')
      ..write(w.summary());
    sections.add(line.toString());
    final days = w.daily.take(2).toList();
    if (days.isNotEmpty) {
      final parts = [
        for (final d in days)
          '${_mmdd(d.date)} ${d.condition.name} '
              '${d.tempMinC.round()}–${d.tempMaxC.round()}°C'
              '${d.precipitationProbability != null ? ' (rain ${d.precipitationProbability}%)' : ''}',
      ];
      sections.add('Forecast: ${parts.join('; ')}.');
    }
  }

  final events = calendar?.events;
  if (events != null && events.isNotEmpty) {
    // Today and tomorrow only: from now to the end of tomorrow, capped.
    final windowEnd = DateTime(now.year, now.month, now.day + 2);
    final soon =
        events
            .where((e) => e.end.isAfter(now) && e.start.isBefore(windowEnd))
            .toList()
          ..sort((a, b) => a.start.compareTo(b.start));
    if (soon.isNotEmpty) {
      final lines = [for (final e in soon.take(8)) '- ${_eventLine(e)}'];
      sections.add(
        'Calendar (as of ${_hhmm(calendar!.fetchedAt)}), today and tomorrow:\n'
        '${lines.join('\n')}',
      );
    }
  }

  if (timers != null && timers.timers.isNotEmpty) {
    final presets = [
      for (final t in timers.timers)
        '${nameOf(t)} ${_dur(t.duration)}${t.pomodoro ? ' (Pomodoro)' : ''}',
    ].join(', ');
    final active = _activeTimerLine(timers, nameOf);
    sections.add(
      'Timers: $presets.${active == null ? '' : ' Active: $active'}',
    );
  }

  final pending = reminders?.reminders ?? const [];
  if (pending.isNotEmpty) {
    final lines = [
      for (final r in pending.take(10)) '- ${r.text}, ${_stamp(r.dueAt)}',
    ];
    sections.add('Pending reminders:\n${lines.join('\n')}');
  }

  if (sections.isEmpty) return null;
  return sections.join('\n');
}

String _two(int n) => n.toString().padLeft(2, '0');

/// `HH:MM`, or `unknown` when no timestamp was recorded.
String _hhmm(DateTime? t) =>
    t == null ? 'unknown' : '${_two(t.hour)}:${_two(t.minute)}';

/// `MM-DD` local calendar day.
String _mmdd(DateTime t) => '${_two(t.month)}-${_two(t.day)}';

/// `MM-DD HH:MM` for an absolute moment.
String _stamp(DateTime t) => '${_mmdd(t)} ${_hhmm(t)}';

/// A compact human duration: `90m` as `1h30m`, sub-hour as `Ns`/`Nm`.
String _dur(Duration d) {
  if (d.inHours > 0) {
    final m = d.inMinutes.remainder(60);
    return m == 0 ? '${d.inHours}h' : '${d.inHours}h${m}m';
  }
  if (d.inMinutes > 0) {
    final s = d.inSeconds.remainder(60);
    return s == 0 ? '${d.inMinutes}m' : '${d.inMinutes}m${s}s';
  }
  return '${d.inSeconds}s';
}

String _eventLine(CalendarEvent e) {
  final when = e.allDay
      ? '${_mmdd(e.start)} (all day)'
      : '${_stamp(e.start)}–${_hhmm(e.end)}';
  return '${e.title}, $when${e.location != null ? ', ${e.location}' : ''}';
}

/// A one-line summary of the armed timer's live state, or null when none is
/// armed.
String? _activeTimerLine(
  TimerRepository timers,
  String Function(TimerConfig config) nameOf,
) {
  final run = timers.run;
  final selected = timers.selected;
  if (selected == null) return null;
  final name = run.selectedName.isNotEmpty
      ? run.selectedName
      : nameOf(selected);
  final state = run.finished
      ? 'finished'
      : (run.running ? 'running' : 'paused');
  final buf = StringBuffer('$name — ${_dur(run.remaining)} left, $state');
  if (selected.pomodoro) {
    buf.write(', ${run.phase.name} phase, ${run.completedFocus} focus done');
  }
  return buf.toString();
}

/// The armed timer's state as the model should see it, or null when nothing
/// is armed.
Map<String, Object?>? _timerStatus(
  TimerRepository timers,
  String Function(TimerConfig config) nameOf,
) {
  final run = timers.run;
  final selected = timers.selected;
  if (selected == null) return null;
  return {
    'name': run.selectedName.isNotEmpty ? run.selectedName : nameOf(selected),
    'remainingSeconds': run.remaining.inSeconds,
    'running': run.running,
    'finished': run.finished,
    if (selected.pomodoro) ...{
      'phase': run.phase.name,
      'completedFocusSessions': run.completedFocus,
    },
  };
}

/// Match a timer by display name: exact (case-insensitive) first, then a
/// unique substring match. Null when nothing (or more than one thing) matches.
TimerConfig? _findTimer(
  List<TimerConfig> timers,
  String Function(TimerConfig config) nameOf,
  String query,
) {
  final q = query.toLowerCase();
  if (q.isEmpty) return null;
  for (final t in timers) {
    if (nameOf(t).toLowerCase() == q) return t;
  }
  final partial = [
    for (final t in timers)
      if (nameOf(t).toLowerCase().contains(q)) t,
  ];
  return partial.length == 1 ? partial.first : null;
}
