import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:nano_dash/data/repositories/agent_repository.dart';
import 'package:nano_dash/data/repositories/settings_repository.dart';
import 'package:nano_dash/data/repositories/voice_repository.dart';
import 'package:nano_dash/data/services/agent_service.dart';
import 'package:nano_dash/data/services/locator.dart';
import 'package:nano_dash/data/services/voice_service.dart';
import 'package:nano_dash/domain/models/agent.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A [VoiceService] whose engine is imaginary: streams are backed by local
/// controllers, `speak` collects what would have been synthesized, and the
/// lifecycle methods only flip flags (the base class's model-file validation
/// never runs).
class _FakeVoiceService extends VoiceService {
  final transcriptsCtrl = StreamController<VoiceTranscript>.broadcast();
  final speakingCtrl = StreamController<bool>.broadcast();
  final wakeCtrl = StreamController<void>.broadcast();
  final sleepCtrl = StreamController<void>.broadcast();
  final errorsCtrl = StreamController<String>.broadcast();

  bool running = true;
  bool speakingNow = false;
  bool aec = true;
  int wakeCalls = 0;
  int stopSpeakingCalls = 0;

  /// One entry per completed `speak`/`speakText` call: the full text.
  final spoken = <String>[];

  @override
  Stream<VoiceTranscript> get transcripts => transcriptsCtrl.stream;

  @override
  Stream<bool> get speaking => speakingCtrl.stream;

  @override
  Stream<void> get wake => wakeCtrl.stream;

  @override
  Stream<void> get sleep => sleepCtrl.stream;

  @override
  Stream<String> get errors => errorsCtrl.stream;

  @override
  bool get isRunning => running;

  @override
  bool get isSpeaking => speakingNow;

  @override
  bool get aecEnabled => aec;

  @override
  Future<void> start(VoiceConfig config) async => running = true;

  @override
  Future<void> stop() async => running = false;

  @override
  Future<void> speak(Stream<String> textDeltas) async {
    final buffer = StringBuffer();
    await for (final delta in textDeltas) {
      buffer.write(delta);
    }
    spoken.add(buffer.toString());
  }

  @override
  Future<void> speakText(String text) async => spoken.add(text);

  @override
  Future<void> stopSpeaking() async => stopSpeakingCalls++;

  @override
  void wakeEngine() => wakeCalls++;

  @override
  void sleepEngine() {}

  @override
  Future<void> dispose() async {
    await transcriptsCtrl.close();
    await speakingCtrl.close();
    await wakeCtrl.close();
    await sleepCtrl.close();
    await errorsCtrl.close();
  }
}

/// One scripted [AgentRun]: the test drives its deltas and completion.
class _ScriptedRun<T> {
  final deltas = StreamController<String>();
  final result = Completer<T>();
  bool aborted = false;

  late final AgentRun<T> run = AgentRun<T>(
    deltas.stream,
    result.future,
    () => aborted = true,
  );

  Future<void> emit(String text) async => deltas.add(text);

  Future<void> finish(T value) async {
    await deltas.close();
    result.complete(value);
  }

  Future<void> fail(Object error) async {
    await deltas.close();
    result.completeError(error);
  }
}

/// An [AgentService] that never touches genkit: every ask returns the next
/// scripted run and records what it was asked.
class _FakeAgentService extends AgentService {
  final lightRuns = <_ScriptedRun<LightOutcome>>[];
  final lightHistories = <List<AgentTurn>>[];
  final lightTexts = <String>[];

  final orchestratorRuns = <_ScriptedRun<String>>[];
  final orchestratorBriefs = <String>[];
  Future<String?> Function(String question)? lastAskUser;

  @override
  AgentRun<LightOutcome> askLight({
    required AgentSettings settings,
    required List<AgentTurn> history,
    required String userText,
  }) {
    final scripted = _ScriptedRun<LightOutcome>();
    lightRuns.add(scripted);
    lightHistories.add(history);
    lightTexts.add(userText);
    return scripted.run;
  }

