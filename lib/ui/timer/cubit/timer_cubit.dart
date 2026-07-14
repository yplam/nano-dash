import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/timer_repository.dart';
import '../../../domain/models/timer.dart';

export '../../../domain/models/timer.dart' show PomodoroPhase;

part 'timer_state.dart';

/// Projects [TimerRepository] — which owns the presets, the running countdown
/// and the focus-session log — into the state the timer views render. It holds
/// no timer state of its own, so the agent and the UI always see one countdown.
class TimerCubit extends Cubit<TimerState> {
  TimerCubit(this._repository) : super(_project(_repository)) {
    _sub = _repository.changes.listen((_) {
      if (!isClosed) emit(_project(_repository));
    });
  }

  final TimerRepository _repository;

  late final StreamSubscription<void> _sub;

  static TimerState _project(TimerRepository repository) {
    final run = repository.run;
    return TimerState(
      timers: repository.timers,
      selectedId: run.selectedId,
      selectedName: run.selectedName,
      remaining: run.remaining,
      running: run.running,
      finished: run.finished,
      phase: run.phase,
      completedFocus: run.completedFocus,
      logs: repository.logs,
    );
  }

  /// Persist an edited preset list (from the settings view).
  Future<void> saveTimers(List<TimerConfig> timers) =>
      _repository.saveTimers(timers);

  /// Arm a timer for counting down, capturing its resolved [name] for logging.
  void select(String id, String name) => _repository.select(id, name);

  /// Start (or resume) the selected countdown.
  void start() => _repository.start();

  /// Pause, holding the remaining time.
  void pause() => _repository.pause();

  /// Stop and restore the current phase's full configured duration.
  void reset() => _repository.reset();

  /// Clear the recorded focus-session history.
  void clearStats() => _repository.clearStats();

  @override
  Future<void> close() async {
    await _sub.cancel();
    return super.close();
  }
}
