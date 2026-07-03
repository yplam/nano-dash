import 'ics_date_time.dart';

/// A minimal `RRULE`: frequency + interval, bounded by `COUNT`/`UNTIL`, with
/// optional `BYDAY` for weekly rules. Exotic parts (`BYSETPOS`, `BYMONTHDAY`,
/// etc.) are ignored — the common repeating cases are covered.
class Recurrence {
  Recurrence({
    required this.freq,
    required this.interval,
    this.count,
    this.until,
    this.byDay = const [],
  });

  final String freq; // DAILY | WEEKLY | MONTHLY | YEARLY
  final int interval;
  final int? count;
  final DateTime? until; // local
  final List<int> byDay; // DateTime weekday ints (Mon=1..Sun=7)

  /// Hard cap on generated occurrences, so a malformed unbounded rule can't spin.
  static const int _maxOccurrences = 1000;

  static Recurrence? parse(String value) {
    final parts = <String, String>{};
    for (final seg in value.split(';')) {
      final eq = seg.indexOf('=');
      if (eq < 0) continue;
      parts[seg.substring(0, eq).toUpperCase()] = seg.substring(eq + 1);
    }
    final freq = parts['FREQ']?.toUpperCase();
    if (freq == null) return null;

    DateTime? until;
    final untilRaw = parts['UNTIL'];
    if (untilRaw != null) {
      until = IcsDateTime.parse(untilRaw, const {})?.local;
    }

    const dayMap = {
      'MO': DateTime.monday,
      'TU': DateTime.tuesday,
      'WE': DateTime.wednesday,
      'TH': DateTime.thursday,
      'FR': DateTime.friday,
      'SA': DateTime.saturday,
      'SU': DateTime.sunday,
    };
    final byDay = <int>[];
    final byDayRaw = parts['BYDAY'];
    if (byDayRaw != null) {
      for (final token in byDayRaw.split(',')) {
        // Strip any ordinal prefix (e.g. "2MO"); take the trailing 2 letters.
        final code = token.length >= 2
            ? token.substring(token.length - 2).toUpperCase()
            : token.toUpperCase();
        final wd = dayMap[code];
        if (wd != null) byDay.add(wd);
      }
    }

    return Recurrence(
      freq: freq,
      interval: int.tryParse(parts['INTERVAL'] ?? '') ?? 1,
      count: int.tryParse(parts['COUNT'] ?? ''),
      until: until,
      byDay: byDay,
    );
  }

  /// Yield occurrence start times from [start] up to [windowEnd] (and no later
  /// than `UNTIL`/`COUNT`), skipping any whose day is in [exDates].
  Iterable<DateTime> expand(
    DateTime start, {
    required DateTime windowEnd,
    required Set<int> exDates,
  }) sync* {
    final step = interval < 1 ? 1 : interval;
    var emitted = 0;
    var generated = 0;

    bool excluded(DateTime d) =>
        exDates.contains(d.year * 10000 + d.month * 100 + d.day);

    bool withinLimits(DateTime d) {
      if (until != null && d.isAfter(until!)) return false;
      if (d.isAfter(windowEnd)) return false;
      if (count != null && emitted >= count!) return false;
      return true;
    }

    if (freq == 'WEEKLY' && byDay.isNotEmpty) {
      // Walk week by week (stepping [interval] weeks); within each active week
      // emit the configured weekdays in order.
      var weekStart = _startOfWeek(start);
      while (generated < _maxOccurrences) {
        for (final wd in byDay) {
          final d = weekStart.add(Duration(days: wd - DateTime.monday));
          final occ = DateTime(
            d.year,
            d.month,
            d.day,
            start.hour,
            start.minute,
            start.second,
          );
          if (occ.isBefore(start)) continue;
          generated++;
          if (!withinLimits(occ)) return;
          if (!excluded(occ)) {
            emitted++;
            yield occ;
          }
        }
        weekStart = weekStart.add(Duration(days: 7 * step));
        if (weekStart.isAfter(windowEnd)) return;
      }
      return;
    }

    var occ = start;
    while (generated < _maxOccurrences) {
      generated++;
      if (!withinLimits(occ)) return;
      if (!excluded(occ)) {
        emitted++;
        yield occ;
      }
      occ = _advance(occ, step);
    }
  }

  DateTime _advance(DateTime d, int step) {
    switch (freq) {
      case 'DAILY':
        return d.add(Duration(days: step));
      case 'WEEKLY':
        return d.add(Duration(days: 7 * step));
      case 'MONTHLY':
        return _addMonths(d, step);
      case 'YEARLY':
        return _addMonths(d, 12 * step);
      default:
        // Unknown frequency: jump past the window to stop.
        return d.add(const Duration(days: 3650));
    }
  }

  static DateTime _addMonths(DateTime d, int months) {
    final total = d.month - 1 + months;
    final year = d.year + total ~/ 12;
    final month = total % 12 + 1;
    // Clamp the day so e.g. Jan 31 + 1 month → Feb 28/29.
    final lastDay = DateTime(year, month + 1, 0).day;
    final day = d.day > lastDay ? lastDay : d.day;
    return DateTime(year, month, day, d.hour, d.minute, d.second);
  }

  static DateTime _startOfWeek(DateTime d) {
    final date = DateTime(d.year, d.month, d.day);
    return date.subtract(Duration(days: date.weekday - DateTime.monday));
  }
}
