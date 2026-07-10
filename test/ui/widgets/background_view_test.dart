import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_dash/ui/widgets/background_view.dart';

/// `BackgroundView.precache` only helps if the entry it warms carries the same
/// [ImageCache] key the widget later resolves. Nothing in the type system ties
/// the two together, so assert the background is painted on the first frame —
/// no pump, no settle.
void main() {
  testWidgets('bundled background paints on the first frame', (tester) async {
    await tester.runAsync(() => BackgroundView.precache(''));

    await tester.pumpWidget(const MaterialApp(home: BackgroundView(path: '')));

    final raw = tester.widget<RawImage>(find.byType(RawImage));
    expect(raw.image, isNotNull);
  });

  testWidgets('chosen background file paints on the first frame', (
    tester,
  ) async {
    final file = File(
      '${Directory.systemTemp.createTempSync('nano_dash_bg').path}/bg.png',
    );
    await tester.runAsync(() async {
      final bytes = await rootBundle.load('assets/bg.png');
      file.writeAsBytesSync(bytes.buffer.asUint8List());
      await BackgroundView.precache(file.path);
    });

    await tester.pumpWidget(MaterialApp(home: BackgroundView(path: file.path)));

    final raw = tester.widget<RawImage>(find.byType(RawImage));
    expect(raw.image, isNotNull);
  });
}
