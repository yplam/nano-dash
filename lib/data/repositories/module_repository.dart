import '../../domain/models/dash_item_config.dart';
import '../../domain/models/dash_module.dart';

/// The catalogue of available dashboard modules.
class ModuleRepository {
  const ModuleRepository(this.modules);

  /// All modules shipped with the app, in catalogue order.
  final List<DashModule> modules;

  DashModule? byId(String id) {
    for (final m in modules) {
      if (m.id == id) return m;
    }
    return null;
  }

  /// The ordered page list for a configuration: the items that are both
  /// enabled and backed by a displayable module, in display order.
  List<DashItemConfig> pages(List<DashItemConfig> items) => [
    for (final item in items)
      if (item.enabled && (byId(item.moduleId)?.hasDisplay ?? false)) item,
  ];
}
