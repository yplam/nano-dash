import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:nano_dash/data/repositories/reminder_repository.dart';
import 'package:nano_dash/data/repositories/settings_repository.dart';
import 'package:nano_dash/data/repositories/timer_repository.dart';
import 'package:nano_dash/data/services/agent_tools.dart';
import 'package:nano_dash/data/services/locator.dart';
import 'package:nano_dash/data/services/notification_service.dart';
import 'package:nano_dash/data/services/pico_view_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Exercises [buildAgentContext] over cached repository state only — no network,
/// no weather/calendar service — covering the always-current timer and reminder
/// sections and the empty→null contract.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    // The repositories log through the Loggable mixin, which resolves its
    // Logger from the app's GetIt locator.
    if (!locator.isRegistered<Logger>()) {
      locator.registerSingleton<Logger>(Logger(level: Level.off));
    }
  });

  late SettingsRepository settings;
  late PicoViewService pico;
  late NotificationService notifications;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    settings = SettingsRepository(prefs);
    pico = PicoViewService();
    notifications = NotificationService();
  });

  test('returns null when no source has anything to report', () {
    expect(buildAgentContext(), isNull);
  });

  test('summarizes the configured timers and pending reminders', () async {
    // A fresh TimerRepository seeds the two default presets (a countdown and a
    // Pomodoro), so the timers section is always present.
    final timers = TimerRepository(settings, pico, notifications);
    final reminders = ReminderRepository(settings, pico);
    addTearDown(timers.dispose);
    addTearDown(reminders.dispose);

    await reminders.add('call mom', DateTime.now().add(const Duration(hours: 2)));

    final ctx = buildAgentContext(timers: timers, reminders: reminders)!;
    expect(ctx, contains('Timers:'));
    // The default Pomodoro preset is flagged as such.
    expect(ctx, contains('(Pomodoro)'));
    expect(ctx, contains('Pending reminders:'));
    expect(ctx, contains('call mom'));
  });

  test('reflects the armed timer as active state', () async {
    final timers = TimerRepository(settings, pico, notifications);
    addTearDown(timers.dispose);

    final countdown = timers.timers.firstWhere((t) => !t.pomodoro);
    timers.select(countdown.id, 'Countdown');
    timers.start();

    final ctx = buildAgentContext(timers: timers)!;
    expect(ctx, contains('Active: Countdown'));
    expect(ctx, contains('running'));
  });
}
