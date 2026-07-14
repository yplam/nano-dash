import 'dart:async';
import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../data/repositories/calendar_repository.dart';
import '../../../../domain/models/calendar.dart';
import '../../../../extensions/loggable.dart';

part 'calendar_state.dart';

/// Owns the calendar module's settings state and drives polling. Mirrors
/// `WeatherCubit`: restore config, fetch immediately, then re-poll on a timer,
/// guarding against a slow in-flight fetch overwriting a newer one.
///
/// Polling runs at two cadences: a slow [_kBackgroundInterval] while the page is
/// off-screen, and a faster [_kForegroundInterval] while the user is viewing the
/// calendar. The view drives the switch via [onViewActive]/[onViewInactive].
class CalendarCubit extends Cubit<CalendarState> with Loggable {
  CalendarCubit(this._repository) : super(_restore(_repository)) {
    _fetch();
    _startTimer(_kBackgroundInterval);
  }

  final CalendarRepository _repository;

  /// How often to re-poll the feeds while the page is off-screen.
  static const Duration _kBackgroundInterval = Duration(minutes: 10);

  /// How often to re-poll while the user is viewing the calendar page.
  static const Duration _kForegroundInterval = Duration(minutes: 1);

  Timer? _timer;

  /// Guards against a slow in-flight fetch overwriting a newer one's result.
  int _requestId = 0;

  @override
  String get logIdentifier => '[CalendarCubit]';

  static CalendarState _restore(CalendarRepository repository) {
    return CalendarState(
      sources: repository.config.sources,
      range: repository.config.range,
    );
  }

  /// Replace the configured feeds and display range, persist them, and refetch
  /// when the feeds themselves changed. A range-only change is a display filter,
  /// so it persists without hitting the network.
  void setConfig(CalendarConfig config) {
    final feedsChanged =
        _encodeSources(state.sources) != _encodeSources(config.sources);
    emit(state.copyWith(sources: config.sources, range: config.range));
    _persist();
    if (feedsChanged) _fetch();
  }

  static String _encodeSources(List<CalendarSource> sources) =>
      jsonEncode([for (final s in sources) s.toJson()]);

  /// Re-poll now (e.g. pull-to-refresh or after an error).
  void refresh() => _fetch();

  /// Called when the calendar page is switched into view: fetch immediately and
  /// poll at the faster foreground cadence.
  void onViewActive() {
    _fetch();
    _startTimer(_kForegroundInterval);
  }

  /// Called when the calendar page is switched out of view: drop back to the
  /// slower background cadence.
  void onViewInactive() => _startTimer(_kBackgroundInterval);

  void _startTimer(Duration interval) {
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) => _fetch());
  }

  Future<void> _fetch() async {
    if (state.sources.where((s) => s.enabled).isEmpty) {
      emit(
        state.copyWith(
          events: const [],
          loading: false,
          clearError: true,
          sourceErrors: const {},
        ),
      );
      return;
    }

    final id = ++_requestId;
    emit(state.copyWith(loading: true, clearError: true));
    logInfo(
      'fetch: polling ${state.sources.where((s) => s.enabled).length} '
      'enabled source(s)',
    );
    try {
      final result = await _repository.fetch();
      if (isClosed || id != _requestId) return;
      if (result.hasErrors) {
        for (final entry in result.errors.entries) {
          logWarning('source ${entry.key} failed', error: entry.value);
        }
      }
      logInfo(
        'fetch done: ${result.events.length} event(s), '
        '${result.errors.length} source error(s)',
      );
      emit(
        state.copyWith(
          events: result.events,
          loading: false,
          // Surface an error only when every source failed; a partial result is
          // still worth showing.
          error: result.events.isEmpty && result.hasErrors
              ? result.errors.values.first
              : null,
          clearError: !(result.events.isEmpty && result.hasErrors),
          sourceErrors: {
            for (final e in result.errors.entries) e.key: e.value.toString(),
          },
        ),
      );
    } catch (e, s) {
      if (isClosed || id != _requestId) return;
      logWarning('calendar fetch failed', error: e, stackTrace: s);
      emit(state.copyWith(loading: false, error: e));
    }
  }

  void _persist() {
    _repository
        .save(CalendarConfig(sources: state.sources, range: state.range))
        .catchError((Object e, StackTrace s) {
          logError(
            'failed to persist calendar settings',
            error: e,
            stackTrace: s,
          );
        });
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
