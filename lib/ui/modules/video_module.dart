import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/services/ffmpeg_locator.dart';
import '../../data/services/pico_view_service.dart';
import '../../domain/models/dashboard.dart';
import '../../domain/models/module.dart';
import '../../l10n/app_localizations.dart';
import '../video/cubit/video_cubit.dart';
import '../video/views/video_view.dart';

/// The Video page: plays a local video file straight to the panel (LCD-only).
class VideoModule extends Module {
  const VideoModule();

  static const String kId = 'video';

  /// Path (or bare command name) of the `ffmpeg` used to decode. Empty means
  /// auto-detect from `PATH`.
  static const String _kFfmpegPath = 'ffmpegPath';

  @override
  String get id => kId;

  @override
  IconData get icon => Icons.movie;

  @override
  String title(AppLocalizations l10n) => l10n.moduleVideoTitle;

  @override
  bool get hasSettings => true;

  @override
  ModuleSettings get defaultSettings => const {_kFfmpegPath: ''};

  @override
  Widget build(BuildContext context, ModuleSettings settings) => BlocProvider(
    create: (context) => VideoCubit(
      context.read<PicoViewService>(),
      ffmpegPath: settings[_kFfmpegPath] as String? ?? '',
    ),
    child: const VideoView(),
  );

  @override
  Widget buildSettings(
    BuildContext context,
    ModuleSettings settings,
    ValueChanged<ModuleSettings> onChanged,
  ) {
    final l10n = AppLocalizations.of(context);
    final path = settings[_kFfmpegPath] as String? ?? '';
    final subtitle = path.isEmpty
        ? (FfmpegLocator.autoDetect() ?? l10n.settingsFfmpegNotFound)
        : l10n.settingsFfmpegHint;
    return ListTile(
      leading: const Icon(Icons.movie_filter_outlined),
      title: Text(
        path.isEmpty ? l10n.settingsFfmpegAuto : path,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: path.isEmpty
          ? null
          : IconButton(
              icon: const Icon(Icons.clear),
              tooltip: l10n.clear,
              onPressed: () => onChanged({...settings, _kFfmpegPath: ''}),
            ),
      onTap: () async {
        final file = await openFile();
        if (file == null) return;
        onChanged({...settings, _kFfmpegPath: file.path});
      },
    );
  }
}
