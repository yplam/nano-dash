import 'dart:async';

import '../../domain/models/app_config.dart';
import '../../domain/models/reminder.dart';
import '../../extensions/loggable.dart';
import '../services/pico_view_service.dart';
import 'settings_repository.dart';

/// A reminder coming due: [missed] is true when its time passed while the app
/// was closed, so the announcement can say so instead of pretending it's on
/// time.
class ReminderFired {
  const ReminderFired(this.reminder, {required this.missed});

  final Reminder reminder;
  final bool missed;
}

/// App-scoped owner of the agent-created reminders: it persists them, arms an
/// in-process timer per reminder (re-armed from storage on startup), and when
/// one comes due removes it, buzzes the panel, and emits it on [fired].
class ReminderRepository with Loggable {
  ReminderRepository(this._settings, this._pico) {
    _reminders = _settings.loadList(Reminder.kKey, Reminder.fromJson);
    for (final reminder in _reminders) {
      _arm(reminder);
    }
    if (_reminders.isNotEmpty) {
      logInfo('re-armed ${_reminders.length} persisted reminders');
    }
  }

  final SettingsRepository _settings;

  /// Plays the physical alert buzz on the panel. A no-op when no device is open.
  final PicoViewService _pico;

  final StreamController<ReminderFired> _fired =
      StreamController<ReminderFired>.broadcast();

  final Map<String, Timer> _timers = {};

  late List<Reminder> _reminders;

  @override
  String get logIdentifier => '[ReminderRepository]';

  /// The pending reminders, soonest first.
  List<Reminder> get reminders {
    final sorted = [..._reminders]..sort((a, b) => a.dueAt.compareTo(b.dueAt));
    return List.unmodifiable(sorted);
  }

  /// Reminders coming due, each fired exactly once.
  Stream<ReminderFired> get fired => _fired.stream;

  /// Schedule a new reminder and persist it.
  Future<Reminder> add(String text, DateTime dueAt) async {
    final reminder = Reminder(id: Reminder.newId(), text: text, dueAt: dueAt);
    _reminders = [..._reminders, reminder];
    _arm(reminder);
    logInfo('added reminder ${reminder.id} at $dueAt: "$text"');
    await _persist();
    return reminder;
  }

  /// Cancel a pending reminder. Returns false when [id] matches nothing.
  Future<bool> cancel(String id) async {
    final before = _reminders.length;
    _reminders = [
      for (final r in _reminders)
        if (r.id != id) r,
    ];
    if (_reminders.length == before) return false;
    _timers.remove(id)?.cancel();
    logInfo('cancelled reminder $id');
    await _persist();
    return true;
  }

  /// Arm the countdown for [reminder]. A due time already in the past fires on
  /// the next event-loop turn as missed.
  void _arm(Reminder reminder) {
    final delay = reminder.dueAt.difference(DateTime.now());
    final missed = delay.isNegative;
    _timers[reminder.id] = Timer(
      missed ? Duration.zero : delay,
      () => _onDue(reminder, missed: missed),
    );
  }

  void _onDue(Reminder reminder, {required bool missed}) {
    _timers.remove(reminder.id);
    _reminders = [
      for (final r in _reminders)
        if (r.id != reminder.id) r,
    ];
    unawaited(_persist());
    logInfo('reminder ${reminder.id} due (missed=$missed): "${reminder.text}"');
    // The buzz mirrors the timer alert: the globally configured effect, a
    // no-op when it's "none" or no device is open.
    _pico.playHaptic(_settings.load(appConfigKey).alertEffect);
    if (!_fired.isClosed) _fired.add(ReminderFired(reminder, missed: missed));
  }

  Future<void> _persist() => _settings.saveList(Reminder.kKey, _reminders);

  Future<void> dispose() async {
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
    await _fired.close();
  }
}
