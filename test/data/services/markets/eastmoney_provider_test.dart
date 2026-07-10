import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_dash/data/services/markets/eastmoney_provider.dart';
import 'package:nano_dash/domain/models/markets.dart';

/// Answers every request with [body] and records the URI it was asked for, so a
/// test can assert on the `secids` the provider derived.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.body);

  final Object body;
  Uri? captured;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    captured = options.uri;
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// Run the provider over [tickers] against a canned [body], returning both the
/// quotes and the secids the provider asked EastMoney for.
Future<({List<Quote> quotes, List<String> secids})> run(
  List<String> tickers, {
  Object body = const {'data': null},
}) async {
  final adapter = _FakeAdapter(body);
  final dio = Dio()..httpClientAdapter = adapter;
  final quotes = await EastMoneyProvider(
    dio,
  ).fetch([for (final t in tickers) MarketSymbol.parse(t)]);
  final secids = adapter.captured?.queryParameters['secids']?.split(',') ?? [];
  return (quotes: quotes, secids: secids);
}

/// One `data.diff` row as EastMoney returns it under `fltt=2`.
Map<String, Object?> row({
  required String code,
  required int market,
  String name = 'Name',
  Object? price = 10.0,
  double? change = 1.0,
  double? percent = 11.11,
  double? prevClose = 9.0,
  double high = 10.5,
  double low = 8.5,
  int? time,
}) => {
  'f2': price,
  'f3': percent,
  'f4': change,
  'f12': code,
  'f13': market,
  'f14': name,
  'f15': high,
  'f16': low,
  'f18': prevClose,
  'f124': ?time,
};

Object payload(List<Map<String, Object?>> rows) => {
  'rc': 0,
  'data': {'total': rows.length, 'diff': rows},
};

