import 'package:dio/dio.dart';

import '../../../domain/models/markets.dart';
import '../http_proxy_stub.dart' if (dart.library.io) '../http_proxy_io.dart';
import 'eastmoney_provider.dart';
import 'yahoo_finance_provider.dart';

/// Thrown when a market-data lookup can't complete.
class MarketsException implements Exception {
  MarketsException(this.message);

  final String message;

  @override
  String toString() => 'MarketsException: $message';
}

/// A source of live [Quote]s for a watchlist, kept behind an interface so
/// providers can be added without touching the repository or cubit.
abstract class MarketQuoteProvider {
  Future<List<Quote>> fetch(List<MarketSymbol> symbols);
}

/// Builds the provider for a [QuoteProvider] over a configured [Dio].
typedef QuoteProviderFactory = MarketQuoteProvider Function(Dio);

/// The stock providers, one per [QuoteProvider].
const Map<QuoteProvider, QuoteProviderFactory> _defaultProviders = {
  QuoteProvider.yahoo: YahooFinanceProvider.new,
  QuoteProvider.eastmoney: EastMoneyProvider.new,
};

/// Fetches live quotes for a watchlist whose entries may come from different
/// sources. Groups the watchlist by [QuoteProvider], fetches every group in
/// parallel, and merges the results back into the user's order.
class MarketsService {
  MarketsService(
    this._dio, {
    Map<QuoteProvider, QuoteProviderFactory> providers = _defaultProviders,
  }) : _factories = providers;

  final Dio _dio;
  final Map<QuoteProvider, QuoteProviderFactory> _factories;

  /// Fetch quotes for [config]'s watchlist, preserving watchlist order.
  Future<List<Quote>> fetch(MarketsConfig config) async {
    if (config.symbols.isEmpty) return const [];

    final groups = <QuoteProvider, List<MarketSymbol>>{};
    for (final s in config.symbols) {
      groups.putIfAbsent(s.provider, () => []).add(s);
    }

    final results = await Future.wait([
      for (final e in groups.entries) _fetchGroup(config, e.key, e.value),
    ]);
    if (results.every((r) => r == null)) {
      throw MarketsException('every quote provider failed');
    }

    final bySymbol = {
      for (final quotes in results)
        if (quotes != null)
          for (final q in quotes) q.symbol: q,
    };
    return [for (final s in config.symbols) ?bySymbol[s.symbol]];
  }

  /// Fetch one provider's slice of the watchlist, or null if it failed.
  Future<List<Quote>?> _fetchGroup(
    MarketsConfig config,
    QuoteProvider provider,
    List<MarketSymbol> symbols,
  ) async {
    final factory = _factories[provider];
    if (factory == null) return null;
    // Only Yahoo is proxyable; EastMoney answers proxied requests with delayed
    // quotes, so it always gets the shared, direct client.
    final client = _clientFor(
      provider == QuoteProvider.yahoo ? config.yahooProxy : null,
    );
    try {
      return await factory(client).fetch(symbols);
    } catch (_) {
      return null;
    } finally {
      // A per-fetch proxied client is single-use; release its sockets. The
      // shared [_dio] is left alone.
      if (!identical(client, _dio)) client.close();
    }
  }

  /// The Dio to fetch with: the shared client, or a throwaway one routed
  /// through [proxy]. Falls back to the shared client on the web build or an
  /// unusable proxy string.
  Dio _clientFor(String? proxy) {
    if (proxy == null) return _dio;
    final adapter = proxyAdapter(proxy);
    if (adapter == null) return _dio;
    return Dio(_dio.options)..httpClientAdapter = adapter;
  }
}
