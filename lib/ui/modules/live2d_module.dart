import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../domain/models/dashboard.dart';
import '../../domain/models/module.dart';
import '../../l10n/app_localizations.dart';
import '../live2d/views/live2d_settings_view.dart';
import '../live2d/views/live2d_view.dart';

/// A Live2D Cubism avatar rendered by the native [Live2dCubit] engine and shown
/// on the LCD. Desktop-only.
class Live2DModule extends Module {
  const Live2DModule();

  static const String kId = 'live2d';

  static const String _kModelDir = 'modelDir';
  static const String _kBackground = 'background';

  @override
  String get id => kId;

  @override
  IconData get icon => Icons.face_retouching_natural;

  @override
  String title(AppLocalizations l10n) => l10n.moduleLive2dTitle;

  @override
  bool get hasDisplay => !kIsWeb;

  @override
  bool get hasSettings => true;

  @override
  ModuleSettings get defaultSettings => const {
    _kModelDir: '',
    _kBackground: '',
  };

  static String modelDirOf(ModuleSettings settings) =>
      settings[_kModelDir] as String? ?? '';

  static String _backgroundOf(ModuleSettings settings) =>
      settings[_kBackground] as String? ?? '';

  @override
  Widget build(BuildContext context, ModuleSettings settings) {
    if (kIsWeb) return const SizedBox.shrink();
    return Live2dView(
      modelDir: modelDirOf(settings),
      backgroundPath: _backgroundOf(settings),
    );
  }

  @override
  Widget buildSettings(
    BuildContext context,
    ModuleSettings settings,
    ValueChanged<ModuleSettings> onChanged,
  ) {
    return Live2dSettingsView(
      modelDir: modelDirOf(settings),
      backgroundPath: _backgroundOf(settings),
      onModelDirChanged: (dir) => onChanged({...settings, _kModelDir: dir}),
      onBackgroundChanged: (bg) => onChanged({...settings, _kBackground: bg}),
    );
  }
}
