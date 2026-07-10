import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../../../l10n/app_localizations.dart';

/// Settings for the Live2D module: pick the folder holding the model's
/// `*.model3.json`, and an optional background image shown under the model.
class Live2dSettingsView extends StatelessWidget {
  const Live2dSettingsView({
    super.key,
    required this.modelDir,
    required this.backgroundPath,
    required this.onModelDirChanged,
    required this.onBackgroundChanged,
  });

  /// Currently selected model directory, or empty if none.
  final String modelDir;

  /// Absolute path to the chosen background file, or empty to fall back to the
  /// app-wide background.
  final String backgroundPath;

  final ValueChanged<String> onModelDirChanged;
  final ValueChanged<String> onBackgroundChanged;

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
                  onPressed: () => onModelDirChanged(''),
                ),
          onTap: () async {
            final dir = await getDirectoryPath();
            if (dir != null) onModelDirChanged(dir);
          },
        ),
        ListTile(
          leading: const Icon(Icons.image_outlined),
          title: Text(
            backgroundPath.isEmpty
                ? l10n.settingsBackgroundDefault
                : _basename(backgroundPath),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(l10n.settingsBackgroundHint),
          trailing: backgroundPath.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.clear),
                  tooltip: l10n.live2dClear,
                  onPressed: _clearBackground,
                ),
          onTap: _pickBackground,
        ),
      ],
    );
  }

  /// Pick an image and copy it into app storage, so the reference survives the
  /// original being moved or deleted.
  Future<void> _pickBackground() async {
    const group = XTypeGroup(
      label: 'images',
      extensions: <String>['png', 'jpg', 'jpeg', 'webp', 'gif', 'bmp'],
    );
    final file = await openFile(acceptedTypeGroups: const [group]);
    if (file == null) return;

    final support = await getApplicationSupportDirectory();
    final dir = Directory('${support.path}/backgrounds');
    await dir.create(recursive: true);
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final dest = '${dir.path}/live2d_bg_$stamp${_extension(file.name)}';
    await File(file.path).copy(dest);

    final previous = backgroundPath;
    onBackgroundChanged(dest);
    await _deleteQuietly(previous, keep: dest);
  }

  Future<void> _clearBackground() async {
    final previous = backgroundPath;
    onBackgroundChanged('');
    await _deleteQuietly(previous);
  }

  /// Remove a previously copied background, ignoring failures.
  Future<void> _deleteQuietly(String path, {String? keep}) async {
    if (path.isEmpty || path == keep) return;
    try {
      await File(path).delete();
    } catch (_) {
      // Best-effort cleanup; a leftover file is harmless.
    }
  }

  static String _basename(String path) => path.split(RegExp(r'[/\\]')).last;

  static String _extension(String name) {
    final dot = name.lastIndexOf('.');
    return dot < 0 ? '' : name.substring(dot).toLowerCase();
  }
}
