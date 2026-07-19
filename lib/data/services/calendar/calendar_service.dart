import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../domain/models/calendar.dart';
import '../../../extensions/loggable.dart';
import '../http_proxy_stub.dart' if (dart.library.io) '../http_proxy_io.dart';
import 'ics_parser.dart';

/// Thrown when a calendar feed can't be fetched or parsed.
class CalendarException implements Exception {
  CalendarException(this.message);

  final String message;

  @override
  String toString() => 'CalendarException: $message';
}

/// Fetches calendar feeds in two modes and hands the resulting ICS text to
/// [IcsParser]:
///
///  * [CalendarKind.ics] — an HTTP `GET` of an iCalendar (`.ics`) document, the
///    form used by "publish"/"public address" links from Google, iCloud,
///    Nextcloud, etc. `webcal://` URLs are treated as `https://`.
///  * [CalendarKind.caldav] — a basic CalDAV `calendar-query` `REPORT` against a
///    calendar collection URL, whose multistatus response embeds one
///    `calendar-data` (an ICS document) per event. Calendar discovery
///    (principal / home-set `PROPFIND`) is out of scope: point the source URL
///    straight at the collection.
///
/// Both modes end up as ICS text handed to the same [IcsParser]. Both accept
/// optional HTTP Basic auth.
class CalendarService with Loggable {
  CalendarService(this._dio);

  final Dio _dio;

  @override
  String get logIdentifier => '[CalendarService]';

  /// Fetch [source] and return its events overlapping `[windowStart, windowEnd)`,
  /// each stamped with the source's id and colour.
  Future<List<CalendarEvent>> fetch(
    CalendarSource source, {
    required DateTime windowStart,
    required DateTime windowEnd,
  }) async {
    final headers = _authHeader(source);
    final client = _clientFor(source);
    final proxied = !identical(client, _dio);
    try {
      final ics = source.kind == CalendarKind.caldav
          ? await _fetchCalDav(client, source, headers, windowStart, windowEnd)
          : await _fetchIcs(client, source, headers);

      final events = IcsParser.parse(
        ics,
        source: source,
        windowStart: windowStart,
        windowEnd: windowEnd,
      );
      return events;
    } catch (e, s) {
      logWarning(
        'fetch failed: label="${source.label}" url=${source.url}',
        error: e,
        stackTrace: s,
      );
      rethrow;
    } finally {
      // A per-source proxied client is single-use; release its sockets. The
      // shared [_dio] is left alone.
      if (!identical(client, _dio)) client.close();
    }
  }

  /// The Dio to fetch [source] with: the shared client, or a throwaway client routed through it.
  Dio _clientFor(CalendarSource source) {
    final proxy = source.proxy?.trim() ?? '';
    if (proxy.isEmpty) return _dio;
    final adapter = proxyAdapter(proxy);
    if (adapter == null) return _dio; // web / unusable proxy string
    return Dio(_dio.options)..httpClientAdapter = adapter;
  }

  /// A Basic-auth header for [source], or null when no username is set.
  static Map<String, String>? _authHeader(CalendarSource source) {
    final user = source.username;
    if (user == null || user.isEmpty) return null;
    final token = base64.encode(utf8.encode('$user:${source.password ?? ''}'));
    return {'authorization': 'Basic $token'};
  }

  /// GET a published ICS document and return its raw text.
  Future<String> _fetchIcs(
    Dio client,
    CalendarSource source,
    Map<String, String>? headers,
  ) async {
    final uri = _normalize(source.url);
    final Response<Object?> res;
    try {
      res = await client.getUri<Object?>(
        uri,
        options: Options(responseType: ResponseType.plain, headers: headers),
      );
    } on DioException catch (e) {
      logWarning(
        'ICS GET $uri failed: ${e.type.name} ${e.message}'
        '${_responseSummary(e.response)}',
      );
      throw CalendarException('Fetch failed for ${source.url}: ${e.message}');
    }
    final body = res.data;
    if (body is! String || !body.contains('BEGIN:VCALENDAR')) {
      logWarning(
        'ICS GET $uri returned a non-iCalendar body '
        '(${body is String ? '${body.length} chars' : body.runtimeType}); '
        'preview: ${_bodyPreview(body)}',
      );
      throw CalendarException('Not an iCalendar feed: ${source.url}');
    }
    return body;
  }

  /// A short one-line summary of an HTTP [Response] for logs: status, a couple
  /// of diagnostic headers, and body size.
  static String _responseSummary(Response<Object?>? res) {
    if (res == null) return ' (no response)';
    final body = res.data;
    final len = body is String ? '${body.length} chars' : '${body.runtimeType}';
    final type = res.headers.value('content-type') ?? '?';
    final loc = res.headers.value('location');
    return ' status=${res.statusCode} type=$type'
        '${loc != null ? ' location=$loc' : ''} body=$len';
  }

