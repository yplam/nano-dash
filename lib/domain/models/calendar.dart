import 'json_model.dart';

/// A single calendar occurrence, normalized from an ICS `VEVENT` (a recurring
/// event expands to one [CalendarEvent] per occurrence). Times are stored as
/// local wall-clock [DateTime]s; see [CalendarService] for how ICS UTC/floating/
/// date-only values are resolved.
class CalendarEvent {
  const CalendarEvent({
    required this.uid,
    required this.title,
    required this.start,
    required this.end,
    this.allDay = false,
    this.location,
    required this.sourceId,
    required this.color,
  });

  /// The event's ICS `UID`; for a recurring event the same `UID` repeats across
  /// occurrences, so it is not unique on its own.
  final String uid;
  final String title;

  /// Local start time. For an all-day event this is local midnight of the day.
  final DateTime start;

  /// Local end time (exclusive). Always present: derived from `DTEND`,
  /// `DURATION`, or defaulted (all-day → +1 day, timed → same as [start]).
  final DateTime end;
  final bool allDay;
  final String? location;

  /// Which [CalendarSource] this came from, and that source's display colour
  /// (ARGB int) so the UI can dot events by calendar.
  final String sourceId;
  final int color;

  /// Whether the event covers more than one calendar day.
  bool get isMultiDay {
    final s = DateTime(start.year, start.month, start.day);
    // All-day end is exclusive, so subtract an instant before comparing days.
    final effectiveEnd = allDay ? end.subtract(const Duration(seconds: 1)) : end;
    final e = DateTime(effectiveEnd.year, effectiveEnd.month, effectiveEnd.day);
    return e.isAfter(s);
  }

  /// A one-line, human-readable summary, suitable for feeding to the chat agent
  /// as context (mirrors `WeatherData.summary`).
  String summary() {
    String two(int v) => v.toString().padLeft(2, '0');
    final when = allDay
        ? '${start.year}-${two(start.month)}-${two(start.day)} (all day)'
        : '${start.year}-${two(start.month)}-${two(start.day)} '
              '${two(start.hour)}:${two(start.minute)}';
    final parts = <String>[
      '$when: $title',
      if (location != null && location!.isNotEmpty) '@ $location',
    ];
    return parts.join(' ');
  }
}

/// How a [CalendarSource] is fetched: [ics] is an HTTP `GET` of a published
/// `.ics` feed; [caldav] is a basic CalDAV `calendar-query` `REPORT` against a
/// calendar collection URL. Both may carry optional Basic-auth credentials.
enum CalendarKind {
  ics,
  caldav;

  static CalendarKind fromName(String? name) {
    return CalendarKind.values.firstWhere(
      (k) => k.name == name,
      orElse: () => CalendarKind.ics,
    );
  }
}

/// One configured calendar feed: its URL, how to fetch it, optional credentials,
/// and a display colour. Persisted as part of [CalendarConfig].
class CalendarSource implements JsonModel {
  const CalendarSource({
    required this.id,
    required this.url,
    this.label = '',
    this.kind = CalendarKind.ics,
    this.username,
    this.password,
    this.proxy,
    this.color = defaultColor,
    this.enabled = true,
  });

  /// Material blue 500 (ARGB), used when a source hasn't been assigned a colour.
  static const int defaultColor = 0xFF2196F3;

  /// Stable id (persistence + per-event `sourceId`); generated when the source
  /// is created, never derived from [url] so the URL can be edited in place.
  final String id;
  final String url;

  /// Optional user-facing name; when blank the UI falls back to the URL host.
  final String label;
  final CalendarKind kind;

  /// Optional HTTP Basic-auth credentials for a protected feed.
  final String? username;
  final String? password;

  /// Optional HTTP/SOCKS proxy to route this feed's requests through, e.g.
  /// `host:port`, `http://host:port`, or `socks5://host:port`. When null or
  /// blank the request goes direct. Ignored on the web build (no proxy support).
  final String? proxy;

  /// ARGB colour for this calendar's events.
  final int color;
  final bool enabled;

  CalendarSource copyWith({
    String? url,
    String? label,
    CalendarKind? kind,
    String? username,
    String? password,
    String? proxy,
    int? color,
    bool? enabled,
  }) {
    return CalendarSource(
      id: id,
      url: url ?? this.url,
      label: label ?? this.label,
      kind: kind ?? this.kind,
      username: username ?? this.username,
      password: password ?? this.password,
      proxy: proxy ?? this.proxy,
      color: color ?? this.color,
      enabled: enabled ?? this.enabled,
    );
  }

  factory CalendarSource.fromJson(Map<String, Object?> json) {
    return CalendarSource(
      id: json['id'] as String? ?? '',
      url: json['url'] as String? ?? '',
      label: json['label'] as String? ?? '',
      kind: CalendarKind.fromName(json['kind'] as String?),
      username: json['username'] as String?,
      password: json['password'] as String?,
      proxy: json['proxy'] as String?,
      color: (json['color'] as num?)?.toInt() ?? defaultColor,
      enabled: json['enabled'] as bool? ?? true,
    );
  }

  @override
  Map<String, Object?> toJson() => {
    'id': id,
    'url': url,
    'label': label,
    'kind': kind.name,
    if (username != null) 'username': username,
    if (password != null) 'password': password,
    if (proxy != null) 'proxy': proxy,
    'color': color,
    'enabled': enabled,
  };
}

/// How far ahead the agenda lists events: [today] shows only today's events,
/// [todayAndTomorrow] shows today and tomorrow, and [all] shows the full
/// upcoming window. This is a display filter over the already-fetched events;
/// it doesn't change what is fetched.
enum CalendarRange {
  today,
  todayAndTomorrow,
  all;

  static CalendarRange fromName(String? name) {
    return CalendarRange.values.firstWhere(
      (r) => r.name == name,
      orElse: () => CalendarRange.all,
    );
  }
}

/// The persisted calendar settings: the user's ordered list of feeds and how
/// far ahead the agenda should list events.
class CalendarConfig implements JsonModel {
  const CalendarConfig({
    this.sources = const [],
    this.range = CalendarRange.all,
  });

  final List<CalendarSource> sources;

  /// Display window for the agenda; defaults to [CalendarRange.all] so existing
  /// configs keep their previous behaviour.
  final CalendarRange range;

  CalendarConfig copyWith({List<CalendarSource>? sources, CalendarRange? range}) =>
      CalendarConfig(
        sources: sources ?? this.sources,
        range: range ?? this.range,
      );

  factory CalendarConfig.fromJson(Map<String, Object?> json) {
    final raw = json['sources'];
    final sources = raw is List
        ? raw
              .whereType<Map>()
              .map((e) => CalendarSource.fromJson(Map<String, Object?>.from(e)))
              .toList()
        : <CalendarSource>[];
    return CalendarConfig(
      sources: sources,
      range: CalendarRange.fromName(json['range'] as String?),
    );
  }

  @override
  Map<String, Object?> toJson() => {
    'sources': [for (final s in sources) s.toJson()],
    'range': range.name,
  };
}

/// Persistence handle for [CalendarConfig].
const calendarSettingsKey = SettingKey<CalendarConfig>(
  'calendar_config_v1',
  CalendarConfig.fromJson,
  defaults: CalendarConfig(),
);