  @override
  AgentRun<String> askOrchestrator({
    required AgentSettings settings,
    required List<AgentTurn> history,
    required String userText,
    required String brief,
    required List<AgentTool> tools,
    required Future<String?> Function(String question) onAskUser,
  }) {
    final scripted = _ScriptedRun<String>();
    orchestratorRuns.add(scripted);
    orchestratorBriefs.add(brief);
    lastAskUser = onAskUser;
    return scripted.run;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    // The repositories log through the Loggable mixin, which resolves its
    // Logger from the app's GetIt locator.
    if (!locator.isRegistered<Logger>()) {
      locator.registerSingleton<Logger>(Logger(level: Level.off));
    }
  });

  late _FakeVoiceService voice;
  late VoiceRepository voiceRepository;
  late _FakeAgentService service;
  late AgentRepository repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final settings = SettingsRepository(prefs);
    voice = _FakeVoiceService();
    voiceRepository = VoiceRepository(settings, voice);
    service = _FakeAgentService();
    repository = AgentRepository(
      settings,
      voiceRepository,
      service,
      errorLine: 'oops',
    );
    await repository.save(const AgentSettings(enabled: true, apiKey: 'key'));
  });

  tearDown(() async {
    await repository.dispose();
    await voiceRepository.dispose();
  });

  void hear(String text) => voice.transcriptsCtrl.add(VoiceTranscript(text));

  test('a light answer streams to TTS and lands in history', () async {
    final replies = <AgentReply>[];
    repository.replies.listen(replies.add);

    hear('hi');
    await pumpEventQueue();
    expect(service.lightRuns, hasLength(1));
    expect(service.lightTexts, ['hi']);
    expect(service.lightHistories.single, isEmpty);
    expect(repository.phase, AgentPhase.answering);

    final run = service.lightRuns.single;
    await run.emit('Hello');
    await run.emit(' there.');
    await run.finish(const LightAnswered('Hello there.'));
    await pumpEventQueue();

    expect(voice.spoken, ['Hello there.']);
    expect(repository.phase, AgentPhase.idle);
    expect(replies.last.done, isTrue);
    expect(replies.last.text, 'Hello there.');
    // No orchestrator involved.
    expect(service.orchestratorRuns, isEmpty);

    // The follow-up question sees the exchange in its history.
    hear('and?');
    await pumpEventQueue();
    expect(service.lightHistories[1].map((t) => t.text), [
      'hi',
      'Hello there.',
    ]);
  });

  test('an escalated question speaks the ack, then the orchestrator', () async {
    hear('what is the weather this weekend?');
    await pumpEventQueue();
    await service.lightRuns.single.finish(
      const LightEscalated(ack: 'Let me check.', brief: 'weekend weather'),
    );
    await pumpEventQueue();

    expect(service.orchestratorRuns, hasLength(1));
    expect(service.orchestratorBriefs, ['weekend weather']);
    expect(repository.phase, AgentPhase.working);

    final orchestrator = service.orchestratorRuns.single;
    await orchestrator.emit('Sunny all weekend.');
    await orchestrator.finish('Sunny all weekend.');
    await pumpEventQueue();

    expect(voice.spoken, ['Let me check. Sunny all weekend.']);
    expect(repository.phase, AgentPhase.idle);
    expect(repository.lastReply!.text, 'Let me check. Sunny all weekend.');
  });

  test('a new question barges in: cancels the run and the speech', () async {
    hear('first');
    await pumpEventQueue();
    final first = service.lightRuns.single;

    hear('second');
    await pumpEventQueue();
    expect(first.aborted, isTrue);
    expect(voice.stopSpeakingCalls, greaterThanOrEqualTo(1));
    expect(service.lightRuns, hasLength(2));

    // The dead run's late output must go nowhere.
    await first.emit('stale');
    await first.fail(StateError('aborted by client close'));
    final second = service.lightRuns[1];
    await second.emit('Fresh.');
    await second.finish(const LightAnswered('Fresh.'));
    await pumpEventQueue();

    expect(repository.lastReply!.text, 'Fresh.');
    expect(voice.spoken, isNot(contains(contains('stale'))));
    expect(voice.spoken, contains('Fresh.'));
  });

  test(
    'ask_user consumes the next utterance instead of starting anew',
    () async {
      hear('book something');
      await pumpEventQueue();
      await service.lightRuns.single.finish(
        const LightEscalated(ack: 'Okay.', brief: 'booking'),
      );
      await pumpEventQueue();

      final answerFuture = service.lastAskUser!('For which day?');
      await pumpEventQueue();
      expect(repository.phase, AgentPhase.askingUser);
      expect(voice.wakeCalls, 1);
      expect(repository.lastReply!.text, contains('For which day?'));

      hear('Tomorrow');
      expect(await answerFuture, 'Tomorrow');
      // The answer did not start a second question.
      expect(service.lightRuns, hasLength(1));
      expect(repository.phase, AgentPhase.working);

      final orchestrator = service.orchestratorRuns.single;
      await orchestrator.emit(' Booked for tomorrow.');
      await orchestrator.finish('Booked for tomorrow.');
      await pumpEventQueue();
      expect(voice.spoken.single, contains('Booked for tomorrow.'));
    },
  );

  test('ask_user is honored once per question, then declined', () async {
    hear('plan my day');
    await pumpEventQueue();
    await service.lightRuns.single.finish(
      const LightEscalated(ack: 'Sure.', brief: 'plan'),
    );
    await pumpEventQueue();

    // The first clarification does the full voice round-trip.
    final first = service.lastAskUser!('Morning or afternoon?');
    await pumpEventQueue();
    expect(repository.phase, AgentPhase.askingUser);
    expect(voice.wakeCalls, 1);
    hear('Morning');
    expect(await first, 'Morning');

    // A second clarification in the same question is declined immediately:
    // no new prompt spoken, no wake, and no askingUser phase.
    final second = await service.lastAskUser!('Which city?');
    expect(second, isNull);
    expect(voice.wakeCalls, 1);
    expect(repository.phase, AgentPhase.working);

    await service.orchestratorRuns.single.finish('Planned.');
    await pumpEventQueue();
  });

  test('without AEC, transcripts heard while speaking are dropped', () async {
    voice.aec = false;
    voice.speakingNow = true;
    hear('echo of my own reply');
    await pumpEventQueue();
    expect(service.lightRuns, isEmpty);
  });

  test('a disabled or keyless agent ignores transcripts', () async {
    await repository.save(const AgentSettings(enabled: false, apiKey: 'key'));
    hear('anyone there?');
    await pumpEventQueue();
    expect(service.lightRuns, isEmpty);

    await repository.save(const AgentSettings(enabled: true, apiKey: ''));
    hear('anyone there?');
    await pumpEventQueue();
    expect(service.lightRuns, isEmpty);
  });

  test('a failed run apologizes with the error line', () async {
    hear('hi');
    await pumpEventQueue();
    await service.lightRuns.single.fail(Exception('boom'));
    await pumpEventQueue();
    expect(voice.spoken, ['oops']);
    expect(repository.lastReply!.text, 'oops');
    expect(repository.phase, AgentPhase.idle);
  });

  test('closing the voice engine clears the conversation history', () async {
    hear('hi');
    await pumpEventQueue();
    final run = service.lightRuns.single;
    await run.emit('Hello.');
    await run.finish(const LightAnswered('Hello.'));
    await pumpEventQueue();

    // Walk the engine through open → closed so statusChanges emits `off`
    // (enable() is a no-op while the fake already reads as running).
    voice.running = false;
    await voiceRepository.enable();
    await voiceRepository.disable();
    await pumpEventQueue();

    hear('do you remember me?');
    await pumpEventQueue();
    expect(service.lightHistories.last, isEmpty);
  });
}
