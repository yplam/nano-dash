import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/usage_monitor_repository.dart';
import '../../../domain/models/usage_monitor.dart';
import '../../../extensions/loggable.dart';

part 'usage_monitor_state.dart';

/// Owns the usage monitor settings and drives polling of every enabled
/// provider's rolling rate-limit usage.
///
/// Providers (Claude in particular) enforce their own rate limits, so polling
/// runs at a single steady [_kPollInterval] whether or not the module is
/// on-screen — we never poll faster in the foreground. Bringing the module into
/// view only triggers an extra fetch when the last poll has already gone stale.
class UsageMonitorCubit extends Cubit<UsageMonitorState> with Loggable {
  UsageMonitorCubit(this._repository) : super(_restore(_repository)) {
    _fetch();
    _timer = Timer.periodic(_kPollInterval, (_) => _fetch());
  }

  final UsageMonitorRepository _repository;

  /// How often to re-poll usage. Rate-limit windows move slowly and the
  /// upstream APIs are themselves rate limited, so a single slow cadence keeps
  /// the reset countdowns honest without risking throttling.
  static const Duration _kPollInterval = Duration(minutes: 10);

  Timer? _timer;

  /// Guards against a slow in-flight fetch overwriting a newer one's result.
  int _requestId = 0;

  /// When the most recent fetch was *started*. Used to throttle the extra fetch
  /// on view activation so rapid view switches can't hammer a rate-limited API.
  DateTime? _lastFetchStarted;

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

  /// Called when the module is switched into view. The steady background poll
  /// keeps data reasonably fresh, so only fetch here when the last poll is
  /// already older than [_kPollInterval] — this avoids extra rate-limit
  /// pressure from repeatedly switching the module in and out of view.
  void onViewActive() {
    final last = _lastFetchStarted;
    if (last == null || DateTime.now().difference(last) >= _kPollInterval) {
      _fetch();
    }
  }

  /// The poll runs at a single cadence regardless of visibility, so there is
  /// nothing to do when the module leaves the view.
  void onViewInactive() {}

  Future<void> _fetch() async {
    final id = ++_requestId;
    _lastFetchStarted = DateTime.now();
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
