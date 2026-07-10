import 'package:dio/dio.dart';

import '../../../domain/models/markets.dart';
import 'markets_service.dart';

/// Fetches live quotes from EastMoney's keyless push endpoint
/// (`push2.eastmoney.com/api/qt/ulist.np/get`), which quotes many instruments
/// in a **single** request — unlike Yahoo's one-request-per-symbol chart API.
/// Reached by prefixing a watchlist entry with `em:`; unprefixed entries go to
/// Yahoo, the default provider.
///
/// EastMoney addresses an instrument by `secid`, a `<market>.<code>` pair
/// (`1.600519` is Kweichow Moutai on the Shanghai exchange). The prefix is
/// stripped before this provider sees the entry, so it receives plain codes
/// (`600519`) and [_secidsFor] infers the market; a code that already carries a
/// numeric market id (`1.000001`) passes through untouched, which is the escape
/// hatch for anything the inference gets wrong.
///
/// Note: this is EastMoney's unofficial API. Requests routed through a proxy are
/// redirected to `push2delay.eastmoney.com` and answered with *delayed* quotes,
/// so this provider is never proxied — `MarketsService` always hands it the
/// shared, direct client.
class EastMoneyProvider implements MarketQuoteProvider {
  EastMoneyProvider(this._dio);

  final Dio _dio;

  static const String _host = 'push2.eastmoney.com';

  /// The response fields to request. EastMoney names them positionally:
  /// f2 price, f3 percent change, f4 absolute change, f12 code, f13 market id,
  /// f14 name, f15 day high, f16 day low, f17 open, f18 previous close,
  /// f124 quote time (epoch seconds).
  static const String _fields = 'f2,f3,f4,f12,f13,f14,f15,f16,f17,f18,f124';

  // Market ids. EastMoney has many more; these are the ones we can infer.
  static const int _mktShanghai = 1;
  static const int _mktShenzhen = 0;
  static const int _mktHongKong = 116;
  static const List<int> _mktUs = [105, 106, 107]; // NASDAQ, NYSE, AMEX

  @override
  Future<List<Quote>> fetch(List<MarketSymbol> symbols) async {
    if (symbols.isEmpty) return const [];

    // Every candidate secid we're about to ask for, mapped back to the
    // watchlist entry that produced it. A symbol may contribute several
    // candidates when its market is ambiguous.
    final bySecid = <String, MarketSymbol>{};
    for (final s in symbols) {
      for (final secid in _secidsFor(s.ticker)) {
        bySecid.putIfAbsent(secid, () => s);
      }
    }
    if (bySecid.isEmpty) return const [];

    final res = await _dio.getUri<Object?>(
      Uri.https(_host, '/api/qt/ulist.np/get', {
        // fltt=2 returns prices as decimals rather than scaled integers.
        'fltt': '2',
        'invt': '2',
        'fields': _fields,
        'secids': bySecid.keys.join(','),
      }),
    );
    return _parse(res.data, bySecid);
  }

  /// The secid candidates to try for [ticker].
  ///
  /// A ticker that already names its market (`1.000001`) is used verbatim.
  /// Otherwise the market is inferred from the code's shape, and where that's
  /// genuinely ambiguous — a US ticker gives no hint whether it lists on NASDAQ,
  /// NYSE, or AMEX — every candidate is emitted. EastMoney silently drops the
  /// secids that don't resolve, so the extra candidates cost nothing but a few
  /// bytes on a request that is batched anyway.
  static List<String> _secidsFor(String ticker) {
    final t = ticker.trim();
    if (t.isEmpty) return const [];
    // Explicit `<market>.<code>` — trust the user over the heuristic.
    if (RegExp(r'^\d+\.').hasMatch(t)) return [t];

    final digits = RegExp(r'^\d+$').hasMatch(t);
    if (!digits) return [for (final m in _mktUs) '$m.${t.toUpperCase()}'];

    if (t.length == 5) return ['$_mktHongKong.$t'];
    if (t.length == 6) {
      // Shanghai issues 6xxxxx (A shares) and 9xxxxx (B shares); Shenzhen holds
      // 0xxxxx/3xxxxx, and Beijing's 4xxxxx/8xxxxx are quoted under its id too.
      final market = switch (t[0]) {
        '6' || '9' => _mktShanghai,
        '0' || '3' || '4' || '8' => _mktShenzhen,
        _ => null,
      };
      if (market != null) return ['$market.$t'];
    }
    // Unknown shape: let EastMoney adjudicate between the mainland exchanges.
    return ['$_mktShanghai.$t', '$_mktShenzhen.$t'];
  }

