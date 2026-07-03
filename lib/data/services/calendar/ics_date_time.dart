/// A parsed ICS date/time, plus how it was expressed, resolved to a local
/// [DateTime].
///
/// Shared by the ICS parser and the recurrence expander (which uses it to read
/// an `RRULE`'s `UNTIL`).
class IcsDateTime {
  IcsDateTime(this.local, {required this.dateOnly});

  final DateTime local;

  /// True when the value was a `VALUE=DATE` (no time) — i.e. an all-day event.
  final bool dateOnly;

  /// Parse an ICS date or date-time. Timezone handling is deliberately coarse
  /// (no tz database): a trailing `Z` is UTC (converted to local); a bare
  /// `VALUE=DATE` is an all-day local date; anything else — floating or `TZID` —
  /// is taken as local wall-clock. Good enough for a glanceable panel agenda.
  static IcsDateTime? parse(String value, Map<String, String> params) {
    final v = value.trim();
    final isDate =
        params['VALUE'] == 'DATE' || (v.length == 8 && !v.contains('T'));
    if (v.length < 8) return null;

    final year = int.tryParse(v.substring(0, 4));
    final month = int.tryParse(v.substring(4, 6));
    final day = int.tryParse(v.substring(6, 8));
    if (year == null || month == null || day == null) return null;

    if (isDate) {
      return IcsDateTime(DateTime(year, month, day), dateOnly: true);
    }

    // Expect `THHMMSS` after the date.
    var hour = 0, minute = 0, second = 0;
    final tIdx = v.indexOf('T');
    if (tIdx == 8 && v.length >= 15) {
      hour = int.tryParse(v.substring(9, 11)) ?? 0;
      minute = int.tryParse(v.substring(11, 13)) ?? 0;
      second = int.tryParse(v.substring(13, 15)) ?? 0;
    }

    if (v.endsWith('Z')) {
      final utc = DateTime.utc(year, month, day, hour, minute, second);
      return IcsDateTime(utc.toLocal(), dateOnly: false);
    }
    return IcsDateTime(
      DateTime(year, month, day, hour, minute, second),
      dateOnly: false,
    );
  }
}
