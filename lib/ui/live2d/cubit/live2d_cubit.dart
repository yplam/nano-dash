import 'dart:async';
import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nano_live2d/nano_live2d.dart';

import '../../../data/repositories/agent_repository.dart';
import '../../../data/repositories/settings_repository.dart';
import '../../../data/repositories/voice_repository.dart';
import '../../../domain/models/agent.dart';
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
  Live2dCubit(this._settings, {VoiceRepository? voice, AgentRepository? agent})
    : _voice = voice,
      super(const Live2dIdle()) {
    // The avatar mouths whatever the voice engine is saying, and leans into the
    // frame while it does.
    _speakingSub = voice?.speaking.listen(_onSpeaking);
    _phase = agent?.phase ?? AgentPhase.idle;
    _phaseSub = agent?.phaseChanges.listen(_onPhase);
  }

  final SettingsRepository _settings;
  final VoiceRepository? _voice;

  /// Panel-native render size for the worker (matches the round 360px LCD).
  static const int _kRenderSize = 360;

  /// While the assistant is active the base zoom is multiplied by this and the
  /// vertical offset nudged up by [_kLeanOffYBoost], for a "lean in" toward the
  /// face; the native side eases the transition and back out on its own.
  static const double _kLeanZoomFactor = 1.18;
  static const double _kLeanOffYBoost = 0.05;

  @override
  String get logIdentifier => '[Live2dCubit]';

  Live2dController? _controller;
  String? _loadedDir;
  bool _creationFailed = false;

  StreamSubscription<bool>? _speakingSub;
  StreamSubscription<AgentPhase>? _phaseSub;

  /// The framing the user configured (persisted per model in the module's
  /// settings), applied whenever a model loads and as the settings sliders drag.
  double _baseZoom = Live2DModule.kMinZoom;
  double _baseOffY = 0.0;

  /// Live "lean in" inputs: true while the assistant is talking or working, so
  /// the view pulls in a touch and eases back out when it goes idle.
  bool _speaking = false;
  AgentPhase _phase = AgentPhase.idle;

  /// How often the mouth is sampled from the engine's play-out amplitude while
  /// it speaks. The voice engine exposes the level as a lock-free value, not a
  /// stream, so we poll it; the native `LipSyncProvider` eases between samples,
  /// so this coarse cadence already reads as natural speech.
  static const Duration _kLipSyncPoll = Duration(milliseconds: 50);

  /// Runs only while the engine is speaking: each tick pushes the current
  /// amplitude into the model's mouth. Null when silent.
  Timer? _lipSyncTimer;

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
      _stopLipSync();
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

    final (zoom, offY) = _configuredBaseFraming();
    _baseZoom = zoom;
    _baseOffY = offY;
    _pushView();
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

  /// The persisted base framing `(zoom, offY)` for the Live2D module, or the
  /// defaults when the module is missing.
  (double, double) _configuredBaseFraming() {
    final items = _settings.loadList(
      dashboardConfigKey,
      DashboardItemConfig.fromJson,
    );
    for (final item in items) {
      if (item.moduleId != Live2DModule.kId) continue;
      return (
        Live2DModule.baseZoomOf(item.settings),
        Live2DModule.baseOffYOf(item.settings),
      );
    }
    return (Live2DModule.kMinZoom, 0.0);
  }

  void previewBaseFraming(double zoom, double offY) {
    _baseZoom = zoom;
    _baseOffY = offY;
    _pushView();
  }

  void _onSpeaking(bool speaking) {
    logInfo('speaking=$speaking (from voice engine)');
    _driveLipSync(speaking);
    if (_speaking == speaking) return;
    _speaking = speaking;
    _pushView();
  }

  /// Start or stop mouthing to the engine's play-out amplitude.
  void _driveLipSync(bool speaking) {
    if (speaking) {
      _lipSyncTimer ??= Timer.periodic(_kLipSyncPoll, (_) => _pollLipSync());
    } else {
      _stopLipSync();
      if (_active) _controller?.setLipSyncValue(0);
    }
  }

  void _pollLipSync() {
    final level = _voice?.speakingLevel ?? 0;
    if (_active) _controller?.setLipSyncValue(level);
  }

  void _stopLipSync() {
    _lipSyncTimer?.cancel();
    _lipSyncTimer = null;
  }

  void _onPhase(AgentPhase phase) {
    if (_phase == phase) return;
    _phase = phase;
    _pushView();
  }

  /// The assistant is "active" (→ lean in) while it talks or the agent is doing
  /// anything but idling.
  bool get _leaning => _speaking || _phase != AgentPhase.idle;

  /// Compute the target view from the base framing plus any lean-in and hand it
  /// to the renderer.
  void _pushView() {
    final controller = _controller;
    if (controller == null || _loadedDir == null) return;
    final zoom = _leaning ? _baseZoom * _kLeanZoomFactor : _baseZoom;
    final offY = _leaning ? _baseOffY + _kLeanOffYBoost : _baseOffY;
    controller.setView(zoom, 0, offY);
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
  Future<void> close() async {
    await _speakingSub?.cancel();
    await _phaseSub?.cancel();
    _stopLipSync();
    _controller?.dispose();
    _controller = null;
    return super.close();
  }
}
