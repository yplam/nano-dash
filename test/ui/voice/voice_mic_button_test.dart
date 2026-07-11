import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';
import 'package:nano_dash/data/repositories/settings_repository.dart';
import 'package:nano_dash/data/repositories/voice_repository.dart';
import 'package:nano_dash/data/services/voice_service.dart';
import 'package:nano_dash/domain/models/voice.dart';
import 'package:nano_dash/l10n/app_localizations.dart';
import 'package:nano_dash/ui/voice/voice.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lets the test drive the button through states the real engine would produce.
class _FakeVoiceCubit extends VoiceCubit {
  _FakeVoiceCubit(super.repository);

  void put(VoiceState state) => emit(state);
}

void main() {
  late _FakeVoiceCubit cubit;

  /// The button only renders once a models folder is set; every state the
  /// rendering tests emit therefore carries one.
  const settings = VoiceSettings(modelsDir: '/models');

  setUp(() async {
    if (!GetIt.instance.isRegistered<Logger>()) {
      GetIt.instance.registerSingleton<Logger>(Logger());
    }
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    cubit = _FakeVoiceCubit(
      VoiceRepository(SettingsRepository(prefs), VoiceService()),
    );
  });

  tearDown(() => cubit.close());

  Widget harness(double diameter) => MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: 360,
          height: 360,
          child: BlocProvider<VoiceCubit>.value(
            value: cubit,
            child: Center(child: VoiceMicButton(diameter: diameter)),
          ),
        ),
      ),
    ),
  );

  /// Emit [state] and let it land: the cubit's stream delivers on a microtask,
  /// so a single pump can build the frame before the rebuild is scheduled.
  Future<void> put(WidgetTester tester, VoiceState state) async {
    cubit.put(state);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
  }

  testWidgets('renders every status in a 360px panel box', (tester) async {
    await tester.pumpWidget(harness(72));

    for (final status in VoiceStatus.values) {
      await put(
        tester,
        VoiceState(
          settings: settings,
          status: status,
          error: status == VoiceStatus.error ? 'boom' : null,
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.takeException(), isNull, reason: 'status $status');
      // The layout box never grows, whether or not the halo is pulsing.
      expect(tester.getSize(find.byType(VoiceMicButton)), const Size(72, 72));
    }
  });

  testWidgets('speaking overrides an open status, and stays inside its box', (
    tester,
  ) async {
    await tester.pumpWidget(harness(72));
    await put(
      tester,
      const VoiceState(
        settings: settings,
        status: VoiceStatus.idle,
        speaking: true,
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byIcon(Icons.graphic_eq), findsOneWidget);
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(VoiceMicButton)), const Size(72, 72));

    // Closing the engine must stop the halo, or it animates forever.
    await put(tester, const VoiceState(settings: settings));
    expect(find.byIcon(Icons.mic_off_outlined), findsOneWidget);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('long-press only wakes a sleeping engine', (tester) async {
    await tester.pumpWidget(harness(72));

    await put(
      tester,
      const VoiceState(settings: settings, status: VoiceStatus.idle),
    );
    expect(tester.widget<InkWell>(find.byType(InkWell)).onLongPress, isNotNull);

    await put(
      tester,
      const VoiceState(settings: settings, status: VoiceStatus.off),
    );
    expect(tester.widget<InkWell>(find.byType(InkWell)).onLongPress, isNull);
  });

  testWidgets('mounting over an already-listening engine starts the halo', (
    tester,
  ) async {
    cubit.put(
      const VoiceState(settings: settings, status: VoiceStatus.listening),
    );
    await tester.pumpWidget(harness(72));
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);

    // The halo is only started from didChangeDependencies on a fresh mount; if
    // the tree settles, that path silently stopped working.
    expect(tester.hasRunningAnimations, isTrue);
  });

  testWidgets('renders nothing until a models folder is set', (tester) async {
    await tester.pumpWidget(harness(72));
    await put(tester, const VoiceState(settings: VoiceSettings()));

    // The engine cannot open without models, so no tappable button is offered.
    expect(find.byType(InkWell), findsNothing);
    expect(tester.getSize(find.byType(VoiceMicButton)), Size.zero);

    await put(tester, const VoiceState(settings: settings));
    expect(find.byType(InkWell), findsOneWidget);
  });
}
