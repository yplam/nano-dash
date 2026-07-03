import '../../domain/models/calendar.dart';
import '../services/calendar/calendar_service.dart';
import 'settings_repository.dart';

/// Owns the calendar module's data: it persists the user's [CalendarConfig]
/// (the list of feeds) through [SettingsRepository], and fetches + merges every
/// enabled feed through [CalendarService], caching the last good merged list.
class CalendarRepository {
  CalendarRepository(this._settings, this._service)
    : _config = _settings.load(calendarSettingsKey);

  final SettingsRepository _settings;
  final CalendarService _service;

  CalendarConfig _config;
  List<CalendarEvent> _events = const [];

  /// How far ahead the agenda reaches; also bounds recurrence expansion.
  static const Duration _horizon = Duration(days: 60);

  /// The current persisted settings.
  CalendarConfig get config => _config;

  /// The last successfully merged events, or empty until the first fetch.
  List<CalendarEvent> get events => _events;

  Future<void> save(CalendarConfig config) {
    _config = config;
    return _settings.save(calendarSettingsKey, config);
  }

  /// Fetch every enabled source, merge and sort by start. Per-source failures
  /// are collected into [CalendarFetchResult.errors] rather than thrown, so a
  /// single bad feed doesn't blank the whole agenda.
  Future<CalendarFetchResult> fetch() async {
    final now = DateTime.now();
    // Start slightly in the past so an event happening right now still shows.
    final windowStart = now.subtract(const Duration(hours: 12));
    final windowEnd = now.add(_horizon);

    final sources = _config.sources.where((s) => s.enabled).toList();
    final merged = <CalendarEvent>[];
    final errors = <String, Object>{};

    await Future.wait(
      sources.map((source) async {
        try {
          final events = await _service.fetch(
            source,
            windowStart: windowStart,
            windowEnd: windowEnd,
          );
          merged.addAll(events);
        } catch (e) {
          errors[source.id] = e;
        }
      }),
    );

    merged.sort((a, b) => a.start.compareTo(b.start));
    _events = merged;
    return CalendarFetchResult(events: merged, errors: errors);
  }
}

/// The outcome of one [CalendarRepository.fetch]: the merged events plus any
/// per-source errors (keyed by [CalendarSource.id]).
class CalendarFetchResult {
  const CalendarFetchResult({required this.events, required this.errors});

  final List<CalendarEvent> events;
  final Map<String, Object> errors;

  bool get hasErrors => errors.isNotEmpty;
}
