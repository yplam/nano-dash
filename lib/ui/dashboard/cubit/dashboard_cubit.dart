import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nano_dash/ui/modules/timer_module.dart';

import '../../../data/repositories/module_repository.dart';
import '../../../data/repositories/settings_repository.dart';
import '../../../data/services/panel_display_controller.dart';
import '../../../domain/models/dashboard.dart';
import '../../../extensions/loggable.dart';
import '../../modules/clock_module.dart';
import '../../modules/weather_module.dart';

part 'dashboard_state.dart';

/// Owns the dashboard configuration: enable/disable, ordering, per-module
/// settings, and the active LCD page.
class DashboardCubit extends Cubit<DashboardState> with Loggable {
  DashboardCubit(this._repository, this._modules, [this._display])
    : super(const DashboardState()) {
    _displaySub = _display?.requests.listen(_onDisplayRequest);
  }

  final SettingsRepository _repository;
  final ModuleRepository _modules;

  /// The bridge the (UI-free) agent uses to ask for a page. Null in contexts
  /// without an agent (e.g. tests that don't exercise it).
  final PanelDisplayController? _display;

  StreamSubscription<PanelShowRequest>? _displaySub;

  /// Auto-return countdown for a transient (assistant-shown) page.
  Timer? _tempTimer;

  /// How long an assistant-shown transient page lingers before returning to the
  /// page that was showing before it.
  static const Duration _kTempTimeout = Duration(seconds: 10);

  @override
  String get logIdentifier => '[DashboardCubit]';

  /// Load persisted config and reconcile it against the module catalogue: keep
  /// the stored order, drop modules that no longer exist, and append any
  /// catalogue module missing from storage as [ModuleVisibility.off] with its
  /// default settings.
  void load() {
    final stored = _repository.loadList(
      dashboardConfigKey,
      DashboardItemConfig.fromJson,
    );
    final items = <DashboardItemConfig>[];
    final seen = <String>{};

    for (final config in stored) {
      final module = _modules.byId(config.moduleId);
      if (module == null) continue; // module removed since last run
      items.add(config);
      seen.add(config.moduleId);
    }

    for (final module in _modules.modules) {
      if (seen.contains(module.id)) continue;
      final settingsOnly = module.hasSettings && !module.hasDisplay;
      const defaultOn = {ClockModule.kId, WeatherModule.kId, TimerModule.kId};
      final on = defaultOn.contains(module.id) || settingsOnly;
      items.add(
        DashboardItemConfig(
          moduleId: module.id,
          visibility: on ? ModuleVisibility.carousel : ModuleVisibility.off,
          settings: module.defaultSettings,
        ),
      );
    }

    final pinned = [
      for (final i in items)
        if (_modules.isSettingsOnly(i)) i,
    ];
    final rest = [
      for (final i in items)
        if (!_modules.isSettingsOnly(i)) i,
    ];
    final ordered = [...pinned, ...rest];

    logInfo('loaded ${ordered.length} module(s)');
    _syncDisplayable(ordered);
    emit(DashboardState(items: ordered, currentPage: 0));
  }

  /// Set a module's visibility (off / assistant-only / carousel).
  void setVisibility(String moduleId, ModuleVisibility visibility) {
    final items = [
      for (final item in state.items)
        if (item.moduleId == moduleId)
          item.copyWith(visibility: visibility)
        else
          item,
    ];
    _commit(items);
  }

  /// Reorder the display order. Both indices are relative to the reorderable
  /// items: settings-only modules stay pinned at the front of [state.items] and
  /// are skipped over here. [newIndex] is the final target index (already
  /// adjusted for the removal — `onReorderItem` semantics).
  void reorder(int oldIndex, int newIndex) {
    final pinned = state.items.where(_modules.isSettingsOnly).length;
    final items = [...state.items];
    final moved = items.removeAt(oldIndex + pinned);
    items.insert(newIndex + pinned, moved);
    _commit(items);
  }

  /// Replace a module's settings.
  void updateSettings(String moduleId, ModuleSettings settings) {
    final items = [
      for (final item in state.items)
        if (item.moduleId == moduleId)
          item.copyWith(settings: settings)
        else
          item,
    ];
    _commit(items);
  }

  /// Route a controller request: a `sticky` one (an explicit action like
  /// starting a timer) lands on the module's carousel page and stays; a plain
  /// one is shown transiently. Sticky falls back to a transient page when the
  /// module has no carousel slot to stay on (assistant-only), and [goToModule]
  /// no-ops when the page is already current — so asking about the timer while
  /// already on the timer page doesn't churn the display.
  void _onDisplayRequest(PanelShowRequest request) {
    if (request.sticky && goToModule(request.moduleId)) return;
    showModule(request.moduleId);
  }

