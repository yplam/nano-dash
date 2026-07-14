import 'dart:async';

import '../../domain/models/app_config.dart';
import '../../domain/models/dashboard.dart';
import '../../domain/models/timer.dart';
import '../../extensions/loggable.dart';
import '../services/notification_service.dart';
import '../services/pico_view_service.dart';
import 'settings_repository.dart';

/// The transient countdown state: which preset is armed and where its
/// Pomodoro cycle stands. Immutable snapshot; [TimerRepository.run] is the
/// latest value.
class TimerRunState {
  const TimerRunState({
    this.selectedId,
    this.selectedName = '',
    this.remaining = Duration.zero,
    this.running = false,
    this.finished = false,
    this.phase = PomodoroPhase.focus,
    this.completedFocus = 0,
  });

  /// The timer the countdown currently applies to, or null when none is armed.
  final String? selectedId;

  /// The selected timer's resolved display name, captured when it was armed so
  /// completed focus sessions can be logged without access to localization.
  final String selectedName;

  /// Time left in the selected timer's countdown.
  final Duration remaining;

  /// Whether the selected timer's countdown is advancing.
  final bool running;

  /// Whether the current phase reached zero and is awaiting the next action
  /// (a reset, or — for a finished break — a manual focus restart).
  final bool finished;

  /// The current leg of the Pomodoro cycle for the selected timer.
  final PomodoroPhase phase;

  /// Focus sessions completed in the current cycle, counting towards the next
  /// long break. Reset to zero after a long break.
  final int completedFocus;

  TimerRunState copyWith({
    Duration? remaining,
    bool? running,
    bool? finished,
    PomodoroPhase? phase,
    int? completedFocus,
  }) {
    return TimerRunState(
      selectedId: selectedId,
      selectedName: selectedName,
      remaining: remaining ?? this.remaining,
      running: running ?? this.running,
      finished: finished ?? this.finished,
      phase: phase ?? this.phase,
      completedFocus: completedFocus ?? this.completedFocus,
    );
  }
}

/// App-scoped owner of the countdown timers: the configured presets, the one
/// running countdown (with its Pomodoro cycle), and the focus-session log
/// behind the statistics report.
class TimerRepository with Loggable {
  TimerRepository(
    this._settings,
    this._pico,
    this._notifications, {
    this.finishedText = 'Timer finished',
    this.focusDoneText = 'Focus complete — time for a break',
    this.breakDoneText = 'Break over — back to focus',
  }) {
    _timers = _loadOrMigrate();
    _logs = _settings.loadList(PomodoroLog.kKey, PomodoroLog.fromJson);
  }

  final SettingsRepository _settings;

  /// Plays the physical alert buzz on the panel. A no-op when no device is open.
  final PicoViewService _pico;

  /// Raises the host system notification (banner + OS sound) when a phase ends.
  /// A no-op stub on web; silent until it has initialized.
  final NotificationService _notifications;

  /// Localized notification bodies for each phase boundary, passed in because
  /// this repository is deliberately l10n-free. [finishedText] is a plain
  /// timer's completion; [focusDoneText]/[breakDoneText] are the Pomodoro legs.
  final String finishedText;
  final String focusDoneText;
  final String breakDoneText;

  /// Focus-session logs older than this are dropped on write, bounding growth.
  static const Duration _kRetention = Duration(days: 14);

  /// Readout update cadence while running.
  static const Duration _kTick = Duration(milliseconds: 100);

  /// The presets seeded when nothing has ever been stored: one plain countdown
  /// and one Pomodoro timer. Names are left empty and carried as semantic
  /// [TimerConfig.labelKey]s so they render in the active locale.
  static const List<TimerConfig> _defaultTimers = [
    TimerConfig(
      id: 'timer-countdown',
      name: '',
      labelKey: 'countdown',
      duration: Duration(minutes: 5),
    ),
    TimerConfig(
      id: 'timer-pomodoro',
      name: '',
      labelKey: 'pomodoro',
      duration: Duration(minutes: 25),
      pomodoro: true,
    ),
  ];

  /// Used to measure real elapsed time so the countdown stays accurate even if
  /// ticks are delayed by a busy UI/SPI flush.
  final Stopwatch _sw = Stopwatch();
  Timer? _ticker;

  final StreamController<void> _changes = StreamController<void>.broadcast();

