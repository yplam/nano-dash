import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_dash/data/services/markets/markets_service.dart';
import 'package:nano_dash/domain/models/markets.dart';

/// A provider that echoes back one quote per symbol it was handed, or throws.
/// Records the [Dio] it was built over, so proxy routing can be asserted.
class _FakeProvider implements MarketQuoteProvider {
  _FakeProvider({this.fails = false});

  final bool fails;
  List<MarketSymbol>? received;
  Dio? client;

  @override
  Future<List<Quote>> fetch(List<MarketSymbol> symbols) async {
    received = symbols;
    if (fails) throw Exception('boom');
    return [
      for (final s in symbols)
        Quote(
          symbol: s.symbol,
          displayName: s.symbol,
          kind: s.kind,
          price: 1,
          change: 0,
          changePercent: 0,
        ),
    ];
  }
}

/// The shared client the service under test was constructed with, so a test can
/// tell it apart from a throwaway proxied one.
late Dio sharedDio;

MarketsService serviceWith(Map<QuoteProvider, MarketQuoteProvider> providers) {
  sharedDio = Dio();
  return MarketsService(
    sharedDio,
    providers: {
      for (final e in providers.entries)
        e.key: (dio) {
          if (e.value case final _FakeProvider f) f.client = dio;
          return e.value;
        },
    },
  );
}

MarketsConfig configOf(List<String> tickers, {String? proxy}) =>
    MarketsConfig.fromTickers(tickers, proxy: proxy);

void main() {
  test('routes each symbol to its own provider', () async {
    final yahoo = _FakeProvider();
    final em = _FakeProvider();
    await serviceWith({
      QuoteProvider.yahoo: yahoo,
      QuoteProvider.eastmoney: em,
    }).fetch(configOf(['em:600519', 'AAPL', 'em:1.000001']));

    expect(yahoo.received!.map((s) => s.symbol), ['AAPL']);
    expect(em.received!.map((s) => s.symbol), ['em:600519', 'em:1.000001']);
  });

  test('merges both providers back into watchlist order', () async {
    final quotes = await serviceWith({
      QuoteProvider.yahoo: _FakeProvider(),
      QuoteProvider.eastmoney: _FakeProvider(),
    }).fetch(configOf(['em:600519', 'AAPL', 'em:00700', '^GSPC']));

    expect(quotes.map((q) => q.symbol), [
      'em:600519',
      'AAPL',
      'em:00700',
      '^GSPC',
    ]);
  });

  test('only Yahoo is proxied; EastMoney gets the direct client', () async {
    final yahoo = _FakeProvider();
    final em = _FakeProvider();
    await serviceWith({
      QuoteProvider.yahoo: yahoo,
      QuoteProvider.eastmoney: em,
    }).fetch(configOf(['em:600519', 'AAPL'], proxy: 'socks5://host:1080'));

    expect(
      identical(em.client, sharedDio),
      isTrue,
      reason: 'a proxied EastMoney request is answered with delayed quotes',
    );
    expect(
      identical(yahoo.client, sharedDio),
      isFalse,
      reason: 'Yahoo gets a throwaway client routed through the proxy',
    );
  });

  test('with no proxy set, every provider shares the direct client', () async {
    final yahoo = _FakeProvider();
    final em = _FakeProvider();
    await serviceWith({
      QuoteProvider.yahoo: yahoo,
      QuoteProvider.eastmoney: em,
    }).fetch(configOf(['em:600519', 'AAPL']));

    expect(identical(em.client, sharedDio), isTrue);
    expect(identical(yahoo.client, sharedDio), isTrue);
  });

  test('one failing provider does not blank the other\'s quotes', () async {
    final quotes = await serviceWith({
      QuoteProvider.yahoo: _FakeProvider(fails: true),
      QuoteProvider.eastmoney: _FakeProvider(),
    }).fetch(configOf(['AAPL', 'em:600519']));

    expect(quotes.map((q) => q.symbol), ['em:600519']);
  });

  test('throws only when every provider fails', () async {
    expect(
      () => serviceWith({
        QuoteProvider.yahoo: _FakeProvider(fails: true),
        QuoteProvider.eastmoney: _FakeProvider(fails: true),
      }).fetch(configOf(['AAPL', 'em:600519'])),
      throwsA(isA<MarketsException>()),
    );
  });

  test(
    'a single failing provider still throws when it is the only one used',
    () async {
      expect(
        () => serviceWith({
          QuoteProvider.yahoo: _FakeProvider(fails: true),
          QuoteProvider.eastmoney: _FakeProvider(),
        }).fetch(configOf(['AAPL'])),
        throwsA(isA<MarketsException>()),
        reason:
            'the EastMoney provider is never consulted, so nothing succeeds',
      );
    },
  );

  test('an empty watchlist fetches nothing', () async {
    final em = _FakeProvider();
    final quotes = await serviceWith({
      QuoteProvider.eastmoney: em,
    }).fetch(configOf(const []));

    expect(quotes, isEmpty);
    expect(em.received, isNull);
  });
}
