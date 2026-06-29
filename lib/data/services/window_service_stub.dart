/// Web [WindowService]: a no-op stub.
library;

import 'package:flutter/widgets.dart';

class WindowService {
  const WindowService._();

  static Future<void> ensureInitialized() async {}

  static Future<void> setupAndShow({
    required Size size,
    required Size minimumSize,
    required String title,
  }) async {}

  static Future<Size> getSize() async => Size.zero;

  static Future<void> setSize(Size size) async {}
}
