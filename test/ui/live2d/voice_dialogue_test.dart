import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';
import 'package:nano_dash/data/repositories/agent_repository.dart';
import 'package:nano_dash/data/repositories/settings_repository.dart';
import 'package:nano_dash/data/repositories/voice_repository.dart';
import 'package:nano_dash/data/services/agent_service.dart';
import 'package:nano_dash/data/services/voice_service.dart';
import 'package:nano_dash/domain/models/agent.dart';
import 'package:nano_dash/domain/models/voice.dart';
import 'package:nano_dash/l10n/app_localizations.dart';
import 'package:nano_dash/ui/agent/agent.dart';
import 'package:nano_dash/ui/widgets/dialogue_box.dart';
import 'package:nano_dash/ui/widgets/voice_dialogue.dart';
import 'package:nano_dash/ui/voice/voice.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lets the test drive the dialogue through states the real engine would produce.
class _FakeVoiceCubit extends VoiceCubit {
  _FakeVoiceCubit(super.repository);

  void put(VoiceState state) => emit(state);
}

/// Lets the test drive the assistant's side of the dialogue.
class _FakeAgentCubit extends AgentCubit {
  _FakeAgentCubit(super.repository);

  void put(AgentState state) => emit(state);
}

void main() {
  const dwell = Duration(seconds: 8);
  // Short enough that DialogueBox's auto-scroll finds nothing to scroll and
  // leaves no pending timer behind.
  const line = 'hello';

  late _FakeVoiceCubit cubit;
  late _FakeAgentCubit agentCubit;
  late AgentRepository agentRepository;

  setUp(() async {
    if (!GetIt.instance.isRegistered<Logger>()) {
      GetIt.instance.registerSingleton<Logger>(Logger());
    }
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final settings = SettingsRepository(prefs);
    final voiceRepository = VoiceRepository(settings, VoiceService());
    cubit = _FakeVoiceCubit(voiceRepository);
    agentRepository = AgentRepository(
      settings,
      voiceRepository,
      AgentService(),
    );
    agentCubit = _FakeAgentCubit(agentRepository);
  });

  tearDown(() async {
    await cubit.close();
    await agentCubit.close();
    await agentRepository.dispose();
  });

  VoiceState listening({VoiceTranscript? transcript}) => VoiceState(
    settings: const VoiceSettings(),
    status: VoiceStatus.listening,
    lastTranscript: transcript,
  );

  Widget harness() => MaterialApp(
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
          child: MultiBlocProvider(
            providers: [
              BlocProvider<VoiceCubit>.value(value: cubit),
              BlocProvider<AgentCubit>.value(value: agentCubit),
            ],
            child: const Align(
              alignment: Alignment.bottomCenter,
              child: VoiceDialogue(side: 360, dwell: dwell),
            ),
          ),
        ),
      ),
    ),
  );

  /// Emit [state] and let it land: the cubit's stream delivers on a microtask,
  /// the listener's `setState` schedules the next frame, and only that frame
  /// starts the switcher's cross-fade — so it takes three pumps to settle.
  Future<void> put(WidgetTester tester, VoiceState state) async {
    cubit.put(state);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('shows a fresh transcript, tagged with the speaker', (
    tester,
  ) async {
    await tester.pumpWidget(harness());
    expect(find.byType(DialogueBox), findsNothing);

    await put(tester, listening(transcript: VoiceTranscript(line)));

    expect(find.byType(DialogueBox), findsOneWidget);
    expect(find.text(line), findsOneWidget);
    expect(find.text('You'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('hides once the dwell elapses', (tester) async {
    await tester.pumpWidget(harness());
    await put(tester, listening(transcript: VoiceTranscript(line)));
    expect(find.byType(DialogueBox), findsOneWidget);

    await tester.pump(dwell);
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(DialogueBox), findsNothing);
  });

  testWidgets('a later utterance restarts the dwell', (tester) async {
    await tester.pumpWidget(harness());
    await put(tester, listening(transcript: VoiceTranscript(line)));

    await tester.pump(const Duration(seconds: 6));
    await put(tester, listening(transcript: VoiceTranscript('again')));

    // Past the first transcript's dwell, but not the second's.
    await tester.pump(const Duration(seconds: 4));
    expect(find.text('again'), findsOneWidget);

    await tester.pump(dwell);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(DialogueBox), findsNothing);
  });

  testWidgets('closing the engine hides the transcript at once', (
    tester,
  ) async {
    await tester.pumpWidget(harness());
    await put(tester, listening(transcript: VoiceTranscript(line)));
    expect(find.byType(DialogueBox), findsOneWidget);

    await put(
      tester,
      VoiceState(
        settings: const VoiceSettings(),
        status: VoiceStatus.off,
        lastTranscript: VoiceTranscript(line),
      ),
    );

    expect(find.byType(DialogueBox), findsNothing);
  });

  testWidgets('a remount never resurrects a stale transcript', (tester) async {
    // The carousel disposes and rebuilds the page's subtree on every swipe, so
    // the box mounts over an engine that may have spoken long ago.
    cubit.put(
      listening(
        transcript: VoiceTranscript(
          line,
          time: DateTime.now().subtract(dwell * 2),
        ),
      ),
    );
    await tester.pumpWidget(harness());
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(DialogueBox), findsNothing);
  });

  testWidgets('a remount keeps showing a transcript still within its dwell', (
    tester,
  ) async {
    cubit.put(
      listening(
        transcript: VoiceTranscript(
          line,
          time: DateTime.now().subtract(const Duration(seconds: 1)),
        ),
      ),
    );
    await tester.pumpWidget(harness());
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(DialogueBox), findsOneWidget);

    // …and only for the remainder of that dwell, not a fresh 8s.
    await tester.pump(const Duration(seconds: 7));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(DialogueBox), findsNothing);
  });

  AgentState reply(String text, {required bool done, DateTime? at}) {
    final time = at ?? DateTime.now();
    return AgentState(
      settings: const AgentSettings(),
      reply: AgentReply(text: text, done: done, started: time, updated: time),
    );
  }

  Future<void> putAgent(WidgetTester tester, AgentState state) async {
    agentCubit.put(state);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('a streaming assistant reply outranks the transcript', (
    tester,
  ) async {
    await tester.pumpWidget(harness());
    await put(tester, listening(transcript: VoiceTranscript(line)));
    await putAgent(tester, reply('Working on', done: false));

    expect(find.text('Working on'), findsOneWidget);
    expect(find.text(line), findsNothing);
    // Tagged as the assistant, not the user.
    expect(find.text('Assistant'), findsOneWidget);

    // A streaming reply never expires, even past the dwell…
    await putAgent(tester, reply('Working on it.', done: false));
    await tester.pump(dwell * 2);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Working on it.'), findsOneWidget);

    // …but a finished one that fits does, once the dwell elapses.
    await putAgent(tester, reply('Got it.', done: true));
    await tester.pump(dwell);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(DialogueBox), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a long reply stays until it has scrolled, then lingers', (
    tester,
  ) async {
    await tester.pumpWidget(harness());
    await put(tester, listening());

    // Far more than the two visible lines: the box has to auto-scroll to reveal
    // it all, which takes longer than the plain dwell.
    const long =
        'This is a rather long assistant reply. It is deliberately more than '
        'the dialogue box can show at once, so it has to scroll from top to '
        'bottom before the reader has seen the whole thing.';
    await putAgent(tester, reply(long, done: true));
    expect(find.byType(DialogueBox), findsOneWidget);

    // Past the plain dwell it must still be up — it is mid-reveal, not expired.
    await tester.pump(dwell);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(DialogueBox), findsOneWidget);

    // Let the scroll reach the bottom, then let the post-reveal linger elapse.
    await tester.pumpAndSettle();
    await tester.pump(dwell);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(DialogueBox), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a long reply that streams then finishes is not cut off', (
    tester,
  ) async {
    await tester.pumpWidget(harness());
    await put(tester, listening());

    const long =
        'This is a rather long assistant reply. It is deliberately more than '
        'the dialogue box can show at once, so it has to scroll from top to '
        'bottom before the reader has seen the whole thing.';

    // The repository streams deltas as one growing reply keyed by `started`,
    // then finishes with `done: true` carrying the *same* text (it reuses the
    // streamed buffer). That final update rebuilds nothing, so the box never
    // re-announced its scroll — the box used to fall back to the plain dwell and
    // vanish mid-scroll. Reproduce that exact shape: fixed `started`, same tail.
    final started = DateTime.now();
    AgentState streaming(String text, {required bool done}) => AgentState(
      settings: const AgentSettings(),
      reply: AgentReply(
        text: text,
        done: done,
        started: started,
        updated: DateTime.now(),
      ),
    );

    await putAgent(tester, streaming(long.substring(0, 90), done: false));
    await putAgent(tester, streaming(long, done: false));
    await putAgent(tester, streaming(long, done: true));
    expect(find.byType(DialogueBox), findsOneWidget);

    // Past the plain dwell it must still be up — it is mid-reveal, not expired.
    await tester.pump(dwell);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(DialogueBox), findsOneWidget);

    // Let the scroll reach the bottom, then let the post-reveal linger elapse.
    await tester.pumpAndSettle();
    await tester.pump(dwell);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(DialogueBox), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a newer utterance replaces a finished reply', (tester) async {
    await tester.pumpWidget(harness());
    await put(tester, listening());
    await putAgent(tester, reply('An answer.', done: true));
    expect(find.text('An answer.'), findsOneWidget);

    await put(tester, listening(transcript: VoiceTranscript('follow-up')));
    expect(find.text('follow-up'), findsOneWidget);
    expect(find.text('An answer.'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