  late List<TimerConfig> _timers;
  late List<PomodoroLog> _logs;
  TimerRunState _run = const TimerRunState();

  @override
  String get logIdentifier => '[TimerRepository]';

  /// All configured timers, in display order.
  List<TimerConfig> get timers => _timers;

  /// The full recorded focus-session history (for the statistics report).
  List<PomodoroLog> get logs => _logs;

  /// The current countdown snapshot.
  TimerRunState get run => _run;

  /// Fires after any change to [timers], [logs] or [run] (including every
  /// countdown tick while a timer is running).
  Stream<void> get changes => _changes.stream;

  /// The selected timer's config, or null if nothing is selected.
  TimerConfig? get selected => _find(_timers, _run.selectedId);

  /// The full configured length of the current phase: the selected timer's
  /// focus duration, or its short/long break when on a break leg.
  Duration get phaseDuration {
    final sel = selected;
    if (sel == null) return Duration.zero;
    switch (_run.phase) {
      case PomodoroPhase.focus:
        return sel.duration;
      case PomodoroPhase.shortBreak:
        return sel.shortBreak;
      case PomodoroPhase.longBreak:
        return sel.longBreak;
    }
  }

  /// Load the persisted presets, migrating them out of the dashboard
  /// module-settings blob (where they lived before this repository existed) on
  /// first run, or seeding the defaults on a fresh install.
  List<TimerConfig> _loadOrMigrate() {
    final stored = _settings.load(timerSettingsKey).timers;
    if (stored != null) return stored;

    List<TimerConfig>? legacy;
    final items = _settings.loadList(
      dashboardConfigKey,
      DashboardItemConfig.fromJson,
    );
    for (final item in items) {
      // 'timer' is TimerModule.kId; the module itself is UI and not imported here.
      if (item.moduleId != 'timer') continue;
      final raw = item.settings['timers'];
      if (raw is List) {
        legacy = raw
            .whereType<Map>()
            .map((m) => TimerConfig.fromJson(Map<String, Object?>.from(m)))
            .toList();
      }
    }
    final timers = legacy ?? _defaultTimers;
    logInfo(
      legacy != null
          ? 'migrated ${timers.length} timers from dashboard settings'
          : 'seeded ${timers.length} default timers',
    );
    unawaited(_settings.save(timerSettingsKey, TimerSettings(timers)));
    return timers;
  }

  Future<void> saveTimers(List<TimerConfig> timers) {
    final selectedBefore = selected;
    final wasFresh =
        selectedBefore != null &&
        !_run.running &&
        !_run.finished &&
        _run.phase == PomodoroPhase.focus &&
        _run.remaining == phaseDuration;

    _timers = List.unmodifiable(timers);
    final selectedAfter = selected;
    if (selectedBefore != null && selectedAfter == null) {
      _stopTicker();
      _sw
        ..stop()
        ..reset();
      _run = const TimerRunState();
    } else if (selectedAfter != null && wasFresh) {
      _run = _run.copyWith(remaining: selectedAfter.duration);
    }
    _emit();
    return _settings.save(timerSettingsKey, TimerSettings(_timers));
  }

  static TimerConfig? _find(List<TimerConfig> timers, String? id) {
    if (id == null) return null;
    for (final t in timers) {
      if (t.id == id) return t;
    }
    return null;
  }

  void select(String id, String name) {
    if (id == _run.selectedId) return;
    final cfg = _find(_timers, id);
    if (cfg == null) return;
    _stopTicker();
    _run = TimerRunState(
      selectedId: cfg.id,
      selectedName: name,
      remaining: cfg.duration,
    );
    _emit();
  }

  /// Start (or resume) the selected countdown.
  void start() {
    if (_run.running) return;
    var base = _run.remaining;
    if (base <= Duration.zero) {
      final sel = selected;
      if (sel == null || sel.pomodoro) return;
      base = phaseDuration;
    }
    if (base <= Duration.zero) return;
    // Prompt for notification permission for timers that will raise a sound
    // alert. This must ride the start tap's synchronous call stack.
    if (selected?.sound ?? false) unawaited(_notifications.requestPermission());
    _startTicker(base);
    _run = _run.copyWith(remaining: base, running: true, finished: false);
    _emit();
  }

  /// Pause, holding the remaining time.
  void pause() {
    if (!_run.running) return;
    _sw.stop();
    _stopTicker();
    _run = _run.copyWith(running: false);
    _emit();
  }