void main() {
  group('secid inference', () {
    test('a Shanghai code takes market 1', () async {
      expect((await run(['em:600519'])).secids, ['1.600519']);
    });

    test('Shenzhen and Beijing codes take market 0', () async {
      expect((await run(['em:000001', 'em:300750', 'em:830799'])).secids, [
        '0.000001',
        '0.300750',
        '0.830799',
      ]);
    });

    test('a five-digit code is Hong Kong', () async {
      expect((await run(['em:00700'])).secids, ['116.00700']);
    });

    test('a US ticker emits every exchange candidate', () async {
      // Nothing in `AAPL` says NASDAQ vs NYSE vs AMEX; EastMoney drops the
      // candidates that don't resolve.
      expect((await run(['em:aapl'])).secids, [
        '105.AAPL',
        '106.AAPL',
        '107.AAPL',
      ]);
    });

    test('an explicit market id passes through untouched', () async {
      // The escape hatch: `000001` would otherwise be inferred as Shenzhen,
      // but 1.000001 is the SSE Composite index.
      expect((await run(['em:1.000001'])).secids, ['1.000001']);
    });

    test('an ambiguous numeric code tries both mainland markets', () async {
      expect((await run(['em:1234567'])).secids, ['1.1234567', '0.1234567']);
    });

    test('duplicate entries are asked for once', () async {
      expect((await run(['em:600519', 'em:600519'])).secids, ['1.600519']);
    });
  });

  group('parsing', () {
    test('reads a row into a quote keyed by the raw watchlist entry', () async {
      final r = await run(
        ['em:600519'],
        body: payload([
          row(
            code: '600519',
            market: 1,
            name: '贵州茅台',
            price: 1199.0,
            change: 16.81,
            percent: 1.42,
            high: 1200.99,
            low: 1170.28,
            time: 1783651623,
          ),
        ]),
      );
      final q = r.quotes.single;
      expect(q.symbol, 'em:600519', reason: 'echoes the watchlist entry');
      expect(q.displayName, '贵州茅台');
      expect(q.price, 1199.0);
      expect(q.change, 16.81);
      expect(q.changePercent, 1.42);
      expect(q.dayHigh, 1200.99);
      expect(q.dayLow, 1170.28);
      expect(q.currency, 'CNY');
      expect(q.kind, QuoteKind.stock);
      expect(q.asOf, DateTime.fromMillisecondsSinceEpoch(1783651623 * 1000));
    });

    test('a label overrides EastMoney\'s Chinese name', () async {
      final adapter = _FakeAdapter(
        payload([row(code: '600519', market: 1, name: '贵州茅台')]),
      );
      final dio = Dio()..httpClientAdapter = adapter;
      final quotes = await EastMoneyProvider(dio).fetch(const [
        MarketSymbol(
          symbol: 'em:600519',
          label: 'Moutai',
          kind: QuoteKind.stock,
          provider: QuoteProvider.eastmoney,
        ),
      ]);
      expect(quotes.single.displayName, 'Moutai');
    });

    test('rows match on the full secid, not the ambiguous bare code', () async {
      // `000001` is the SSE Composite index (1.000001) *and* Ping An Bank
      // (0.000001). Both are in the watchlist at once.
      final r = await run(
        ['em:1.000001', 'em:000001'],
        body: payload([
          row(code: '000001', market: 1, name: '上证指数', price: 4055.55),
          row(code: '000001', market: 0, name: '平安银行', price: 11.9),
        ]),
      );
      final byEntry = {for (final q in r.quotes) q.symbol: q};
      expect(byEntry['em:1.000001']!.displayName, '上证指数');
      expect(byEntry['em:1.000001']!.kind, QuoteKind.marketIndex);
      expect(byEntry['em:000001']!.displayName, '平安银行');
      expect(byEntry['em:000001']!.kind, QuoteKind.stock);
    });

    test('classifies indices, FX, and their currencies by market', () async {
      final r = await run(
        ['em:100.NDX', 'em:133.USDCNH', 'em:00700', 'em:AAPL'],
        body: payload([
          row(code: 'NDX', market: 100),
          row(code: 'USDCNH', market: 133),
          row(code: '00700', market: 116),
          row(code: 'AAPL', market: 105),
        ]),
      );
      final byEntry = {for (final q in r.quotes) q.symbol: q};
      expect(byEntry['em:100.NDX']!.kind, QuoteKind.marketIndex);
      expect(byEntry['em:100.NDX']!.currency, isNull);
      expect(byEntry['em:133.USDCNH']!.kind, QuoteKind.forex);
      expect(byEntry['em:133.USDCNH']!.currency, isNull);
      expect(byEntry['em:00700']!.currency, 'HKD');
      expect(byEntry['em:AAPL']!.currency, 'USD');
    });

    test('a suspended instrument reports "-" and is dropped', () async {
      final r = await run(
        ['em:600519', 'em:000001'],
        body: payload([
          row(code: '600519', market: 1, price: '-'),
          row(code: '000001', market: 0, price: 11.9),
        ]),
      );
      expect(r.quotes.map((q) => q.symbol), ['em:000001']);
    });

    test('an unresolvable secid is simply absent, not an error', () async {
      // EastMoney silently omits secids it can't resolve.
      final r = await run([
        'em:600519',
        'em:ZZZZ',
      ], body: payload([row(code: '600519', market: 1)]));
      expect(r.quotes.map((q) => q.symbol), ['em:600519']);
    });

    test('derives the change from the previous close when absent', () async {
      final r = await run(
        ['em:600519'],
        body: payload([
          row(
            code: '600519',
            market: 1,
            price: 11.0,
            change: null,
            percent: null,
            prevClose: 10.0,
          ),
        ]),
      );
      expect(r.quotes.single.change, closeTo(1.0, 1e-9));
      expect(r.quotes.single.changePercent, closeTo(10.0, 1e-9));
    });

    test('a pre-open zero high/low leaves no range to draw', () async {
      final r = await run([
        'em:600519',
      ], body: payload([row(code: '600519', market: 1, high: 0, low: 0)]));
      expect(r.quotes.single.hasRange, isFalse);
    });

    test('`data: null` (no secid resolved) yields no quotes', () async {
      final r = await run(['em:ZZZZ'], body: const {'rc': 102, 'data': null});
      expect(r.quotes, isEmpty);
    });

    test('an empty watchlist makes no request', () async {
      final adapter = _FakeAdapter(const {});
      final dio = Dio()..httpClientAdapter = adapter;
      expect(await EastMoneyProvider(dio).fetch(const []), isEmpty);
      expect(adapter.captured, isNull);
    });
  });
}