  /// The assistant asks for [moduleId] to be shown. Off/unknown/page-less
  /// modules are ignored; anything else is brought up as a transient page over
  /// the carousel that returns to where the user was after a swipe or a short
  /// idle. Carousel modules are shown transiently too (rather than jumped to and
  /// left) so an agent-shown page never strands the user on it.
  void showModule(String moduleId) {
    final module = _modules.byId(moduleId);
    if (module == null || !module.hasDisplay) return;
    final item = _itemFor(moduleId);
    if (item == null || !item.assistantVisible) {
      logDebug('showModule ignored: "$moduleId" is not displayable');
      return;
    }
    // Already on screen (as the current carousel page, or the current transient
    // page): showing it again would just slide the same content out and back —
    // e.g. an agent that both starts a timer and calls show_on_screen for it.
    if (_isDisplaying(moduleId)) {
      logDebug('showModule: "$moduleId" already on screen; no-op');
      return;
    }
    logInfo('showModule: "$moduleId" as transient page');
    final returnPage = state.showingTemp
        ? (state.tempReturnPage ?? 0)
        : state.currentPage;
    _startTempTimer();
    emit(state.withTemp(moduleId, returnPage));
  }

  /// Whether [moduleId] is the page currently on the LCD: the transient page if
  /// one is up, otherwise the active carousel page.
  bool _isDisplaying(String moduleId) {
    if (state.showingTemp) return state.tempModuleId == moduleId;
    final pages = _modules.pages(state.items);
    if (pages.isEmpty) return false;
    final cur = state.currentPage.clamp(0, pages.length - 1);
    return pages[cur].moduleId == moduleId;
  }

  /// Dismiss the transient page, returning to the carousel page that was
  /// showing before it. [forward] sets the LCD slide direction.
  void dismissTemp({required bool forward}) {
    if (!state.showingTemp) return;
    _cancelTempTimer();
    final pageCount = _modules.pages(state.items).length;
    final target = pageCount == 0
        ? 0
        : (state.tempReturnPage ?? 0).clamp(0, pageCount - 1);
    emit(state.copyWith(currentPage: target, forward: forward));
  }

  /// Jump the carousel straight to [moduleId]'s page and stay there, if it's an
  /// enabled, displayable page. Returns whether [moduleId] is such a page: true
  /// even when already there (a no-op — the caller's intent is satisfied),
  /// false when the module has no carousel page (off or assistant-only), so a
  /// sticky request can fall back to a transient show.
  bool goToModule(String moduleId) {
    final pages = _modules.pages(state.items);
    final index = pages.indexWhere((p) => p.moduleId == moduleId);
    if (index < 0) return false;
    if (index == state.currentPage && !state.showingTemp) return true;
    // A pending transient auto-return would otherwise fire over the page we're
    // landing on; drop it so this page stays put.
    _cancelTempTimer();
    emit(
      state.copyWith(currentPage: index, forward: index >= state.currentPage),
    );
    return true;
  }

  /// Advance to the next enabled page (wrapping). The LCD slides content left.
  /// While a transient page is up, a swipe dismisses it instead of stepping.
  void nextPage() {
    if (state.showingTemp) return dismissTemp(forward: true);
    _step(1);
  }

  /// Go back to the previous enabled page (wrapping). The LCD slides content
  /// right. While a transient page is up, a swipe dismisses it instead.
  void prevPage() {
    if (state.showingTemp) return dismissTemp(forward: false);
    _step(-1);
  }

  /// Step the active page by [delta] (±1) with wraparound, recording the travel
  /// direction in [DashboardState.forward] so the LCD slide matches it.
  void _step(int delta) {
    final count = _modules.pages(state.items).length;
    if (count < 2) return;
    final next = (state.currentPage + delta + count) % count;
    emit(state.copyWith(currentPage: next, forward: delta > 0));
  }

  /// Apply a new item list, clamp the page, persist.
  void _commit(List<DashboardItemConfig> items) {
    _syncDisplayable(items);
    final pageCount = _modules.pages(items).length;
    final page = pageCount == 0 ? 0 : state.currentPage.clamp(0, pageCount - 1);
    _cancelTempTimer();
    emit(DashboardState(items: items, currentPage: page));
    _repository.saveList(dashboardConfigKey, items).catchError((
      Object e,
      StackTrace s,
    ) {
      logError('failed to persist dashboard config', error: e, stackTrace: s);
    });
  }

  /// Publish the ids the assistant may currently show (displayable modules that
  /// aren't off) to the shared controller.
  void _syncDisplayable(List<DashboardItemConfig> items) {
    final display = _display;
    if (display == null) return;
    display.displayable = {
      for (final item in items)
        if (item.assistantVisible &&
            (_modules.byId(item.moduleId)?.hasDisplay ?? false))
          item.moduleId,
    };
  }

  DashboardItemConfig? _itemFor(String moduleId) {
    for (final item in state.items) {
      if (item.moduleId == moduleId) return item;
    }
    return null;
  }

  void _startTempTimer() {
    _tempTimer?.cancel();
    _tempTimer = Timer(_kTempTimeout, () {
      _tempTimer = null;
      dismissTemp(forward: false);
    });
  }

  void _cancelTempTimer() {
    _tempTimer?.cancel();
    _tempTimer = null;
  }

  @override
  Future<void> close() {
    _cancelTempTimer();
    _displaySub?.cancel();
    return super.close();
  }
}
