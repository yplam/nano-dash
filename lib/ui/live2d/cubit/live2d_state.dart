part of 'live2d_cubit.dart';

/// Why a model load failed, mapped to a localized message in the view.
enum Live2dErrorKind { noModelJson, loadFailed }

/// State of the app-wide Live2D renderer.
sealed class Live2dState {
  const Live2dState();
}

/// No model selected yet.
class Live2dIdle extends Live2dState {
  const Live2dIdle();
}

/// A model in [dir] is being loaded by the worker.
class Live2dLoading extends Live2dState {
  const Live2dLoading(this.dir);
  final String dir;
}

/// The model in [dir] is loaded and the renderer is producing frames.
class Live2dReady extends Live2dState {
  const Live2dReady(this.dir);
  final String dir;
}

/// The selected model couldn't be loaded.
class Live2dError extends Live2dState {
  const Live2dError(this.kind);
  final Live2dErrorKind kind;
}

/// The native renderer can't run here (no usable GL context). Latched.
class Live2dUnavailable extends Live2dState {
  const Live2dUnavailable();
}
