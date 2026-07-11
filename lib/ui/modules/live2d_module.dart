import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/models/dashboard.dart';
import '../../domain/models/module.dart';
import '../../l10n/app_localizations.dart';
import '../live2d/cubit/live2d_cubit.dart';
import '../live2d/views/live2d_settings_view.dart';
import '../live2d/views/live2d_view.dart';

/// A Live2D Cubism avatar rendered by the native [Live2dCubit] engine and shown
/// on the LCD. Desktop-only.
class Live2DModule extends Module {
  const Live2DModule();

  static const String kId = 'live2d';

  static const String _kModelDir = 'modelDir';
  static const String _kBackground = 'background';
  static const String _kBaseZoom = 'baseZoom';
  static const String _kBaseOffY = 'baseOffY';

  /// Zoom bounds for the base framing: 1 = the native default full-model fit,
  /// [kMaxZoom] pulls in tight on the face/upper body.
  static const double kMinZoom = 1.0;
  static const double kMaxZoom = 2.5;

  /// Vertical-offset bounds (native normalized units; +y raises the model so
  /// the head/upper body fills a zoomed frame).
  static const double kMinOffY = -0.5;
  static const double kMaxOffY = 0.5;

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
    _kBaseZoom: kMinZoom,
    _kBaseOffY: 0.0,
  };

  static String modelDirOf(ModuleSettings settings) =>
      settings[_kModelDir] as String? ?? '';

  static String _backgroundOf(ModuleSettings settings) =>
      settings[_kBackground] as String? ?? '';

  /// Base zoom for the model framing, clamped to [[kMinZoom], [kMaxZoom]].
  static double baseZoomOf(ModuleSettings settings) =>
      ((settings[_kBaseZoom] as num?)?.toDouble() ?? kMinZoom).clamp(
        kMinZoom,
        kMaxZoom,
      );

  /// Base vertical offset for the framing, clamped to [[kMinOffY], [kMaxOffY]].
  static double baseOffYOf(ModuleSettings settings) =>
      ((settings[_kBaseOffY] as num?)?.toDouble() ?? 0.0).clamp(
        kMinOffY,
        kMaxOffY,
      );

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
      baseZoom: baseZoomOf(settings),
      baseOffY: baseOffYOf(settings),
      onModelDirChanged: (dir) => onChanged({...settings, _kModelDir: dir}),
      onBackgroundChanged: (bg) => onChanged({...settings, _kBackground: bg}),
      onBaseFramingChanged: (zoom, offY) {
        onChanged({...settings, _kBaseZoom: zoom, _kBaseOffY: offY});
        if (!kIsWeb) {
          context.read<Live2dCubit>().previewBaseFraming(zoom, offY);
        }
      },
    );
  }
}
