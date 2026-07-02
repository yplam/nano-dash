import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

/// Settings for the Live2D module: pick the folder holding the model's
/// `*.model3.json`.
class Live2dSettingsView extends StatelessWidget {
  const Live2dSettingsView({
    super.key,
    required this.modelDir,
    required this.onChanged,
  });

  /// Currently selected model directory, or empty if none.
  final String modelDir;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          leading: const Icon(Icons.folder_open),
          title: Text(l10n.live2dChooseModel),
          subtitle: Text(
            modelDir.isEmpty ? l10n.live2dNoModel : modelDir,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: modelDir.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.clear),
                  tooltip: l10n.live2dClear,
                  onPressed: () => onChanged(''),
                ),
          onTap: () async {
            final dir = await getDirectoryPath();
            if (dir != null) onChanged(dir);
          },
        ),
      ],
    );
  }
}
