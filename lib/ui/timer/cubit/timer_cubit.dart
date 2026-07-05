import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/settings_repository.dart';
import '../../../data/services/pico_view_service.dart';
import '../../../domain/models/app_config.dart';
import '../models/pomodoro_log.dart';
import '../models/timer_config.dart';

part 'timer_state.dart';

/// Owns the countdown timer module's state, including the Pomodoro cycle and the
/// focus-session log that backs the statistics report.
class TimerCubit extends Cubit<TimerState> {
  TimerCubit(this._settings, this._pico) : super(const TimerState()) {
    final logs = _settings.loadList(PomodoroLog.kKey, PomodoroLog.fromJson);
    if (logs.isNotEmpty) emit(state.copyWith(logs: logs));
  }

  final SettingsRepository _settings;

  /// Plays the physical alert buzz on the panel. A no-op when no device is open.
  final PicoViewService _pico;

  /// Focus-session logs older than this are dropped on write, bounding growth.
  static const Duration _kRetention = Duration(days: 14);

  /// Readout update cadence while running.
  static const Duration _kTick = Duration(milliseconds: 100);

  /// Used to measure real elapsed time so the countdown stays accurate even if
  /// ticks are delayed by a busy UI/SPI flush.
  final Stopwatch _sw = Stopwatch();
  Timer? _ticker;

  /// Mirror the persisted timer list into the cubit. Called by the view when
  /// the configured timers change.
  void syncTimers(List<TimerConfig> timers) {
    final selected = _find(timers, state.selectedId);

    if (selected == null) {
      if (state.selectedId != null) {
        _stopTicker();
        emit(TimerState(timers: timers, logs: state.logs));
      } else {
        emit(state.copyWith(timers: timers));
      }
      return;
    }

    final fresh =
        !state.running &&
        !state.finished &&
        state.phase == PomodoroPhase.focus &&
        state.remaining == state.duration;
    if (fresh) {
      emit(
        TimerState(
          timers: timers,
          selectedId: selected.id,
          selectedName: state.selectedName,
          remaining: selected.duration,
          logs: state.logs,
        ),
      );
    } else {
      emit(state.copyWith(timers: timers));
    }
  }

  static TimerConfig? _find(List<TimerConfig> timers, String? id) {
    if (id == null) return null;
    for (final t in timers) {
      if (t.id == id) return t;
    }
    return null;
  }

  /// Arm a timer for counting down, capturing its resolved [name] for logging.
  /// Re-selecting the current timer is a no-op so opening its detail view never
  /// discards an in-progress (paused) countdown or running Pomodoro cycle;
  /// switching to a different timer resets the previous one back to focus.
  void select(String id, String name) {
    if (id == state.selectedId) return;
    final cfg = _find(state.timers, id);
    if (cfg == null) return;
    _stopTicker();
    emit(
      TimerState(
        timers: state.timers,
        selectedId: cfg.id,
        selectedName: name,
        remaining: cfg.duration,
        logs: state.logs,
      ),
    );
  }

  /// Start (or resume) the selected countdown.
  void start() {
    if (state.running || state.remaining <= Duration.zero) return;
    _run(state.remaining);
    emit(state.copyWith(running: true, finished: false));
  }

  /// Pause, holding the remaining time.
  void pause() {
    if (!state.running) return;
    _sw.stop();
    _stopTicker();
    emit(state.copyWith(running: false));
  }

  /// Stop and restore the current phase's full configured duration.
  void reset() {
    _sw
      ..stop()
      ..reset();
    _stopTicker();
    emit(
      state.copyWith(
        remaining: state.duration,
        running: false,
        finished: false,
      ),
    );
  }

  /// Begin (or resume) ticking against [base] — the remaining time when the run
  /// started. Used by both manual [start] and the auto-started break.
  void _run(Duration base) {
    _sw
      ..reset()
      ..start();
    _ticker = Timer.periodic(_kTick, (_) => _onTick(base));
  }

  /// Recompute remaining time from real elapsed against [base]. Hands off to the
  /// phase-completion logic when it hits zero.
  void _onTick(Duration base) {
    final left = base - _sw.elapsed;
    if (left <= Duration.zero) {
      _sw.stop();
      _stopTicker();
      _onPhaseComplete();
      return;
    }
    emit(state.copyWith(remaining: left));
  }

  /// Drive the Pomodoro cycle when a phase reaches zero. Plain timers just
  /// finish; a finished focus session is logged and auto-rolls into a break;
  /// a finished break returns to focus and waits for a manual restart.
  void _onPhaseComplete() {
    final sel = state.selected;
    _fireAlert(sel);
    if (sel == null || !sel.pomodoro) {
      emit(
        state.copyWith(
          remaining: Duration.zero,
          running: false,
          finished: true,
        ),
      );
      return;
    }

    if (state.phase == PomodoroPhase.focus) {
      final completed = state.completedFocus + 1;
      final logs = _appendLog(
        PomodoroLog(
          name: state.selectedName,
          focusSeconds: sel.duration.inSeconds,
          completedAt: DateTime.now(),
        ),
      );
      const every = TimerConfig.longBreakEvery;
      final isLong = completed % every == 0;
      final breakDuration = isLong ? sel.longBreak : sel.shortBreak;
      emit(
        state.copyWith(
          remaining: breakDuration,
          running: breakDuration > Duration.zero,
          finished: breakDuration <= Duration.zero,
          phase: isLong ? PomodoroPhase.longBreak : PomodoroPhase.shortBreak,
          completedFocus: completed,
          logs: logs,
        ),
      );
      // Auto-start the break (unless it has no length to count down).
      if (breakDuration > Duration.zero) _run(breakDuration);
    } else {
      // Break over: back to a fresh focus, awaiting a manual start.
      final wasLong = state.phase == PomodoroPhase.longBreak;
      emit(
        state.copyWith(
          remaining: sel.duration,
          running: false,
          finished: true,
          phase: PomodoroPhase.focus,
          completedFocus: wasLong ? 0 : state.completedFocus,
        ),
      );
    }
  }

  /// Signal a phase boundary on the panel, honouring the selected timer's alert
  /// preferences. Vibration plays the globally configured [AppConfig.alertEffect]
  /// (read fresh so a settings change is picked up); [playHaptic] is itself a
  /// no-op when the effect is "none" or no device is open.
  ///
  /// TODO(sound): honour [TimerConfig.sound] here once host/device audio
  /// playback is wired up — deferred for now, so the flag stays inert.
  void _fireAlert(TimerConfig? sel) {
    if (sel == null || !sel.vibrate) return;
    _pico.playHaptic(_settings.load(appConfigKey).alertEffect);
  }

  /// Append [log] to the history, trim entries past the retention window, and persist.
  List<PomodoroLog> _appendLog(PomodoroLog log) {
    final cutoff = DateTime.now().subtract(_kRetention);
    final updated = [
      for (final l in state.logs)
        if (l.completedAt.isAfter(cutoff)) l,
      log,
    ];
    unawaited(_settings.saveList(PomodoroLog.kKey, updated));
    return updated;
  }

  /// Clear the recorded focus-session history.
  void clearStats() {
    unawaited(_settings.saveList(PomodoroLog.kKey, const <PomodoroLog>[]));
    emit(state.copyWith(logs: const []));
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  @override
  Future<void> close() {
    _ticker?.cancel();
    return super.close();
  }
}
