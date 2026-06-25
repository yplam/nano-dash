import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nano_dash/l10n/app_localizations.dart';

import '../../../data/repositories/module_repository.dart';
import '../../../domain/models/dash_item_config.dart';
import '../../../domain/models/dash_module.dart';
import '../cubit/dashboard_cubit.dart';

/// The configuration list under the LCD preview: every available widget with an
/// enable switch, a drag handle for display order, and an optional settings
/// button.
class DashboardConfigPanel extends StatelessWidget {
  const DashboardConfigPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final modules = context.read<ModuleRepository>();

    return BlocBuilder<DashboardCubit, DashboardState>(
      buildWhen: (prev, curr) => prev.items != curr.items,
      builder: (context, state) {
        return ReorderableListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          buildDefaultDragHandles: false,
          itemCount: state.items.length,
          onReorderItem: (oldIndex, newIndex) =>
              context.read<DashboardCubit>().reorder(oldIndex, newIndex),
          itemBuilder: (context, index) {
            final DashItemConfig item = state.items[index];
            final module = modules.byId(item.moduleId);
            if (module == null) {
              return SizedBox.shrink(key: ValueKey('missing-$index'));
            }
            return _ModuleTile(
              key: ValueKey(item.moduleId),
              index: index,
              module: module,
              item: item,
            );
          },
        );
      },
    );
  }
}

class _ModuleTile extends StatelessWidget {
  const _ModuleTile({
    super.key,
    required this.index,
    required this.module,
    required this.item,
  });

  final int index;
  final DashModule module;
  final DashItemConfig item;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DashboardCubit>();
    final l10n = AppLocalizations.of(context);
    return ListTile(
      leading: Icon(module.icon),
      title: Text(module.title(l10n)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (module.hasSettings)
            IconButton(
              icon: const Icon(Icons.tune),
              tooltip: l10n.settingsTitle,
              onPressed: item.enabled
                  ? () => _openSettings(context, cubit)
                  : null,
            ),
          Switch(
            value: item.enabled,
            onChanged: (_) => cubit.toggle(item.moduleId),
          ),
          // Config-only modules (no LCD page) take no place in the page order,
          // so they get no drag handle. A fixed-width spacer keeps the switches
          // aligned with the draggable rows.
          if (module.hasDisplay)
            ReorderableDragStartListener(
              index: index,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.drag_handle),
              ),
            )
          else
            const SizedBox(width: 40),
        ],
      ),
    );
  }

  Future<void> _openSettings(BuildContext context, DashboardCubit cubit) {
    final l10n = AppLocalizations.of(context);
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        // Rebuild the sheet body from live state so edits reflect immediately.
        return BlocBuilder<DashboardCubit, DashboardState>(
          bloc: cubit,
          builder: (context, state) {
            final current = state.items.firstWhere(
              (i) => i.moduleId == module.id,
              orElse: () => item,
            );
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: Icon(module.icon),
                      title: Text(module.title(l10n)),
                      trailing: TextButton(
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        child: Text(l10n.settingsDone),
                      ),
                    ),
                    const Divider(height: 1),
                    Flexible(
                      child: SingleChildScrollView(
                        child: module.buildSettings(
                          context,
                          current.settings,
                          (s) => cubit.updateSettings(module.id, s),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
