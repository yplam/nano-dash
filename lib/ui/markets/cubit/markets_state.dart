part of 'markets_cubit.dart';

/// View state for the markets widget.
class MarketsState {
  const MarketsState({
    required this.config,
    this.quotes,
    this.loading = false,
    this.error,
  });

  final MarketsConfig config;

  /// The most recent quotes, in watchlist order, or `null` before the first
  /// successful fetch (or after the watchlist is cleared).
  final List<Quote>? quotes;

  final bool loading;

  /// The error from the most recent failed fetch, or `null` if the last fetch
  /// succeeded.
  final Object? error;

  MarketsState copyWith({
    MarketsConfig? config,
    List<Quote>? quotes,
    bool clearQuotes = false,
    bool? loading,
    Object? error,
    bool clearError = false,
  }) {
    return MarketsState(
      config: config ?? this.config,
      quotes: clearQuotes ? null : (quotes ?? this.quotes),
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}
