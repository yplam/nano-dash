import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/usage_monitor_repository.dart';
import '../../../domain/models/usage_monitor.dart';
import '../../../extensions/loggable.dart';

part 'usage_monitor_state.dart';

/// Owns the usage monitor settings and drives polling of every enabled
/// provider's rolling rate-limit usage.
///
/// Polling runs at two cadences: a slow [_kBackgroundInterval] while the page is
/// off-screen, and a faster [_kForegroundInterval] while the user is viewing the
/// module.
class UsageMonitorCubit extends Cubit<UsageMonitorState> with Loggable {
  UsageMonitorCubit(this._repository) : super(_restore(_repository)) {
    _fetch();
    _startTimer(_kBackgroundInterval);
  }

  final UsageMonitorRepository _repository;

  /// How often to re-poll while the page is off-screen. Rate-limit windows move
  /// slowly, so a slow cadence keeps the reset countdowns honest without churn.
  static const Duration _kBackgroundInterval = Duration(minutes: 10);

  /// How often to re-poll while the user is viewing the module.
  static const Duration _kForegroundInterval = Duration(minutes: 1);

  Timer? _timer;

  /// Guards against a slow in-flight fetch overwriting a newer one's result.
  int _requestId = 0;

  @override
  String get logIdentifier => '[UsageMonitorCubit]';

  static UsageMonitorState _restore(UsageMonitorRepository repository) =>
      UsageMonitorState(config: repository.config, usage: repository.current);

  /// Replace the config, persist it, and refetch.
  void setConfig(UsageMonitorConfig config) {
    if (config == state.config) return;
    emit(state.copyWith(config: config));
    _persist();
    _fetch();
  }

  /// Force an immediate refresh (e.g. a manual pull).
  void refresh() => _fetch();

  /// Called when the module is switched into view: fetch immediately and poll at
  /// the faster foreground cadence.
  void onViewActive() {
    _fetch();
    _startTimer(_kForegroundInterval);
  }

  /// Called when the module is switched out of view: drop back to the slower
  /// background cadence.
  void onViewInactive() => _startTimer(_kBackgroundInterval);

  void _startTimer(Duration interval) {
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) => _fetch());
  }

  Future<void> _fetch() async {
    final id = ++_requestId;
    emit(state.copyWith(loading: true));
    try {
      final usage = await _repository.fetch();
      if (isClosed || id != _requestId) return;
      emit(state.copyWith(usage: usage, loading: false));
    } catch (e, s) {
      if (isClosed || id != _requestId) return;
      logWarning('fetch failed', error: e, stackTrace: s);
      emit(state.copyWith(loading: false));
    }
  }

  void _persist() {
    _repository.save(state.config).catchError((Object e, StackTrace s) {
      logError('failed to persist usage settings', error: e, stackTrace: s);
    });
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
