import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/module_repository.dart';
import '../../../data/repositories/settings_repository.dart';
import '../../../domain/models/dashboard.dart';
import '../../../extensions/loggable.dart';
import '../../modules/clock_module.dart';
import '../../modules/weather_module.dart';

part 'dashboard_state.dart';

/// Owns the dashboard configuration: enable/disable, ordering, per-module
/// settings, and the active LCD page.
class DashboardCubit extends Cubit<DashboardState> with Loggable {
  DashboardCubit(this._repository, this._modules)
    : super(const DashboardState());

  final SettingsRepository _repository;
  final ModuleRepository _modules;

  @override
  String get logIdentifier => '[DashboardCubit]';

  /// Load persisted config and reconcile it against the module catalogue: keep
  /// the stored order, drop modules that no longer exist, and append any
  /// catalogue module missing from storage as disabled with its default
  /// settings.
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
      const defaultOn = {ClockModule.kId, WeatherModule.kId};
      items.add(
        DashboardItemConfig(
          moduleId: module.id,
          enabled: defaultOn.contains(module.id) || settingsOnly,
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
    emit(DashboardState(items: ordered, currentPage: 0));
  }

  /// Toggle a module on/off.
  void toggle(String moduleId) {
    final items = [
      for (final item in state.items)
        if (item.moduleId == moduleId)
          item.copyWith(enabled: !item.enabled)
        else
          item,
    ];
    _commit(items);
  }

  /// Reorder the full list (display order). [newIndex] is the final target
  /// index (already adjusted for the removal — `onReorderItem` semantics).
  void reorder(int oldIndex, int newIndex) {
    final items = [...state.items];
    final moved = items.removeAt(oldIndex);
    items.insert(newIndex, moved);
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

  /// Jump the carousel straight to [moduleId]'s page, if it's an enabled, displayable page.
  void goToModule(String moduleId) {
    final pages = _modules.pages(state.items);
    final index = pages.indexWhere((p) => p.moduleId == moduleId);
    if (index < 0 || index == state.currentPage) return;
    emit(
      state.copyWith(currentPage: index, forward: index > state.currentPage),
    );
  }

  /// Advance to the next enabled page (wrapping). The LCD slides content left.
  void nextPage() => _step(1);

  /// Go back to the previous enabled page (wrapping). The LCD slides content
  /// right.
  void prevPage() => _step(-1);

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
    final pageCount = _modules.pages(items).length;
    final page = pageCount == 0 ? 0 : state.currentPage.clamp(0, pageCount - 1);
    emit(DashboardState(items: items, currentPage: page));
    _repository.saveList(dashboardConfigKey, items).catchError((
      Object e,
      StackTrace s,
    ) {
      logError('failed to persist dashboard config', error: e, stackTrace: s);
    });
  }
}
