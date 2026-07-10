import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nano_live2d/nano_live2d.dart';

import '../../../data/repositories/settings_repository.dart';
import '../../../domain/models/dashboard.dart';
import '../../../extensions/loggable.dart';
import '../../modules/live2d_module.dart';

part 'live2d_state.dart';

/// Owns the single native Live2D renderer for the whole app.
///
/// The renderer holds a GL context + worker thread that are expensive to spawn
/// and join, so it must outlive the module widget — the LCD carousel disposes
/// the on-screen subtree on every page swipe (see `lcd-page-disposes-module-state`).
/// This cubit lives at app scope; the [Live2dView] only polls [controller] for
/// frames and forwards touch.
///
/// The handle is created lazily on the first [loadModel] and reused across model
/// switches; if the GL context can't be created (headless box, no driver) the
/// cubit latches [Live2dUnavailable] instead of crashing.
class Live2dCubit extends Cubit<Live2dState> with Loggable {
  Live2dCubit(this._settings) : super(const Live2dIdle());

  final SettingsRepository _settings;

  /// Panel-native render size for the worker (matches the round 360px LCD).
  static const int _kRenderSize = 360;

  @override
  String get logIdentifier => '[Live2dCubit]';

  Live2dController? _controller;
  String? _loadedDir;
  bool _creationFailed = false;

  /// Whether the renderer should be actively rendering.
  bool _active = true;

  /// The live renderer once a model is loaded; null otherwise (idle/loading/
  /// error/unavailable). Used by [Live2dView] to acquire frames and send touch.
  Live2dController? get controller => state is Live2dReady ? _controller : null;

  /// Load the model in [dir] (a directory holding a `*.model3.json`). No-op when
  /// that directory is already the loaded one. Creates the native renderer on
  /// first use.
  Future<void> loadModel(String dir) async {
    if (dir.isEmpty) {
      _loadedDir = null;
      emit(const Live2dIdle());
      return;
    }
    if (_creationFailed) {
      emit(const Live2dUnavailable());
      return;
    }
    if (dir == _loadedDir && state is Live2dReady) return;

    emit(Live2dLoading(dir));

    final model3 = await _findModel3Json(dir);
    if (model3 == null) {
      _loadedDir = null;
      logWarning('no *.model3.json in $dir');
      emit(const Live2dError(Live2dErrorKind.noModelJson));
      return;
    }

    final controller = await _ensureController();
    if (controller == null) {
      emit(const Live2dUnavailable());
      return;
    }

    // nl_load expects a trailing separator on the directory.
    final loadDir = dir.endsWith('/') || dir.endsWith(Platform.pathSeparator)
        ? dir
        : '$dir${Platform.pathSeparator}';
    final ok = await controller.load(loadDir, model3);
    if (!ok) {
      _loadedDir = null;
      logWarning('nl_load failed for $loadDir$model3');
      emit(const Live2dError(Live2dErrorKind.loadFailed));
      return;
    }
    _loadedDir = dir;
    logInfo('loaded $model3 from $dir');
    emit(Live2dReady(dir));
  }

  Future<void> preload({Duration delay = const Duration(seconds: 2)}) async {
    final dir = _configuredModelDir();
    if (dir.isEmpty) return;
    _setActive(false);
    await Future.delayed(delay);
    if (isClosed) return;
    logInfo('preloading model from $dir');
    await loadModel(dir);
  }

  /// The model directory persisted for the Live2D module, or '' when the module
  /// is missing/disabled or no directory has been chosen.
  String _configuredModelDir() {
    final items = _settings.loadList(
      dashboardConfigKey,
      DashboardItemConfig.fromJson,
    );
    for (final item in items) {
      if (item.moduleId != Live2DModule.kId) continue;
      return item.enabled ? Live2DModule.modelDirOf(item.settings) : '';
    }
    return '';
  }

  /// Resume rendering — call when the model becomes visible again.
  void resume() => _setActive(true);

  /// Pause rendering to save CPU/GPU while the model is off-screen.
  void pause() => _setActive(false);

  void _setActive(bool active) {
    if (_active == active) return;
    _active = active;
    _controller?.setActive(active);
  }

  /// Create the native renderer once, latching [_creationFailed] on error so a
  /// box without a usable GL context degrades to [Live2dUnavailable].
  Future<Live2dController?> _ensureController() async {
    final existing = _controller;
    if (existing != null) return existing;
    try {
      final controller = await Live2dController.create(
        width: _kRenderSize,
        height: _kRenderSize,
      );
      // A fresh renderer starts active; honor a pause requested before now.
      if (!_active) controller.setActive(false);
      return _controller = controller;
    } catch (e, s) {
      _creationFailed = true;
      logError('Live2dController create failed', error: e, stackTrace: s);
      return null;
    }
  }

  /// The first filename ending in `.model3.json` directly inside [dir].
  Future<String?> _findModel3Json(String dir) async {
    try {
      final d = Directory(dir);
      if (!d.existsSync()) return null;
      await for (final entry in d.list(followLinks: false)) {
        if (entry is! File) continue;
        final name = entry.uri.pathSegments.last;
        if (name.toLowerCase().endsWith('.model3.json')) return name;
      }
    } catch (e, s) {
      logWarning('scanning $dir failed', error: e, stackTrace: s);
    }
    return null;
  }

  @override
  Future<void> close() {
    _controller?.dispose();
    _controller = null;
    return super.close();
  }
}
