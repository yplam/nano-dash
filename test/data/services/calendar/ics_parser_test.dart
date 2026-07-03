import 'package:flutter_test/flutter_test.dart';
import 'package:nano_dash/data/services/calendar/ics_date_time.dart';
import 'package:nano_dash/data/services/calendar/ics_parser.dart';
import 'package:nano_dash/domain/models/calendar.dart';

/// A test source; the parser only reads [CalendarSource.id] and `.color`.
const _source = CalendarSource(id: 'src1', url: 'https://x', color: 0xFF00FF00);

/// Wrap loose `VEVENT` bodies in a VCALENDAR and parse over an (optionally
/// narrowed) window. Defaults span a wide range so nothing is filtered out.
List<CalendarEvent> parse(
  String veventBody, {
  DateTime? windowStart,
  DateTime? windowEnd,
}) {
  final ics =
      'BEGIN:VCALENDAR\r\nVERSION:2.0\r\n$veventBody\r\nEND:VCALENDAR\r\n';
  return IcsParser.parse(
    ics,
    source: _source,
    windowStart: windowStart ?? DateTime(2000),
    windowEnd: windowEnd ?? DateTime(2100),
  );
}

String vevent(String body) => 'BEGIN:VEVENT\r\n$body\r\nEND:VEVENT';

void main() {
  group('IcsParser — single events', () {
    test('parses a timed event with DTEND (floating local wall-clock)', () {
      final events = parse(
        vevent('UID:1\r\nSUMMARY:Standup\r\n'
            'DTSTART:20260101T090000\r\nDTEND:20260101T093000'),
      );
      expect(events, hasLength(1));
      final e = events.single;
      expect(e.uid, '1');
      expect(e.title, 'Standup');
      expect(e.allDay, isFalse);
      expect(e.start, DateTime(2026, 1, 1, 9));
      expect(e.end, DateTime(2026, 1, 1, 9, 30));
      expect(e.sourceId, 'src1');
      expect(e.color, 0xFF00FF00);
    });

    test('a VALUE=DATE event is all-day and spans one day', () {
      final e = parse(
        vevent('UID:2\r\nSUMMARY:Holiday\r\nDTSTART;VALUE=DATE:20260101'),
      ).single;
      expect(e.allDay, isTrue);
      expect(e.start, DateTime(2026, 1, 1));
      expect(e.end, DateTime(2026, 1, 2));
    });

    test('a trailing Z is UTC, resolved to local time', () {
      final e = parse(
        vevent('UID:3\r\nSUMMARY:Call\r\n'
            'DTSTART:20260101T120000Z\r\nDTEND:20260101T130000Z'),
      ).single;
      expect(e.start, DateTime.utc(2026, 1, 1, 12).toLocal());
      expect(e.end, DateTime.utc(2026, 1, 1, 13).toLocal());
    });

    test('DURATION supplies the length when DTEND is absent', () {
      final e = parse(
        vevent('UID:4\r\nSUMMARY:Focus\r\n'
            'DTSTART:20260101T090000\r\nDURATION:PT1H30M'),
      ).single;
      expect(e.end.difference(e.start), const Duration(hours: 1, minutes: 30));
    });

    test('folded (continued) lines are unfolded before parsing', () {
      final e = parse(
        vevent('UID:5\r\nSUMMARY:Team\r\n Sync\r\nDTSTART:20260101T090000'),
      ).single;
      expect(e.title, 'TeamSync');
    });

    test('escaped text (\\n, \\,) is unescaped', () {
      final e = parse(
        vevent('UID:6\r\nSUMMARY:a\\, b\\nc\r\nDTSTART:20260101T090000'),
      ).single;
      expect(e.title, 'a, b\nc');
    });

    test('a RECURRENCE-ID override is skipped', () {
      final events = parse(
        vevent('UID:7\r\nSUMMARY:Moved\r\n'
            'RECURRENCE-ID:20260101T090000\r\nDTSTART:20260101T100000'),
      );
      expect(events, isEmpty);
    });
  });

  group('IcsParser — window filtering', () {
    test('events outside [windowStart, windowEnd) are dropped', () {
      final body = vevent('UID:8\r\nSUMMARY:Old\r\n'
          'DTSTART:20250101T090000\r\nDTEND:20250101T100000');
      expect(
        parse(body, windowStart: DateTime(2026), windowEnd: DateTime(2027)),
        isEmpty,
      );
      expect(
        parse(body, windowStart: DateTime(2025), windowEnd: DateTime(2026)),
        hasLength(1),
      );
    });
  });

  group('IcsParser — recurrence expansion', () {
    test('DAILY;COUNT=3 yields three consecutive days', () {
      final events = parse(
        vevent('UID:9\r\nSUMMARY:Daily\r\n'
            'DTSTART:20260101T090000\r\nRRULE:FREQ=DAILY;COUNT=3'),
      );
      expect(events.map((e) => e.start), [
        DateTime(2026, 1, 1, 9),
        DateTime(2026, 1, 2, 9),
        DateTime(2026, 1, 3, 9),
      ]);
    });

    test('WEEKLY;BYDAY=MO,WE expands the configured weekdays', () {
      // 2026-01-05 is a Monday.
      final events = parse(
        vevent('UID:10\r\nSUMMARY:Class\r\n'
            'DTSTART:20260105T090000\r\nRRULE:FREQ=WEEKLY;BYDAY=MO,WE;COUNT=4'),
      );
      expect(events.map((e) => e.start), [
        DateTime(2026, 1, 5, 9), // Mon
        DateTime(2026, 1, 7, 9), // Wed
        DateTime(2026, 1, 12, 9), // Mon
        DateTime(2026, 1, 14, 9), // Wed
      ]);
    });

    test('EXDATE removes a matching occurrence', () {
      // COUNT bounds the number of *emitted* occurrences, so an excluded day
      // doesn't shrink the series — expansion runs on until three survive.
      final events = parse(
        vevent('UID:11\r\nSUMMARY:Daily\r\n'
            'DTSTART:20260101T090000\r\nRRULE:FREQ=DAILY;COUNT=3\r\n'
            'EXDATE:20260102T090000'),
      );
      expect(events.map((e) => e.start), [
        DateTime(2026, 1, 1, 9),
        DateTime(2026, 1, 3, 9),
        DateTime(2026, 1, 4, 9),
      ]);
    });
  });

  group('IcsDateTime', () {
    test('a bare 8-digit value is a date-only (all-day) local date', () {
      final dt = IcsDateTime.parse('20260101', const {});
      expect(dt, isNotNull);
      expect(dt!.dateOnly, isTrue);
      expect(dt.local, DateTime(2026, 1, 1));
    });

    test('a Z-suffixed value is UTC converted to local', () {
      final dt = IcsDateTime.parse('20260101T120000Z', const {});
      expect(dt!.dateOnly, isFalse);
      expect(dt.local, DateTime.utc(2026, 1, 1, 12).toLocal());
    });

    test('too-short garbage parses to null', () {
      expect(IcsDateTime.parse('bad', const {}), isNull);
    });
  });
}
