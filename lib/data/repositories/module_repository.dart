import '../../domain/models/dashboard.dart';
import '../../domain/models/module.dart';

/// The catalogue of available dashboard modules.
class ModuleRepository {
  const ModuleRepository(this.modules);

  /// All modules shipped with the app, in catalogue order.
  final List<Module> modules;

  Module? byId(String id) {
    for (final m in modules) {
      if (m.id == id) return m;
    }
    return null;
  }

  /// A settings-only module: it exposes settings but renders no LCD page.
  bool isSettingsOnly(DashboardItemConfig item) {
    final module = byId(item.moduleId);
    return module != null && module.hasSettings && !module.hasDisplay;
  }

  /// The ordered page list for a configuration: the items that are both
  /// enabled and backed by a displayable module, in display order.
  List<DashboardItemConfig> pages(List<DashboardItemConfig> items) => [
    for (final item in items)
      if (item.enabled && (byId(item.moduleId)?.hasDisplay ?? false)) item,
  ];
}