  /// The first line / first ~200 chars of a response body, collapsed to a single
  /// line, to hint at what a server actually returned (an HTML login page, an
  /// error message, a redirect notice, …) without dumping the whole document.
  static String _bodyPreview(Object? body) {
    if (body is! String) return '<${body.runtimeType}>';
    final collapsed = body.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (collapsed.isEmpty) return '<empty>';
    return collapsed.length > 200
        ? '${collapsed.substring(0, 200)}…'
        : collapsed;
  }

  /// Run a CalDAV `calendar-query` REPORT for VEVENTs in the window and return
  /// the concatenated `calendar-data` ICS documents from the multistatus body.
  Future<String> _fetchCalDav(
    Dio client,
    CalendarSource source,
    Map<String, String>? headers,
    DateTime windowStart,
    DateTime windowEnd,
  ) async {
    final uri = _normalize(source.url);
    final Response<Object?> res;
    try {
      res = await client.requestUri<Object?>(
        uri,
        data: _calendarQuery(windowStart, windowEnd),
        options: Options(
          method: 'REPORT',
          responseType: ResponseType.plain,
          headers: {
            'content-type': 'application/xml; charset=utf-8',
            'depth': '1',
            ...?headers,
          },
        ),
      );
    } on DioException catch (e) {
      logWarning(
        'CalDAV REPORT $uri failed: ${e.type.name} ${e.message}'
        '${_responseSummary(e.response)}',
      );
      throw CalendarException(
        'CalDAV REPORT failed for ${source.url}: ${e.message}',
      );
    }
    final xml = res.data;
    if (xml is! String) {
      logWarning(
        'CalDAV REPORT $uri returned ${xml.runtimeType}, expected text',
      );
      throw CalendarException('Unexpected CalDAV response from ${source.url}');
    }
    final blocks = _extractCalendarData(xml);
    // Some servers answer a collection GET/REPORT with plain ICS; accept that.
    if (blocks.isEmpty) {
      if (xml.contains('BEGIN:VCALENDAR')) {
        return xml;
      }
      logWarning(
        'CalDAV REPORT $uri had no calendar data; preview: ${_bodyPreview(xml)}',
      );
      throw CalendarException('No calendar data from ${source.url}');
    }
    return blocks.join('\n');
  }

  /// The CalDAV `calendar-query` request body, filtered to VEVENTs overlapping
  /// `[start, end)` (UTC).
  static String _calendarQuery(DateTime start, DateTime end) {
    String z(DateTime t) {
      final u = t.toUtc();
      String two(int v) => v.toString().padLeft(2, '0');
      return '${u.year}${two(u.month)}${two(u.day)}T'
          '${two(u.hour)}${two(u.minute)}${two(u.second)}Z';
    }

    return '<?xml version="1.0" encoding="utf-8"?>'
        '<C:calendar-query xmlns:D="DAV:" '
        'xmlns:C="urn:ietf:params:xml:ns:caldav">'
        '<D:prop><C:calendar-data/></D:prop>'
        '<C:filter><C:comp-filter name="VCALENDAR">'
        '<C:comp-filter name="VEVENT">'
        '<C:time-range start="${z(start)}" end="${z(end)}"/>'
        '</C:comp-filter></C:comp-filter></C:filter>'
        '</C:calendar-query>';
  }

  /// Pull the text of every `calendar-data` element out of a CalDAV multistatus
  /// document (namespace-prefix agnostic), unescaping XML entities and CDATA.
  static List<String> _extractCalendarData(String xml) {
    final re = RegExp(
      r'<(?:[A-Za-z0-9]+:)?calendar-data[^>]*>(.*?)</(?:[A-Za-z0-9]+:)?calendar-data\s*>',
      dotAll: true,
    );
    final out = <String>[];
    for (final m in re.allMatches(xml)) {
      var text = m.group(1) ?? '';
      final cdata = RegExp(
        r'<!\[CDATA\[(.*?)\]\]>',
        dotAll: true,
      ).firstMatch(text);
      if (cdata != null) text = cdata.group(1) ?? '';
      text = _xmlUnescape(text).trim();
      if (text.contains('BEGIN:VCALENDAR')) out.add(text);
    }
    return out;
  }

  static String _xmlUnescape(String s) => s
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&apos;', "'")
      .replaceAll('&#13;', '\r')
      .replaceAll('&#10;', '\n')
      .replaceAll('&amp;', '&');

  static Uri _normalize(String url) {
    var u = url.trim();
    if (u.startsWith('webcal://')) {
      u = 'https://${u.substring('webcal://'.length)}';
    }
    return Uri.parse(u);
  }
}
