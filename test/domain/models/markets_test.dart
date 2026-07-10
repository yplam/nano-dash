import 'package:flutter_test/flutter_test.dart';
import 'package:nano_dash/domain/models/markets.dart';

void main() {
  group('MarketSymbol.parse', () {
    test('an unprefixed ticker goes to Yahoo and is left whole', () {
      final s = MarketSymbol.parse('AAPL');
      expect(s.provider, QuoteProvider.yahoo);
      expect(s.symbol, 'AAPL');
      expect(s.ticker, 'AAPL');
    });

    test('an unprefixed ticker still infers its kind', () {
      // `^` and `-USD` are Yahoo's conventions, and Yahoo is the default source.
      expect(MarketSymbol.parse('^GSPC').kind, QuoteKind.marketIndex);
      expect(MarketSymbol.parse('BTC-USD').kind, QuoteKind.crypto);
      expect(MarketSymbol.parse('EURUSD=X').kind, QuoteKind.forex);
      expect(MarketSymbol.parse('AAPL').kind, QuoteKind.stock);
    });

    test('an em: prefix routes to EastMoney and is stripped', () {
      final s = MarketSymbol.parse('em:600519');
      expect(s.provider, QuoteProvider.eastmoney);
      expect(s.symbol, 'em:600519', reason: 'symbol is the watchlist identity');
      expect(s.ticker, '600519', reason: 'the ticker is what the API wants');
    });

    test('the prefix is case-insensitive and the entry is trimmed', () {
      final s = MarketSymbol.parse('  EM:1.000001  ');
      expect(s.provider, QuoteProvider.eastmoney);
      expect(s.ticker, '1.000001');
    });

    test('a redundant yahoo: prefix is accepted and stripped', () {
      final s = MarketSymbol.parse('yahoo:BTC-USD');
      expect(s.provider, QuoteProvider.yahoo);
      expect(s.ticker, 'BTC-USD');
      expect(s.kind, QuoteKind.crypto, reason: 'the kind reads the ticker');
    });

    test('an unknown prefix is part of the ticker, not a provider', () {
      final s = MarketSymbol.parse('foo:BAR');
      expect(s.provider, QuoteProvider.yahoo);
      expect(s.ticker, 'foo:BAR');
    });

    test('EastMoney entries get a provisional kind the provider overrides', () {
      // `^` and `-USD` are Yahoo conventions; an `em:` entry is EastMoney's and
      // must not be classified by them.
      expect(MarketSymbol.parse('em:600519').kind, QuoteKind.stock);
      expect(MarketSymbol.parse('em:1.000001').kind, QuoteKind.stock);
    });
  });

  group('MarketSymbol JSON', () {
    test('round-trips the provider', () {
      final s = MarketSymbol.parse('em:00700');
      expect(MarketSymbol.fromJson(s.toJson()), s);
      final y = MarketSymbol.parse('^GSPC');
      expect(MarketSymbol.fromJson(y.toJson()), y);
    });

    test('an entry with no stored provider re-derives it from the symbol', () {
      final em = MarketSymbol.fromJson({
        'symbol': 'em:600519',
        'kind': 'stock',
      });
      expect(em.provider, QuoteProvider.eastmoney);
      expect(em.ticker, '600519');

      final yahoo = MarketSymbol.fromJson({'symbol': 'AAPL', 'kind': 'stock'});
      expect(yahoo.provider, QuoteProvider.yahoo);
      expect(yahoo.ticker, 'AAPL');
    });
  });

  group('MarketsConfig', () {
    test('fromTickers routes each line by its prefix', () {
      final c = MarketsConfig.fromTickers([
        'em:600519',
        'AAPL',
        '  ',
        'em:1.000001',
      ]);
      expect(c.symbols.map((s) => s.provider), [
        QuoteProvider.eastmoney,
        QuoteProvider.yahoo,
        QuoteProvider.eastmoney,
      ], reason: 'blank lines are dropped');
    });

    test('yahooProxy treats a blank proxy as "connect direct"', () {
      expect(const MarketsConfig(proxy: '   ').yahooProxy, isNull);
      expect(const MarketsConfig().yahooProxy, isNull);
    });

    test('yahooProxy returns the trimmed proxy', () {
      expect(const MarketsConfig(proxy: ' host:1080 ').yahooProxy, 'host:1080');
    });

    test('round-trips the proxy', () {
      const c = MarketsConfig(symbols: [], proxy: 'socks5://host:1080');
      expect(MarketsConfig.fromJson(c.toJson()), c);
      expect(
        MarketsConfig.fromJson(c.toJson()).yahooProxy,
        'socks5://host:1080',
      );
    });

    test('a blank proxy is not persisted, and equals an absent one', () {
      const blank = MarketsConfig(symbols: [], proxy: '  ');
      const absent = MarketsConfig(symbols: []);
      expect(blank.toJson().containsKey('proxy'), isFalse);
      expect(blank, absent);
      expect(blank.hashCode, absent.hashCode);
    });

    test('the starter watchlist is Yahoo throughout', () {
      const c = MarketsConfig();
      expect(
        c.symbols.map((s) => s.provider),
        everyElement(QuoteProvider.yahoo),
      );
    });

    test('the starter watchlist names each Greater China exchange once', () {
      // Yahoo routes a China listing by the suffix on its local ticker, so the
      // starter list carries one of each as a worked example for the settings
      // box.
      const c = MarketsConfig();
      expect(
        c.symbols.map((s) => s.symbol),
        containsAll(['600519.SS', '000001.SZ', '0700.HK']),
        reason: '.SS Shanghai, .SZ Shenzhen, .HK Hong Kong',
      );
    });

    test('every starter entry is routed where its prefix says', () {
      // The list is written by hand, so its `provider` field can disagree with
      // the prefix on its symbol — and then the settings box would round-trip
      // the entry to a different source than it started at. (`kind` is exempt:
      // the hand-written value is deliberately sharper than the provisional
      // `stock` that parsing an `em:` entry yields.)
      for (final s in MarketsConfig.defaultSymbols) {
        expect(
          s.provider,
          MarketSymbol.parse(s.symbol).provider,
          reason: s.symbol,
        );
      }
    });

    test('a corrupt symbols list falls back to the starter watchlist', () {
      final c = MarketsConfig.fromJson({'symbols': 'not-a-list'});
      expect(c.symbols, MarketsConfig.defaultSymbols);
    });

    test('an empty symbols list is a deliberate clear, not a fallback', () {
      final c = MarketsConfig.fromJson({'symbols': <Object?>[]});
      expect(c.symbols, isEmpty);
    });

    test('equal configs built differently agree on hashCode', () {
      final a = MarketsConfig.fromTickers(['AAPL'], proxy: 'a:1');
      // Same watchlist and proxy, reached the other way round.
      const b = MarketsConfig(
        symbols: [MarketSymbol(symbol: 'AAPL', kind: QuoteKind.stock)],
        proxy: 'a:1',
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });
  });
}
