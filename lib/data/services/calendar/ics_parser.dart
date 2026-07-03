import '../../../domain/models/calendar.dart';
import 'ics_date_time.dart';
import 'recurrence.dart';

/// A hand-rolled RFC 5545 parser: turns an iCalendar (`.ics`) document into
/// [CalendarEvent]s overlapping a requested window.
///
/// Recurring events ([Recurrence]) are expanded into individual occurrences;
/// `RECURRENCE-ID` overrides are skipped so they don't double up with the
/// series' generated occurrence. Timezone handling is coarse — see [IcsDateTime].
///
/// Pure and I/O-free: fetching the ICS text (over HTTP or CalDAV) is the
/// service's job.
class IcsParser {
  const IcsParser._();

  /// Parse [ics] and return its events overlapping `[windowStart, windowEnd)`,
  /// each stamped with [source]'s id and colour, sorted ascending by start.
  static List<CalendarEvent> parse(
    String ics, {
    required CalendarSource source,
    required DateTime windowStart,
    required DateTime windowEnd,
  }) {
    final lines = _unfold(ics);
    final out = <CalendarEvent>[];

    RawEvent? cur;
    for (final line in lines) {
      if (line == 'BEGIN:VEVENT') {
        cur = RawEvent();
        continue;
      }
      if (line == 'END:VEVENT') {
        if (cur != null) {
          _emit(cur, source, windowStart, windowEnd, out);
        }
        cur = null;
        continue;
      }
      if (cur == null) continue;

      final prop = Property.parse(line);
      if (prop == null) continue;
      switch (prop.name) {
        case 'SUMMARY':
          cur.summary = _unescapeText(prop.value);
        case 'LOCATION':
          cur.location = _unescapeText(prop.value);
        case 'UID':
          cur.uid = prop.value;
        case 'DTSTART':
          cur.start = IcsDateTime.parse(prop.value, prop.params);
        case 'DTEND':
          cur.end = IcsDateTime.parse(prop.value, prop.params);
        case 'DURATION':
          cur.duration = _parseDuration(prop.value);
        case 'RRULE':
          cur.rrule = Recurrence.parse(prop.value);
        case 'EXDATE':
          for (final v in prop.value.split(',')) {
            final dt = IcsDateTime.parse(v, prop.params);
            if (dt != null) cur.exDates.add(_dayKey(dt.local));
          }
        case 'RECURRENCE-ID':
          // A single-occurrence override; skip so it doesn't double up with the
          // series' generated occurrence.
          cur.isOverride = true;
      }
    }

    // Sort ascending by start so callers can merge feeds cheaply.
    out.sort((a, b) => a.start.compareTo(b.start));
    return out;
  }

  static void _emit(
    RawEvent raw,
    CalendarSource source,
    DateTime windowStart,
    DateTime windowEnd,
    List<CalendarEvent> out,
  ) {
    final start = raw.start;
    if (raw.isOverride || start == null) return;
    final title = (raw.summary ?? '').trim();

    // Duration of the occurrence: DTEND − DTSTART, or explicit DURATION, or a
    // sensible default (all-day → 1 day, timed → zero-length).
    Duration length;
    if (raw.end != null) {
      length = raw.end!.local.difference(start.local);
    } else if (raw.duration != null) {
      length = raw.duration!;
    } else {
      length = start.dateOnly ? const Duration(days: 1) : Duration.zero;
    }
    if (length.isNegative) length = Duration.zero;

    CalendarEvent build(DateTime occStart) {
      return CalendarEvent(
        uid: raw.uid ?? '',
        title: title.isEmpty ? '(untitled)' : title,
        start: occStart,
        end: occStart.add(length),
        allDay: start.dateOnly,
        location: raw.location,
        sourceId: source.id,
        color: source.color,
      );
    }

    void addIfInWindow(DateTime occStart) {
      final occEnd = occStart.add(length);
      // Overlap test against the window (end is exclusive).
      if (occEnd.isAfter(windowStart) && occStart.isBefore(windowEnd)) {
        out.add(build(occStart));
      }
    }

    final rrule = raw.rrule;
    if (rrule == null) {
      addIfInWindow(start.local);
      return;
    }

    for (final occStart in rrule.expand(
      start.local,
      windowEnd: windowEnd,
      exDates: raw.exDates,
    )) {
      addIfInWindow(occStart);
    }
  }

  /// RFC 5545 line unfolding: a line beginning with a space or tab continues the
  /// previous one. Handles both CRLF and LF endings.
  static List<String> _unfold(String ics) {
    final rawLines = ics
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .split('\n');
    final out = <String>[];
    for (final line in rawLines) {
      if (line.isEmpty) continue;
      if ((line.startsWith(' ') || line.startsWith('\t')) && out.isNotEmpty) {
        out[out.length - 1] += line.substring(1);
      } else {
        out.add(line);
      }
    }
    return out;
  }

  static String _unescapeText(String v) {
    final sb = StringBuffer();
    for (var i = 0; i < v.length; i++) {
      final c = v[i];
      if (c == r'\' && i + 1 < v.length) {
        final next = v[i + 1];
        switch (next) {
          case 'n':
          case 'N':
            sb.write('\n');
          case ',':
            sb.write(',');
          case ';':
            sb.write(';');
          case r'\':
            sb.write(r'\');
          default:
            sb.write(next);
        }
        i++;
      } else {
        sb.write(c);
      }
    }
    return sb.toString();
  }

  /// Parse an ICS `DURATION` (e.g. `PT1H`, `P1DT2H`, `-PT15M`). Best-effort;
  /// returns null on anything unrecognised.
  static Duration? _parseDuration(String v) {
    final m = RegExp(
      r'^(?<sign>[+-]?)P(?:(?<w>\d+)W)?(?:(?<d>\d+)D)?'
      r'(?:T(?:(?<h>\d+)H)?(?:(?<m>\d+)M)?(?:(?<s>\d+)S)?)?$',
    ).firstMatch(v.trim());
    if (m == null) return null;
    int g(String n) => int.tryParse(m.namedGroup(n) ?? '') ?? 0;
    var d = Duration(
      days: g('w') * 7 + g('d'),
      hours: g('h'),
      minutes: g('m'),
      seconds: g('s'),
    );
    if (m.namedGroup('sign') == '-') d = -d;
    return d;
  }

  static int _dayKey(DateTime d) => d.year * 10000 + d.month * 100 + d.day;
}

/// A property line split into name, parameters, and value: `NAME;PARAM=x:value`.
class Property {
  Property(this.name, this.params, this.value);

  final String name;
  final Map<String, String> params;
  final String value;

  static Property? parse(String line) {
    final colon = line.indexOf(':');
    if (colon < 0) return null;
    final head = line.substring(0, colon);
    final value = line.substring(colon + 1);

    final segs = head.split(';');
    final name = segs.first.toUpperCase();
    final params = <String, String>{};
    for (var i = 1; i < segs.length; i++) {
      final eq = segs[i].indexOf('=');
      if (eq < 0) continue;
      params[segs[i].substring(0, eq).toUpperCase()] = segs[i].substring(
        eq + 1,
      );
    }
    return Property(name, params, value);
  }
}

/// Accumulates the properties of one `VEVENT` before it's turned into
/// [CalendarEvent]s.
class RawEvent {
  String? uid;
  String? summary;
  String? location;
  IcsDateTime? start;
  IcsDateTime? end;
  Duration? duration;
  Recurrence? rrule;
  bool isOverride = false;
  final Set<int> exDates = {};
}
