import 'package:dio/dio.dart';

import '../../../domain/models/markets.dart';
import 'markets_service.dart';

/// Fetches live quotes from Yahoo Finance's keyless chart endpoint
/// (`query1.finance.yahoo.com/v8/finance/chart/<symbol>`). One request per
/// symbol (issued in parallel), reading the `meta` block for price, previous
/// close, and the session low/high. This endpoint needs no API key or crumb,
/// unlike the `/v7/finance/quote` batch endpoint.
///
/// This is the default provider: an unprefixed watchlist entry lands here.
///
/// Note: this is Yahoo's unofficial API. It's rate-limited per IP and can change
/// without notice; a browser-like `User-Agent` avoids the most aggressive
/// blocking. It also does not report a market-open flag, so quotes carry none.
class YahooFinanceProvider implements MarketQuoteProvider {
  YahooFinanceProvider(this._dio);

  final Dio _dio;

  static const String _host = 'query1.finance.yahoo.com';

  /// Yahoo rejects requests from non-browser user agents with 429; spoof one.
  static const String _userAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/122.0 Safari/537.36';

  @override
  Future<List<Quote>> fetch(List<MarketSymbol> symbols) async {
    if (symbols.isEmpty) return const [];
    // Fetch every symbol in parallel; a failed symbol yields null and is
    // dropped, so one bad ticker never blanks the whole page.
    final results = await Future.wait([for (final s in symbols) _fetchOne(s)]);
    return [for (final q in results) ?q];
  }

  Future<Quote?> _fetchOne(MarketSymbol symbol) async {
    try {
      final res = await _dio.getUri<Object?>(
        Uri.https(_host, '/v8/finance/chart/${symbol.ticker}', {
          'range': '1d',
          'interval': '30m',
        }),
        options: Options(headers: {'User-Agent': _userAgent}),
      );
      return _parse(symbol, res.data);
    } catch (_) {
      // Unknown ticker, rate limit, or transient network error: skip it.
      return null;
    }
  }

  /// Read the `chart.result[0].meta` block into a [Quote]. Returns null if the
  /// response is malformed or lacks a usable price.
  static Quote? _parse(MarketSymbol symbol, Object? data) {
    if (data is! Map) return null;
    final chart = data['chart'];
    if (chart is! Map) return null;
    final results = chart['result'];
    if (results is! List || results.isEmpty) return null;
    final first = results.first;
    if (first is! Map) return null;
    final meta = first['meta'];
    if (meta is! Map) return null;

    final price = (meta['regularMarketPrice'] as num?)?.toDouble();
    if (price == null) return null;

    // `chartPreviousClose` is the baseline the chart is drawn against; fall back
    // to `previousClose`. Without one we can't compute a change, so treat the
    // change as zero rather than dropping the row.
    final prevClose =
        (meta['chartPreviousClose'] as num?)?.toDouble() ??
        (meta['previousClose'] as num?)?.toDouble() ??
        price;
    final change = price - prevClose;
    final changePercent = prevClose == 0 ? 0.0 : (change / prevClose) * 100;

    final time = (meta['regularMarketTime'] as num?)?.toInt();

    return Quote(
      // Echo the watchlist entry verbatim, redundant `yahoo:` prefix and all, so
      // MarketsService can key this back to the user's ordering.
      symbol: symbol.symbol,
      displayName:
          symbol.label ??
          (meta['shortName'] as String?) ??
          (meta['longName'] as String?) ??
          symbol.ticker,
      kind: symbol.kind,
      price: price,
      change: change,
      changePercent: changePercent,
      dayLow: (meta['regularMarketDayLow'] as num?)?.toDouble(),
      dayHigh: (meta['regularMarketDayHigh'] as num?)?.toDouble(),
      currency: meta['currency'] as String?,
      asOf: time == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(time * 1000),
    );
  }
}