  /// Read `data.diff` into quotes. Rows are matched back to watchlist entries by
  /// their full `<market>.<code>` secid, never by position: EastMoney drops
  /// unresolvable secids from the response, and the bare code is ambiguous
  /// (`000001` is both the SSE Composite index `1.000001` and Ping An Bank
  /// `0.000001`).
  static List<Quote> _parse(Object? data, Map<String, MarketSymbol> bySecid) {
    if (data is! Map) return const [];
    final payload = data['data'];
    // `data: null` with `rc: 102` means not one secid resolved.
    if (payload is! Map) return const [];
    final diff = payload['diff'];
    if (diff is! List) return const [];

    final quotes = <String, Quote>{};
    for (final row in diff) {
      if (row is! Map) continue;
      final code = row['f12'] as String?;
      final market = (row['f13'] as num?)?.toInt();
      if (code == null || market == null) continue;
      final symbol = bySecid['$market.$code'];
      if (symbol == null) continue;

      final quote = _quote(symbol, market, code, row);
      // Several candidates can resolve for one entry only in pathological cases;
      // the first row wins so the result stays deterministic.
      if (quote != null) quotes.putIfAbsent(symbol.symbol, () => quote);
    }
    return quotes.values.toList();
  }

  static Quote? _quote(
    MarketSymbol symbol,
    int market,
    String code,
    Map<Object?, Object?> row,
  ) {
    final price = _num(row['f2']);
    // Suspended instruments report "-" instead of a price; there's nothing to
    // show for them, so drop the row rather than render a zero.
    if (price == null) return null;

    final prevClose = _num(row['f18']);
    // EastMoney reports the change directly; fall back to deriving it from the
    // previous close, as the Yahoo provider does.
    final change =
        _num(row['f4']) ?? (prevClose == null ? 0.0 : price - prevClose);
    final changePercent =
        _num(row['f3']) ??
        ((prevClose == null || prevClose == 0)
            ? 0.0
            : change / prevClose * 100);

    // Before the open, the session high/low come back as 0. `Quote.hasRange`
    // requires high > low, so leaving them as 0 already hides the range bar.
    final high = _num(row['f15']);
    final low = _num(row['f16']);
    final time = _num(row['f124'])?.toInt();

    return Quote(
      // Echo the watchlist entry verbatim, prefix and all, so MarketsService
      // can key this back to the user's ordering.
      symbol: symbol.symbol,
      displayName: symbol.label ?? (row['f14'] as String?) ?? code,
      // The ticker never revealed the instrument's kind; the market does.
      kind: _kindFor(market, code),
      price: price,
      change: change,
      changePercent: changePercent,
      dayLow: low,
      dayHigh: high,
      currency: _currencyFor(market),
      asOf: time == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(time * 1000),
    );
  }

  /// Classify from the market the quote actually came back on. Only affects how
  /// many decimals the UI prints.
  static QuoteKind _kindFor(int market, String code) {
    // 100 is EastMoney's bucket for global indices; 119/120/133 are FX.
    if (market == 100) return QuoteKind.marketIndex;
    if (market == 119 || market == 120 || market == 133) return QuoteKind.forex;
    // Mainland indices: Shanghai's 000xxx and Shenzhen's 399xxx.
    if (market == _mktShanghai && code.startsWith('000')) {
      return QuoteKind.marketIndex;
    }
    if (market == _mktShenzhen && code.startsWith('399')) {
      return QuoteKind.marketIndex;
    }
    return QuoteKind.stock;
  }

  /// EastMoney reports no currency code, so derive it from the market. A
  /// mainland index quotes in CNY just as Yahoo reports `^GSPC` in USD; the
  /// global-index (100) and FX markets are unitless and get none.
  static String? _currencyFor(int market) => switch (market) {
    _mktShanghai || _mktShenzhen => 'CNY',
    _mktHongKong || 128 => 'HKD',
    105 || 106 || 107 => 'USD',
    _ => null,
  };

  /// Coerce a numeric field. EastMoney substitutes the string `"-"` for fields
  /// it has no value for, so a plain cast would throw.
  static double? _num(Object? value) => switch (value) {
    final num n => n.toDouble(),
    _ => null,
  };
}
