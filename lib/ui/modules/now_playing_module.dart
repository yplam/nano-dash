import 'package:flutter/material.dart';

import '../../domain/models/dashboard.dart';
import '../../domain/models/module.dart';
import '../../l10n/app_localizations.dart';
import '../now_playing/views/now_playing_view.dart';

/// The Now Playing page: mirrors the host's current media session.
class NowPlayingModule extends Module {
  const NowPlayingModule();

  static const String kId = 'now_playing';

  @override
  String get id => kId;

  @override
  IconData get icon => Icons.music_note;

  @override
  String title(AppLocalizations l10n) => l10n.moduleNowPlayingTitle;

  @override
  Widget build(BuildContext context, ModuleSettings settings) =>
      const NowPlayingView();
}
