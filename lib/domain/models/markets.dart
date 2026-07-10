import 'json_model.dart';

/// A market-data source. The [id] doubles as the watchlist prefix a user writes
/// to route a symbol at that source (`em:600519`); an unprefixed ticker means
/// [QuoteProvider.yahoo].
enum QuoteProvider {
  yahoo('yahoo'),
  eastmoney('em');

  const QuoteProvider(this.id);

  /// The watchlist prefix and the JSON discriminator.
  final String id;

  static QuoteProvider? byId(String id) {
    for (final p in values) {
      if (p.id == id) return p;
    }
    return null;
  }
}

/// The broad kind of a tracked instrument, inferred from its ticker. Drives how
/// the UI formats the price (decimal places) and labels the row; the data
/// provider doesn't need it.
enum QuoteKind {
  stock,
  marketIndex,
  etf,
  crypto,
  forex;

  /// Best-effort classification from a Yahoo Finance ticker:
  ///  * `^GSPC`      → index (caret prefix)
  ///  * `BTC-USD`    → crypto (`-USD`/`-USDT` suffix)
  ///  * `EURUSD=X`   → forex (`=X` suffix)
  ///  * everything else → stock
  ///
  /// These are Yahoo's ticker conventions, so this is only meaningful for
  /// [QuoteProvider.yahoo] — which, being the default source, is where an
  /// unprefixed entry lands.
  static QuoteKind fromSymbol(String symbol) {
    final s = symbol.toUpperCase().trim();
    if (s.startsWith('^')) return QuoteKind.marketIndex;
    if (s.endsWith('=X')) return QuoteKind.forex;
    if (s.endsWith('-USD') || s.endsWith('-USDT') || s.endsWith('-USDC')) {
      return QuoteKind.crypto;
    }
    return QuoteKind.stock;
  }
}

/// One watchlist entry: a [provider], the ticker to ask it for, an optional
/// display override, and the instrument [kind]. Persisted as part of
/// [MarketsConfig].
class MarketSymbol implements JsonModel {
  const MarketSymbol({
    required this.symbol,
    this.label,
    required this.kind,
    this.provider = QuoteProvider.yahoo,
  });

  /// The entry exactly as the user wrote it, prefix and all (`^GSPC`,
  /// `BTC-USD`, `em:600519`).
  final String symbol;

  /// A user-friendly name to show instead of [symbol]; falls back to [symbol]
  /// when null.
  final String? label;

  final QuoteKind kind;

  final QuoteProvider provider;

  /// [symbol] with any `<provider>:` prefix stripped — what the provider's API
  /// actually expects (`600519` for `em:600519`, `^GSPC` for `^GSPC`).
  String get ticker {
    final prefix = '${provider.id}:';
    return symbol.toLowerCase().startsWith(prefix)
        ? symbol.substring(prefix.length)
        : symbol;
  }

  /// Build an entry from a raw watchlist line: route it by its `<provider>:`
  /// prefix (falling back to Yahoo) and infer [kind] from the ticker's shape.
  factory MarketSymbol.parse(String symbol) {
    final s = symbol.trim();
    final colon = s.indexOf(':');
    if (colon > 0) {
      final provider = QuoteProvider.byId(s.substring(0, colon).toLowerCase());
      if (provider != null) {
        return MarketSymbol(
          symbol: s,
          provider: provider,
          kind: provider == QuoteProvider.eastmoney
              ? QuoteKind.stock
              : QuoteKind.fromSymbol(s.substring(colon + 1)),
        );
      }
    }
    // Unprefixed: Yahoo, whose ticker shape names the kind.
    return MarketSymbol(symbol: s, kind: QuoteKind.fromSymbol(s));
  }

  factory MarketSymbol.fromJson(Map<String, Object?> json) {
    final symbol = json['symbol'] as String? ?? '';
    // Re-derive provider and kind from the raw entry for any field the stored
    // object is missing.
    final fallback = MarketSymbol.parse(symbol);
    final kindName = json['kind'] as String?;
    final providerId = json['provider'] as String?;
    return MarketSymbol(
      symbol: symbol,
      label: json['label'] as String?,
      kind: QuoteKind.values.asNameMap()[kindName] ?? fallback.kind,
      provider: providerId == null
          ? fallback.provider
          : QuoteProvider.byId(providerId) ?? fallback.provider,
    );
  }

  @override
  Map<String, Object?> toJson() => {
    'symbol': symbol,
    if (label != null) 'label': label,
    'kind': kind.name,
    'provider': provider.id,
  };

  @override
  bool operator ==(Object other) =>
      other is MarketSymbol &&
      other.symbol == symbol &&
      other.label == label &&
      other.kind == kind &&
      other.provider == provider;

