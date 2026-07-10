import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../data/repositories/markets_repository.dart';
import '../../../../domain/models/markets.dart';
import '../../../../extensions/loggable.dart';

part 'markets_state.dart';

/// Owns the markets watchlist settings and drives polling.
class MarketsCubit extends Cubit<MarketsState> with Loggable {
  MarketsCubit(this._repository) : super(_restore(_repository)) {
    _fetch();
    _timer = Timer.periodic(_kRefreshInterval, (_) => _fetch());
  }

  final MarketsRepository _repository;

  /// How often to re-poll quotes.
  static const Duration _kRefreshInterval = Duration(seconds: 300);

  Timer? _timer;

  /// Guards against a slow in-flight fetch overwriting a newer one's result.
  int _requestId = 0;

  @override
  String get logIdentifier => '[MarketsCubit]';

  static MarketsState _restore(MarketsRepository repository) {
    return MarketsState(config: repository.config);
  }

  /// Replace the watchlist, persist it, and refetch.
  void setConfig(MarketsConfig config) {
    if (config == state.config) return;
    emit(state.copyWith(config: config, clearQuotes: true, clearError: true));
    _persist();
    _fetch();
  }

  Future<void> _fetch() async {
    // No symbols configured: nothing to fetch or display.
    if (state.config.symbols.isEmpty) {
      emit(state.copyWith(clearQuotes: true, loading: false, clearError: true));
      return;
    }

    final id = ++_requestId;
    emit(state.copyWith(loading: true, clearError: true));
    try {
      final quotes = await _repository.fetch();
      if (isClosed || id != _requestId) return;
      emit(state.copyWith(quotes: quotes, loading: false, clearError: true));
    } catch (e, s) {
      if (isClosed || id != _requestId) return;
      logWarning('fetch failed', error: e, stackTrace: s);
      emit(state.copyWith(loading: false, error: e));
    }
  }

  void _persist() {
    _repository.save(state.config).catchError((Object e, StackTrace s) {
      logError('failed to persist markets settings', error: e, stackTrace: s);
    });
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
