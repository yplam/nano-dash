import 'package:fake_async/fake_async.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:nano_dash/data/repositories/module_repository.dart';
import 'package:nano_dash/data/repositories/settings_repository.dart';
import 'package:nano_dash/data/services/locator.dart';
import 'package:nano_dash/data/services/panel_display_controller.dart';
import 'package:nano_dash/domain/models/dashboard.dart';
import 'package:nano_dash/domain/models/module.dart';
import 'package:nano_dash/l10n/app_localizations.dart';
import 'package:nano_dash/ui/dashboard/cubit/dashboard_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A bare displayable module; visibility lives in the config, not here.
class _TestModule extends Module {
  const _TestModule(this._id);
  final String _id;
  @override
  String get id => _id;
  @override
  IconData get icon => Icons.dashboard;
  @override
  String title(AppLocalizations l10n) => _id;
}

void main() {
  setUpAll(() {
    if (!locator.isRegistered<Logger>()) {
      locator.registerSingleton<Logger>(Logger(level: Level.off));
    }
  });

  late SettingsRepository settings;
  late ModuleRepository modules;
  late PanelDisplayController display;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    settings = SettingsRepository(prefs);
    modules = ModuleRepository(const [
      _TestModule('a'),
      _TestModule('b'),
      _TestModule('c'),
    ]);
    display = PanelDisplayController();
  });

  tearDown(() => display.dispose());

  /// A loaded cubit with a=carousel, b=carousel, c=assistant-only.
  DashboardCubit configured() {
    final cubit = DashboardCubit(settings, modules, display)..load();
    cubit.setVisibility('a', ModuleVisibility.carousel);
    cubit.setVisibility('b', ModuleVisibility.carousel);
    cubit.setVisibility('c', ModuleVisibility.assistant);
    return cubit;
  }

  test('publishes the assistant-visible ids to the controller', () {
    final cubit = configured();
    addTearDown(cubit.close);
    expect(display.displayable, {'a', 'b', 'c'});
    cubit.setVisibility('c', ModuleVisibility.off);
    expect(display.displayable, {'a', 'b'});
    expect(display.canShow('c'), isFalse);
  });

  test('showModule brings an assistant-only module up as a transient page', () {
    final cubit = configured();
    addTearDown(cubit.close);
    expect(cubit.state.showingTemp, isFalse);

    cubit.showModule('c');
    expect(cubit.state.showingTemp, isTrue);
    expect(cubit.state.tempModuleId, 'c');
    expect(cubit.state.tempReturnPage, 0);
  });

  test('a swipe dismisses the transient page back to the previous one', () {
    final cubit = configured();
    addTearDown(cubit.close);
    cubit.nextPage(); // move to page b (index 1)
    expect(cubit.state.currentPage, 1);

    cubit.showModule('c');
    expect(cubit.state.showingTemp, isTrue);
    expect(cubit.state.tempReturnPage, 1);

    cubit.nextPage(); // a swipe while temp: dismiss, not step
    expect(cubit.state.showingTemp, isFalse);
    expect(cubit.state.currentPage, 1);
  });

  test('showModule shows a carousel module transiently and returns', () {
    fakeAsync((async) {
      final cubit = configured();
      addTearDown(cubit.close);
      // 'b' is a real carousel page, but an agent-shown page must never strand
      // the user on it: it comes up transiently over the current page and
      // returns there after the idle timeout.
      cubit.showModule('b');
      expect(cubit.state.showingTemp, isTrue);
      expect(cubit.state.tempModuleId, 'b');
      expect(cubit.state.tempReturnPage, 0);

      async.elapse(const Duration(seconds: 21));
      expect(cubit.state.showingTemp, isFalse);
      expect(cubit.state.currentPage, 0);
    });
  });

  test('showModule ignores off/unknown modules', () {
    final cubit = configured();
    addTearDown(cubit.close);
    cubit.showModule('nope');
    expect(cubit.state.showingTemp, isFalse);

    cubit.setVisibility('c', ModuleVisibility.off);
    cubit.showModule('c');
    expect(cubit.state.showingTemp, isFalse);
  });

  test('a controller request drives the transient page', () {
    fakeAsync((async) {
      final cubit = configured();
      addTearDown(cubit.close);
      display.show('c');
      async.flushMicrotasks();
      expect(cubit.state.showingTemp, isTrue);

      // Auto-returns after the idle timeout.
      async.elapse(const Duration(seconds: 21));
      expect(cubit.state.showingTemp, isFalse);
      expect(cubit.state.currentPage, 0);
    });
  });

  test('a sticky request lands on the carousel page and stays', () {
    fakeAsync((async) {
      final cubit = configured();
      addTearDown(cubit.close);
      // 'b' is carousel page index 1; a sticky show jumps there and stays,
      // rather than peeking over page 0 and sliding back.
      display.goTo('b');
      async.flushMicrotasks();
      expect(cubit.state.showingTemp, isFalse);
      expect(cubit.state.currentPage, 1);

      // No auto-return: still on 'b' well past the transient timeout.
      async.elapse(const Duration(seconds: 21));
      expect(cubit.state.showingTemp, isFalse);
      expect(cubit.state.currentPage, 1);
    });
  });

  test('a sticky request for the current page does not churn the display', () {
    fakeAsync((async) {
      final cubit = configured();
      addTearDown(cubit.close);
      cubit.nextPage(); // on page 'b' (index 1)
      expect(cubit.state.currentPage, 1);

      final states = <DashboardState>[];
      final sub = cubit.stream.listen(states.add);
      addTearDown(sub.cancel);

      // Already on the timer-like page: a sticky request must not slide to a
      // transient page and back — it should emit nothing at all.
      display.goTo('b');
      async.flushMicrotasks();
      async.elapse(const Duration(seconds: 21));

      expect(states, isEmpty);
      expect(cubit.state.currentPage, 1);
      expect(cubit.state.showingTemp, isFalse);
    });
  });

  test('showModule is a no-op for the current carousel page', () {
    final cubit = configured();
    addTearDown(cubit.close);
    cubit.nextPage(); // on page 'b' (index 1)
    expect(cubit.state.currentPage, 1);

    final states = <DashboardState>[];
    final sub = cubit.stream.listen(states.add);
    addTearDown(sub.cancel);

    // The agent asks to show 'b' while 'b' is already the visible page (e.g. it
    // started a timer and then also called show_on_screen for it): no transient
    // slide over the identical page.
    cubit.showModule('b');
    expect(states, isEmpty);
    expect(cubit.state.showingTemp, isFalse);
    expect(cubit.state.currentPage, 1);
  });

  test('showModule is a no-op when the module is already the transient page', () {
    fakeAsync((async) {
      final cubit = configured();
      addTearDown(cubit.close);
      cubit.showModule('c'); // transient page 'c' up
      expect(cubit.state.tempModuleId, 'c');

      final states = <DashboardState>[];
      final sub = cubit.stream.listen(states.add);
      addTearDown(sub.cancel);

      cubit.showModule('c'); // asked again while already showing 'c'
      async.flushMicrotasks();
      expect(states, isEmpty);
      expect(cubit.state.tempModuleId, 'c');
    });
  });

  test('a sticky request for an assistant-only module falls back to transient', () {
    fakeAsync((async) {
      final cubit = configured();
      addTearDown(cubit.close);
      // 'c' has no carousel page to stay on, so a sticky request degrades to a
      // transient page that auto-returns.
      display.goTo('c');
      async.flushMicrotasks();
      expect(cubit.state.showingTemp, isTrue);
      expect(cubit.state.tempModuleId, 'c');

      async.elapse(const Duration(seconds: 21));
      expect(cubit.state.showingTemp, isFalse);
      expect(cubit.state.currentPage, 0);
    });
  });
}
