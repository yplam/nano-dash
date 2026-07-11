/// Web [Live2dController]: a no-op stub. The renderer is native-only (offscreen
/// GL + a worker thread reached over `dart:ffi`), neither of which exists on the
/// web, so construction throws [Live2dException] — callers that guard creation
/// (see `Live2dCubit._ensureController`) degrade to "unavailable" instead of
/// crashing.
///
/// Selected on the web by [live2d_controller.dart]; native builds get
/// [live2d_controller_io.dart].
library;

import 'dart:typed_data';

import 'live2d_types.dart';

export 'live2d_types.dart';

class Live2dController {
  static Future<Live2dController> create({
    required int width,
    required int height,
    String? shaderDir,
  }) {
    throw Live2dException('Live2D is not supported on the web');
  }

  int get width => 0;
  int get height => 0;

  /// Bytes per frame (`width * height * 4`).
  int get frameBytes => 0;

  Future<bool> load(String dir, String model3Json) async => false;

  void setActive(bool active) {}

  void setDrag(double nx, double ny) {}

  void setView(double scale, double offX, double offY) {}

  void tap(double nx, double ny) {}

  int motionCount([String group = '']) => 0;

  void startMotion({
    String group = '',
    int index = -1,
    Live2dMotionPriority priority = Live2dMotionPriority.normal,
  }) {}

  void setLipSyncValue(double value) {}

  int get expressionCount => 0;

  String? expressionName(int index) => null;

  List<String> get expressionNames => const [];

  void setExpression(String? name) {}

  void setParameter(
    String id,
    double value, {
    double weight = 1.0,
    bool add = false,
  }) {}

  void clearParameter([String? id]) {}

  double getParameter(String id) => 0;

  Uint8List? acquireFrame() => null;

  void releaseFrame() {}

  void dispose() {}
}
