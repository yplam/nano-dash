/// [Live2dController]: owns one native renderer handle. Behind the handle a
/// background worker thread holds the offscreen GL context + model, advances the
/// animation on its own clock, and renders at a fixed cadence.
///
/// The renderer is reached over `dart:ffi`, which has no web implementation, so
/// on the web this resolves to a no-op stub (see [live2d_controller_stub.dart]).
library;

export 'live2d_controller_stub.dart'
    if (dart.library.io) 'live2d_controller_io.dart';
