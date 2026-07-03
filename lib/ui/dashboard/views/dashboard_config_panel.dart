import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nano_dash/l10n/app_localizations.dart';

import '../../../data/repositories/module_repository.dart';
import '../../../domain/models/dashboard.dart';
import '../../../domain/models/module.dart';
import '../cubit/dashboard_cubit.dart';

/// The configuration list under the LCD preview.
class DashboardConfigPanel extends StatelessWidget {
  const DashboardConfigPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final modules = context.read<ModuleRepository>();

    return BlocBuilder<DashboardCubit, DashboardState>(
      buildWhen: (prev, curr) => prev.items != curr.items,
      builder: (context, state) {
        // Settings-only modules are pinned at the front of state.items.
        final pinned = [
          for (final item in state.items)
            if (modules.isSettingsOnly(item)) item,
        ];
        final rest = [
          for (final item in state.items)
            if (!modules.isSettingsOnly(item)) item,
        ];

        return Column(
          children: [
            for (final item in pinned)
              if (modules.byId(item.moduleId) case final module?)
                _PinnedTile(
                  key: ValueKey(item.moduleId),
                  module: module,
                  item: item,
                ),
            if (pinned.isNotEmpty) const Divider(height: 1),
            Expanded(
              child: ReorderableListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                buildDefaultDragHandles: false,
                itemCount: rest.length,
                onReorderItem: (oldIndex, newIndex) =>
                    context.read<DashboardCubit>().reorder(
                      oldIndex + pinned.length,
                      newIndex + pinned.length,
                    ),
                itemBuilder: (context, index) {
                  final DashboardItemConfig item = rest[index];
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
              ),
            ),
          ],
        );
      },
    );
  }
}

/// A pinned, always-available tile for a settings-only module.
class _PinnedTile extends StatelessWidget {
  const _PinnedTile({super.key, required this.module, required this.item});

  final Module module;
  final DashboardItemConfig item;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DashboardCubit>();
    final l10n = AppLocalizations.of(context);
    return ListTile(
      leading: Icon(module.icon),
      title: Text(module.title(l10n)),
      trailing: const Icon(Icons.tune),
      onTap: () => _openModuleSettings(context, cubit, module, item),
    );
  }
}

/// Opens a module's settings in a modal bottom sheet, rebuilding its body from
/// live cubit state so edits reflect immediately.
Future<void> _openModuleSettings(
  BuildContext context,
  DashboardCubit cubit,
  Module module,
  DashboardItemConfig item,
) {
  final l10n = AppLocalizations.of(context);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) {
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

class _ModuleTile extends StatelessWidget {
  const _ModuleTile({
    super.key,
    required this.index,
    required this.module,
    required this.item,
  });

  final int index;
  final Module module;
  final DashboardItemConfig item;

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
                  ? () => _openModuleSettings(context, cubit, module, item)
                  : null,
            ),
          Switch(
            value: item.enabled,
            onChanged: (_) => cubit.toggle(item.moduleId),
          ),
          // Config-only modules (no LCD page) take no place in the page order,
          // so they get no drag handle.
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
}
