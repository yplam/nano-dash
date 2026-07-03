import 'package:flutter_test/flutter_test.dart';
import 'package:nano_dash/data/services/calendar/recurrence.dart';

List<DateTime> expand(
  Recurrence r,
  DateTime start, {
  DateTime? windowEnd,
  Set<int> exDates = const {},
}) =>
    r
        .expand(
          start,
          windowEnd: windowEnd ?? DateTime(2100),
          exDates: exDates,
        )
        .toList();

void main() {
  group('Recurrence.parse', () {
    test('reads FREQ, INTERVAL, COUNT', () {
      final r = Recurrence.parse('FREQ=DAILY;INTERVAL=2;COUNT=5')!;
      expect(r.freq, 'DAILY');
      expect(r.interval, 2);
      expect(r.count, 5);
    });

    test('BYDAY strips ordinal prefixes to weekday ints', () {
      final r = Recurrence.parse('FREQ=WEEKLY;BYDAY=2MO,WE')!;
      expect(r.byDay, [DateTime.monday, DateTime.wednesday]);
    });

    test('missing FREQ yields null', () {
      expect(Recurrence.parse('INTERVAL=1'), isNull);
    });

    test('interval defaults to 1 when absent', () {
      expect(Recurrence.parse('FREQ=DAILY')!.interval, 1);
    });
  });

  group('Recurrence.expand', () {
    test('DAILY;INTERVAL=2 steps two days at a time', () {
      final r = Recurrence.parse('FREQ=DAILY;INTERVAL=2;COUNT=3')!;
      expect(expand(r, DateTime(2026, 1, 1, 8)), [
        DateTime(2026, 1, 1, 8),
        DateTime(2026, 1, 3, 8),
        DateTime(2026, 1, 5, 8),
      ]);
    });

    test('MONTHLY clamps the day into short months', () {
      final r = Recurrence.parse('FREQ=MONTHLY;COUNT=2')!;
      final occ = expand(r, DateTime(2026, 1, 31, 9));
      expect(occ.first, DateTime(2026, 1, 31, 9));
      // Feb 2026 has 28 days, so Jan 31 clamps to Feb 28.
      expect(occ[1], DateTime(2026, 2, 28, 9));
    });

    test('UNTIL bounds the series (inclusive of the boundary day)', () {
      final r = Recurrence.parse('FREQ=DAILY;UNTIL=20260103T090000')!;
      final occ = expand(r, DateTime(2026, 1, 1, 9));
      expect(occ.last, DateTime(2026, 1, 3, 9));
      expect(occ, hasLength(3));
    });

    test('windowEnd stops expansion even without COUNT/UNTIL', () {
      final r = Recurrence.parse('FREQ=DAILY')!;
      final occ = expand(
        r,
        DateTime(2026, 1, 1),
        windowEnd: DateTime(2026, 1, 4),
      );
      expect(occ, hasLength(4)); // Jan 1..4 inclusive of the window end day
    });

    test('exDates skip matching days but COUNT still counts emitted', () {
      final r = Recurrence.parse('FREQ=DAILY;COUNT=3')!;
      final occ = expand(
        r,
        DateTime(2026, 1, 1, 9),
        exDates: {2026 * 10000 + 1 * 100 + 2}, // 2026-01-02
      );
      // COUNT limits emitted occurrences, so excluding Jan 2 pushes a Jan 4 in.
      expect(occ, [
        DateTime(2026, 1, 1, 9),
        DateTime(2026, 1, 3, 9),
        DateTime(2026, 1, 4, 9),
      ]);
    });
  });
}
