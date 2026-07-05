import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_dash/data/services/pico_view_service.dart';
import 'package:nano_dash/l10n/app_localizations.dart';
import 'package:nano_dash/ui/settings/views/firmware_update_tile.dart';
import 'package:pico_view/pico_view.dart';

/// A [PicoViewService] whose link/open state is driven by the test. The
/// underlying controller is never touched (no native calls), so overriding the
/// getters the tile reads is enough.
class _FakePicoViewService extends PicoViewService {
  final _link = StreamController<PicoLinkState>.broadcast();
  bool deviceOpen = false;

  @override
  bool get isOpen => deviceOpen;

  @override
  Stream<PicoLinkState> get linkStates => _link.stream;

  void emit(PicoLinkState state) {
    deviceOpen = state == PicoLinkState.connected;
    _link.add(state);
  }

  @override
  void dispose() {
    _link.close();
  }
}

Widget _host(PicoViewService service) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: FirmwareUpdateTile(service: service)),
  );
}

void main() {
  testWidgets('is disabled with a hint while no device is open', (tester) async {
    final service = _FakePicoViewService();
    addTearDown(service.dispose);

    await tester.pumpWidget(_host(service));

    expect(find.text('Connect the panel to update'), findsOneWidget);
    expect(tester.widget<ListTile>(find.byType(ListTile)).enabled, isFalse);
  });

  testWidgets('enables itself when the device connects', (tester) async {
    final service = _FakePicoViewService();
    addTearDown(service.dispose);

    await tester.pumpWidget(_host(service));
    expect(tester.widget<ListTile>(find.byType(ListTile)).enabled, isFalse);

    service.emit(PicoLinkState.connected);
    await tester.pump();

    expect(find.text('Flash a .bin to the panel over USB'), findsOneWidget);
    expect(tester.widget<ListTile>(find.byType(ListTile)).enabled, isTrue);
  });

  testWidgets('disables again when the device disconnects', (tester) async {
    final service = _FakePicoViewService()..deviceOpen = true;
    addTearDown(service.dispose);

    await tester.pumpWidget(_host(service));
    expect(tester.widget<ListTile>(find.byType(ListTile)).enabled, isTrue);

    service.emit(PicoLinkState.disconnected);
    await tester.pump();

    expect(tester.widget<ListTile>(find.byType(ListTile)).enabled, isFalse);
  });
}