  @override
  int get hashCode => Object.hash(symbol, label, kind, provider);
}

/// A live reading for one instrument. Not persisted — produced by the service on
/// every poll.
class Quote {
  const Quote({
    required this.symbol,
    required this.displayName,
    required this.kind,
    required this.price,
    required this.change,
    required this.changePercent,
    this.dayLow,
    this.dayHigh,
    this.currency,
    this.asOf,
  });

  final String symbol;
  final String displayName;
  final QuoteKind kind;
  final double price;

  /// Absolute change from the previous close, in [currency].
  final double change;

  /// Percentage change from the previous close.
  final double changePercent;

  final double? dayLow;
  final double? dayHigh;
  final String? currency;
  final DateTime? asOf;

  /// True when the instrument is flat or up on the session; drives the up/down
  /// colour and arrow.
  bool get isUp => change >= 0;

  /// Whether a session low/high range is available and non-degenerate, so the
  /// range bar can be drawn.
  bool get hasRange {
    final lo = dayLow;
    final hi = dayHigh;
    return lo != null && hi != null && hi > lo;
  }
}

/// Persisted configuration for the markets module: the ordered watchlist and
/// the Yahoo proxy.
class MarketsConfig implements JsonModel {
  const MarketsConfig({this.symbols = defaultSymbols, this.proxy});

  /// The watchlist shown on first run, before the user edits it.
  static const List<MarketSymbol> defaultSymbols = [
    MarketSymbol(
      symbol: '600519.SS',
      label: 'Kweichow Moutai',
      kind: QuoteKind.stock,
    ),
    MarketSymbol(
      symbol: '000001.SZ',
      label: 'Ping An Bank',
      kind: QuoteKind.stock,
    ),
    MarketSymbol(symbol: '0700.HK', label: 'Tencent', kind: QuoteKind.stock),
    MarketSymbol(
      symbol: '^GSPC',
      label: 'S&P 500',
      kind: QuoteKind.marketIndex,
    ),
    MarketSymbol(symbol: 'BTC-USD', label: 'Bitcoin', kind: QuoteKind.crypto),
    MarketSymbol(symbol: 'EURUSD=X', label: 'EUR/USD', kind: QuoteKind.forex),
  ];

  final List<MarketSymbol> symbols;

  /// Optional HTTP/SOCKS proxy for Yahoo Finance, e.g. `host:port`,
  /// `http://host:port`, or `socks5://host:port`. Blank or null fetches direct.
  /// Ignored on the web build (no proxy support).
  final String? proxy;

  /// The usable Yahoo proxy, or null when Yahoo should connect direct.
  String? get yahooProxy {
    final p = proxy?.trim() ?? '';
    return p.isEmpty ? null : p;
  }

  /// Build a config from raw watchlist lines (e.g. parsed from the settings
  /// text box), dropping blanks and routing each by its provider prefix.
  /// Preserves the existing [proxy] when re-parsing the watchlist text.
  factory MarketsConfig.fromTickers(
    Iterable<String> tickers, {
    String? proxy,
  }) => MarketsConfig(
    symbols: [
      for (final t in tickers)
        if (t.trim().isNotEmpty) MarketSymbol.parse(t),
    ],
    proxy: proxy,
  );

  factory MarketsConfig.fromJson(Map<String, Object?> json) {
    final raw = json['symbols'];
    final proxy = json['proxy'] as String?;
    // A missing/corrupt `symbols` falls back to the starter watchlist; an empty
    // list is a deliberate "I cleared it" and stays empty.
    if (raw is! List) return MarketsConfig(proxy: proxy);
    return MarketsConfig(
      symbols: [
        for (final e in raw)
          if (e is Map) MarketSymbol.fromJson(Map<String, Object?>.from(e)),
      ],
      proxy: proxy,
    );
  }

  @override
  Map<String, Object?> toJson() => {
    'symbols': [for (final s in symbols) s.toJson()],
    'proxy': ?yahooProxy,
  };

  @override
  bool operator ==(Object other) =>
      other is MarketsConfig &&
      // Compare the normalized proxy: a blank field and an absent one both mean
      // "connect direct", and must not read as a config change.
      other.yahooProxy == yahooProxy &&
      other.symbols.length == symbols.length &&
      _listEquals(other.symbols, symbols);

  @override
  int get hashCode => Object.hash(yahooProxy, Object.hashAll(symbols));

  static bool _listEquals(List<MarketSymbol> a, List<MarketSymbol> b) {
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

const marketsSettingsKey = SettingKey<MarketsConfig>(
  'markets_config_v1',
  MarketsConfig.fromJson,
  defaults: MarketsConfig(),
);