  /// Stop and restore the current phase's full configured duration.
  void reset() {
    _sw
      ..stop()
      ..reset();
    _stopTicker();
    _run = _run.copyWith(
      remaining: phaseDuration,
      running: false,
      finished: false,
    );
    _emit();
  }

  /// Begin (or resume) ticking against [base] — the remaining time when the run
  /// started. Used by both manual [start] and the auto-started break.
  void _startTicker(Duration base) {
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
    _run = _run.copyWith(remaining: left);
    _emit();
  }

  /// Drive the Pomodoro cycle when a phase reaches zero. Plain timers just
  /// finish; a finished focus session is logged and auto-rolls into a break;
  /// a finished break returns to focus and waits for a manual restart.
  void _onPhaseComplete() {
    final sel = selected;
    _fireAlert(sel);
    if (sel == null || !sel.pomodoro) {
      _run = _run.copyWith(
        remaining: Duration.zero,
        running: false,
        finished: true,
      );
      _emit();
      return;
    }

    if (_run.phase == PomodoroPhase.focus) {
      final completed = _run.completedFocus + 1;
      _appendLog(
        PomodoroLog(
          name: _run.selectedName,
          focusSeconds: sel.duration.inSeconds,
          completedAt: DateTime.now(),
        ),
      );
      const every = TimerConfig.longBreakEvery;
      final isLong = completed % every == 0;
      final breakDuration = isLong ? sel.longBreak : sel.shortBreak;
      _run = _run.copyWith(
        remaining: breakDuration,
        running: breakDuration > Duration.zero,
        finished: breakDuration <= Duration.zero,
        phase: isLong ? PomodoroPhase.longBreak : PomodoroPhase.shortBreak,
        completedFocus: completed,
      );
      _emit();
      // Auto-start the break (unless it has no length to count down).
      if (breakDuration > Duration.zero) _startTicker(breakDuration);
    } else {
      // Break over: back to a fresh focus, awaiting a manual start.
      final wasLong = _run.phase == PomodoroPhase.longBreak;
      _run = _run.copyWith(
        remaining: sel.duration,
        running: false,
        finished: true,
        phase: PomodoroPhase.focus,
        completedFocus: wasLong ? 0 : _run.completedFocus,
      );
      _emit();
    }
  }

  /// Signal a phase boundary, honouring the selected timer's alert preferences.
  /// The two channels are independent: [TimerConfig.vibrate] plays the globally
  /// configured [AppConfig.alertEffect] on the panel, while [TimerConfig.sound]
  /// raises a host system notification with the OS notification sound.
  ///
  /// Called at the top of [_onPhaseComplete], before the run's phase advances,
  /// so [_run.phase] still holds the leg that just finished.
  void _fireAlert(TimerConfig? sel) {
    if (sel == null) return;
    if (sel.vibrate) {
      _pico.playHaptic(_settings.load(appConfigKey).alertEffect);
    }
    if (sel.sound) {
      final (title, body) = _alertText(sel);
      unawaited(
        _notifications.notify(
          title: title,
          body: body,
          id: NotificationService.timerId,
        ),
      );
    }
  }

  /// The notification (title, body) for the phase that just completed.
  (String, String) _alertText(TimerConfig sel) {
    final name = _run.selectedName;
    final String status;
    if (!sel.pomodoro) {
      status = finishedText;
    } else {
      status = _run.phase == PomodoroPhase.focus
          ? focusDoneText
          : breakDoneText;
    }
    return name.isEmpty ? (status, '') : (name, status);
  }

  /// Append [log] to the history, trim entries past the retention window, and
  /// persist.
  void _appendLog(PomodoroLog log) {
    final cutoff = DateTime.now().subtract(_kRetention);
    _logs = [
      for (final l in _logs)
        if (l.completedAt.isAfter(cutoff)) l,
      log,
    ];
    unawaited(_settings.saveList(PomodoroLog.kKey, _logs));
  }

  /// Clear the recorded focus-session history.
  void clearStats() {
    _logs = const [];
    unawaited(_settings.saveList(PomodoroLog.kKey, _logs));
    _emit();
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  void _emit() {
    if (!_changes.isClosed) _changes.add(null);
  }

  Future<void> dispose() async {
    _stopTicker();
    await _changes.close();
  }
}
