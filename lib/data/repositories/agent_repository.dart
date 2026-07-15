import 'dart:async';

import '../../domain/models/agent.dart';
import '../../domain/models/voice.dart';
import '../../extensions/loggable.dart';
import '../services/agent_service.dart';
import '../services/notification_service.dart';
import 'reminder_repository.dart';
import 'settings_repository.dart';
import 'voice_repository.dart';

/// The agent's conductor: it turns recognized utterances into spoken answers.
///
/// It listens to [VoiceRepository.transcripts] and, per utterance, runs the
/// two-tier flow — the light model answers or escalates, the orchestrator
/// finishes what was escalated — streaming every text delta both into
/// [VoiceRepository.speak] (so TTS starts on the first sentence) and out on
/// [replies] for the dialogue UI. When the voice settings select no synthesizer
/// (`ttsBackend: 'none'`) the speak side is skipped: the agent still listens and
/// streams replies to the UI, but speaks nothing. App-scoped and UI-free, like
/// [VoiceRepository]: it answers whether or not any agent widget is mounted.
///
/// Conversation memory is a rolling window of plain text turns, cleared when
/// the voice engine closes — a household device shouldn't carry context from
/// one mic session into the next indefinitely, and both models share the same
/// window so follow-ups keep working across escalations.
class AgentRepository with Loggable {
  AgentRepository(
    this._settings,
    this._voice,
    this._service, {
    List<AgentTool> tools = const [],
    this.contextBuilder,
    this.errorLine = 'Sorry, something went wrong.',
    ReminderRepository? reminders,
    this.notifications,
    String Function(String text)? reminderLine,
    String Function(String text)? missedReminderLine,
    this.reminderTitle = 'Reminder',
    this.missedReminderTitle = 'Missed reminder',
  }) : _tools = List.unmodifiable(tools),
       _reminderLine = reminderLine ?? ((text) => text),
       _missedReminderLine = missedReminderLine ?? ((text) => text),
       _config = _settings.load(agentSettingsKey) {
    _transcriptSub = _voice.transcripts.listen(_onTranscript);
    _statusSub = _voice.statusChanges.listen(_onStatus);
    _wakeSub = _voice.wake.listen(_onWake);
    // TTS start/stop bears on idleness: a reply may still be draining after the
    // phase has already gone idle, and it mustn't be slept mid-sentence.
    _speakingSub = _voice.speaking.listen((_) => _reviseIdleTimer());
    _reminderSub = reminders?.fired.listen(_onReminderFired);
  }

  final SettingsRepository _settings;
  final VoiceRepository _voice;
  final AgentService _service;
  final List<AgentTool> _tools;

  /// Builds the ambient snapshot (time-adjacent live state: weather, calendar,
  /// timers, reminders) prepended to both models' prompts, or null to add none.
  /// Called once per utterance so the light and orchestrator passes share one
  /// consistent view. Cheap and synchronous — it reads only cached repository
  /// state, never the network.
  final String? Function()? contextBuilder;

  /// Raises the host system notification when a reminder comes due — the visual/
  /// audible complement to speaking it.
  final NotificationService? notifications;

  /// Spoken and shown when a run fails.
  final String errorLine;

  /// Notification titles for a due reminder (the reminder's own text is the
  /// body). Passed in because this repository is l10n-free.
  final String reminderTitle;
  final String missedReminderTitle;

  /// Wrap a fired reminder's text into the announced line ("Reminder: …"),
  final String Function(String text) _reminderLine;
  final String Function(String text) _missedReminderLine;

  static const int _kMaxHistoryTurns = 20;
  static const Duration _kAskUserTimeout = Duration(seconds: 30);

  /// After this long with the engine awake but nothing happening — no speech
  /// heard, no answer in flight, no TTS playing — a wake-gated engine returns to
  /// sleep so the wake word is needed again. Ungated engines are never slept.
  static const Duration _kIdleSleepTimeout = Duration(seconds: 30);

  /// Spoken clarifications allowed per question. One keeps a household device
  /// snappy; further `ask_user` calls are declined so the orchestrator falls
  /// back to its best judgment instead of interrogating the user in a loop.
  static const int _kMaxClarifications = 1;

  /// A paused utterance can reach us as two transcripts, split by VAD on the
  /// gap. When a new transcript supersedes a run that has not begun its real
  /// answer, within this window the earlier fragment is prepended so the split
  /// request stays whole rather than its first half being lost. See [_ask].
  static const Duration _kSplitUtteranceWindow = Duration(seconds: 3);

  late final StreamSubscription<VoiceTranscript> _transcriptSub;
  late final StreamSubscription<VoiceStatus> _statusSub;
  late final StreamSubscription<String?> _wakeSub;
  late final StreamSubscription<bool> _speakingSub;
  StreamSubscription<ReminderFired>? _reminderSub;

  /// Counts down while the engine is awake and nothing is happening; on fire a
  /// wake-gated engine is put back to sleep. See [_reviseIdleTimer].
  Timer? _idleSleepTimer;

  final StreamController<AgentReply> _replies =
      StreamController<AgentReply>.broadcast();
  final StreamController<AgentPhase> _phases =
      StreamController<AgentPhase>.broadcast();

  final List<AgentTurn> _history = [];

  AgentSettings _config;
  AgentPhase _phase = AgentPhase.idle;
  AgentReply? _lastReply;

  /// The run currently talking to the LLM, if any. Only its cancel handle is
  /// needed, hence the erased type argument.
  AgentRun<Object?>? _active;

  /// Set while the orchestrator waits for a spoken answer to `ask_user`; the
  /// next transcript completes it instead of starting a new question.
  Completer<String>? _pendingAnswer;

  final List<String> _pendingAnnouncements = [];

  /// Monotonic run counter: emissions from a superseded run compare stale and
  /// are dropped, so a barge-in can never interleave two answers.
  int _generation = 0;

  /// The user text of the run in flight, retained until it commits its turn to
  /// [_history]. A follow-on transcript that supersedes the run before it has
  /// begun answering is treated as the tail of the same (VAD-split) utterance
  /// and prepended with this. Null when nothing is uncommitted.
  String? _uncommittedUserText;
  DateTime? _uncommittedAt;

  /// Whether the in-flight run has begun delivering its real answer (a direct
  /// light answer or streamed orchestrator text) rather than just the escalate
  /// acknowledgement. A superseding transcript merges only while this is false;
  /// once an answer is under way, a new utterance is a genuine barge-in.
  bool _answerStarted = false;

  @override
  String get logIdentifier => '[AgentRepository]';

  /// The current persisted settings. Read at the start of each question, so a
  /// save applies to the next utterance without restarting anything.
  AgentSettings get config => _config;

  /// Assistant replies as they stream: one growing [AgentReply] per question,
  /// finishing with `done: true`. Broadcast; [lastReply] is the latest value.
  Stream<AgentReply> get replies => _replies.stream;

  AgentReply? get lastReply => _lastReply;

  /// What the agent is doing, for the UI. Broadcast; [phase] is the latest.
  Stream<AgentPhase> get phaseChanges => _phases.stream;

  AgentPhase get phase => _phase;

  Future<void> save(AgentSettings config) {
    _config = config;
    return _settings.save(agentSettingsKey, config);
  }

  /// Stop the current answer without closing the voice engine: cancel the run
  /// and its speech, finalize whatever was shown so the dialogue fades out
  /// normally, and return to idle. Unlike the mic button's tap (which closes
  /// the engine), this is a barge-in on the assistant, not on the session — the
  /// microphone keeps listening. A no-op when nothing is in flight.
  Future<void> stop() async {
    if (_phase == AgentPhase.idle &&
        _active == null &&
        _pendingAnswer == null) {
      return;
    }
    logInfo('stop: barge-in, finalizing current answer');
    // Bumps the generation, so the superseded run's `finally` skips its own
    // phase reset and done-reply: this call owns the finalization below.
    _cancelActive();
    await _voice.stopSpeaking();
    // A run cancelled mid-stream left its last reply with `done: false`, which
    // the dialogue box pins open forever; finalize it so it dwells and fades.
    final reply = _lastReply;
    if (reply != null && !reply.done) {
      _emitReply(
        AgentReply(
          text: reply.text,
          done: true,
          started: reply.started,
          updated: DateTime.now(),
        ),
      );
    }
    _setPhase(AgentPhase.idle);
  }

  /// Speak and show [line] without running the models — the outlet for
  /// app-originated utterances like a fired reminder.
  void announce(String line) {
    if (_phase != AgentPhase.idle) {
      logInfo('announce queued until idle: "$line"');
      _pendingAnnouncements.add(line);
      return;
    }
    logInfo('announce: "$line"');
    _speakAnnouncement(line);
  }

  /// Show [line] as a finished reply and, with a synthesizer selected, speak it.
  void _speakAnnouncement(String line) {
    final now = DateTime.now();
    _emitReply(AgentReply(text: line, done: true, started: now, updated: now));
    if (_voice.config.ttsEnabled) {
      unawaited(_voice.speakText(line));
    }
  }

  void _onReminderFired(ReminderFired event) {
    final text = event.reminder.text;
    unawaited(
      notifications?.notify(
        title: event.missed ? missedReminderTitle : reminderTitle,
        body: text,
        id: NotificationService.reminderId,
      ),
    );
    announce(event.missed ? _missedReminderLine(text) : _reminderLine(text));
  }

  void _drainAnnouncements() {
    if (_pendingAnnouncements.isEmpty || _phase != AgentPhase.idle) return;
    final lines = List<String>.of(_pendingAnnouncements);
    _pendingAnnouncements.clear();
    logInfo('draining ${lines.length} queued announcement(s)');
    _speakAnnouncement(lines.join('\n'));
  }

  void _onTranscript(VoiceTranscript transcript) {
    // Any recognized speech is activity: rearm the idle countdown so a lull is
    // measured from the last thing the user said.
    _reviseIdleTimer();
    final text = transcript.text.trim();
    if (text.isEmpty) return;
    logDebug('transcript: "$text"');

    // Without AEC our own TTS bleeds into the mic and comes back transcribed;
    // taken as a question (or as an ask_user answer) the agent would argue
    // with itself.
    if (_voice.isSpeaking && !_voice.aecEnabled) {
      logDebug('transcript dropped: speaking without AEC');
      return;
    }

    // An utterance while the orchestrator waits on ask_user is the answer,
    // not a new question.
    final pending = _pendingAnswer;
    if (pending != null) {
      logInfo('transcript is ask_user answer');
      _pendingAnswer = null;
      if (!pending.isCompleted) pending.complete(text);
      return;
    }

    if (!_config.isConfigured) {
      logDebug('transcript dropped: agent not configured');
      return;
    }
    unawaited(_ask(text));
  }

  /// A wake-word wake plays a canned greeting straight from the engine.
  void _onWake(String? ack) {
    if (ack == null || ack.isEmpty) return;
    if (_phase != AgentPhase.idle) return;
    logInfo('wake greeting: "$ack"');
    final now = DateTime.now();
    _emitReply(AgentReply(text: ack, done: true, started: now, updated: now));
  }

  /// Engine closed (or failed): the mic session is over, so drop the
  /// conversation and whatever was in flight.
  void _onStatus(VoiceStatus status) {
    // A wake moves the engine to `listening`, which arms the countdown; `off`/
    // `error`/`idle` disarm it (the guard in _reviseIdleTimer sees to that).
    _reviseIdleTimer();
    if (status != VoiceStatus.off && status != VoiceStatus.error) return;
    logInfo(
      'voice engine $status: dropping conversation (${_history.length} '
      'turns) and any in-flight run',
    );
    _cancelActive();
    _history.clear();
    _setPhase(AgentPhase.idle);
  }

  /// Run one question end to end. Any earlier run is barged in on: cancelled
  /// and its speech stopped, then this one owns the voice.
  Future<void> _ask(String rawText) async {
    // A paused utterance can arrive as two transcripts (VAD splits on the gap).
    // If this one supersedes a run that hadn't begun its real answer yet, and
    // follows it closely, stitch the earlier fragment back on instead of losing
    // it; once an answer is under way, treat it as a genuine barge-in.
    final prior = _uncommittedUserText;
    final mergeable =
        prior != null &&
        !_answerStarted &&
        _uncommittedAt != null &&
        DateTime.now().difference(_uncommittedAt!) <= _kSplitUtteranceWindow;
    final userText = mergeable ? '$prior $rawText' : rawText;
    if (mergeable) logInfo('merging split utterance: "$prior" + "$rawText"');

    _cancelActive();
    await _voice.stopSpeaking();

    final generation = ++_generation;
    _uncommittedUserText = userText;
    _uncommittedAt = DateTime.now();
    _answerStarted = false;
    logInfo('ask #$generation: "$userText" (history=${_history.length})');
    final startedAt = DateTime.now();
    final buffer = StringBuffer();
    // With a synthesizer selected, one TTS stream carries the whole answer (ack
    // + orchestrator included): VoiceRepository.speak cancels the previous reply
    // on each call, so a second call would cut off the first's tail mid-sentence.
    // In text-only mode (`ttsBackend: 'none'`) there is no stream — the reply is
    // shown but not spoken.
    final tts = _voice.config.ttsEnabled ? StreamController<String>() : null;
    if (tts != null) unawaited(_voice.speak(tts.stream));

    void push(String text) {
      if (text.isEmpty || generation != _generation) return;
      buffer.write(text);
      if (tts != null && !tts.isClosed) tts.add(text);
      _emitReply(
        AgentReply(
          text: buffer.toString(),
          done: false,
          started: startedAt,
          updated: DateTime.now(),
        ),
      );
    }

    // Phase transitions from a superseded run (e.g. an ask_user unwinding
    // after a barge-in) must not stomp the run that replaced it.
    void setPhase(AgentPhase phase) {
      if (generation == _generation) _setPhase(phase);
    }

    // The point where a real answer starts flowing (not just the escalate
    // acknowledgement): from here a new utterance is a barge-in, not a merge.
    void markAnswering() {
      if (generation == _generation) _answerStarted = true;
    }

    final history = List<AgentTurn>.unmodifiable(_history);
    final context = contextBuilder?.call();
    try {
      setPhase(AgentPhase.answering);
      final light = _service.askLight(
        settings: _config,
        history: history,
        userText: userText,
        context: context,
      );
      _active = light;
      await for (final delta in light.deltas) {
        push(delta);
      }
      final outcome = await light.result;
      if (generation != _generation) {
        logDebug('ask #$generation: superseded after light pass');
        return;
      }

      switch (outcome) {
        case LightAnswered(:final text):
          logInfo('ask #$generation: light answered directly');
          markAnswering();
          // The answer normally arrives as streamed deltas; fall back to the
          // final text when the endpoint didn't stream any.
          if (buffer.isEmpty) push(text);
          break;
        case LightEscalated(:final ack, :final brief):
          logInfo('ask #$generation: escalating to orchestrator');
          // The streamed text, if any, already was the acknowledgement.
          if (buffer.isEmpty) push(ack);
          setPhase(AgentPhase.working);
          push(' ');
          // Honor at most one spoken clarification per question; decline the
          // rest so the orchestrator can't loop the user through questions.
          var clarifications = 0;
          final orchestrator = _service.askOrchestrator(
            settings: _config,
            history: history,
            userText: userText,
            brief: brief,
            tools: _tools,
            context: context,
            onAskUser: (question) {
              if (clarifications >= _kMaxClarifications) {
                logInfo('ask_user past the per-question limit; declining');
                return Future<String?>.value(null);
              }
              clarifications++;
              logDebug('ask_user #$clarifications: "$question"');
              return _askUserByVoice(question, push, setPhase);
            },
          );
          _active = orchestrator;
          final lenBeforeOrchestrator = buffer.length;
          await for (final delta in orchestrator.deltas) {
            markAnswering();
            push(delta);
          }
          final orchestratorText = await orchestrator.result;
          // As with the light pass, fall back to the final text when the
          // endpoint streamed no deltas of its own, so the answer isn't lost.
          if (buffer.length == lenBeforeOrchestrator) push(orchestratorText);
      }
      if (generation != _generation) return;

      final answer = buffer.toString().trim();
      if (answer.isNotEmpty) {
        _history
          ..add(AgentTurn(fromUser: true, text: userText))
          ..add(AgentTurn(fromUser: false, text: answer));
        while (_history.length > _kMaxHistoryTurns) {
          _history.removeAt(0);
        }
        logInfo(
          'ask #$generation done: ${answer.length} chars, '
          'history now ${_history.length} turns',
        );
      } else {
        logDebug('ask #$generation done: empty answer, not stored');
      }
    } catch (e, s) {
      // A cancelled run dies by its own aborted HTTP client; only genuine
      // failures deserve the apology.
      if (generation != _generation) return;
      logWarning('run failed', error: e, stackTrace: s);
      push(errorLine);
    } finally {
      unawaited(tts?.close());
      if (generation == _generation) {
        _active = null;
        // This run finished as the current one (not superseded): its text is
        // committed or spent, so there is no split-utterance tail to merge.
        _uncommittedUserText = null;
        _uncommittedAt = null;
        _emitReply(
          AgentReply(
            text: buffer.toString(),
            done: true,
            started: startedAt,
            updated: DateTime.now(),
          ),
        );
        _setPhase(AgentPhase.idle);
      }
    }
  }

  /// The voice round-trip behind the orchestrator's `ask_user` tool: speak the
  /// question through the reply stream (so it is also shown), make sure the
  /// engine is actually listening, then wait for the next utterance.
  Future<String?> _askUserByVoice(
    String question,
    void Function(String) push,
    void Function(AgentPhase) setPhase,
  ) async {
    setPhase(AgentPhase.askingUser);
    push(' $question');
    // A wake-gated engine may have gone back to sleep; the user shouldn't
    // need the wake word to answer a question the agent asked.
    _voice.wakeNow();
    final completer = Completer<String>();
    _pendingAnswer = completer;
    try {
      return await completer.future.timeout(_kAskUserTimeout);
    } on TimeoutException {
      logInfo('ask_user timed out');
      return null;
    } finally {
      _pendingAnswer = null;
      setPhase(AgentPhase.working);
    }
  }

  void _cancelActive() {
    _generation++;
    if (_active != null || _pendingAnswer != null) {
      logDebug(
        'cancelActive: gen->$_generation '
        'active=${_active != null} pending=${_pendingAnswer != null}',
      );
    }
    _active?.cancel();
    _active = null;
    // A superseded or stopped run leaves no split-utterance tail to merge onto
    // the next transcript (a deliberate stop, or a genuine new question).
    _uncommittedUserText = null;
    _uncommittedAt = null;
    _answerStarted = false;
    // Fail an in-flight ask_user wait so its run unwinds now instead of
    // holding on until the timeout.
    final pending = _pendingAnswer;
    _pendingAnswer = null;
    if (pending != null && !pending.isCompleted) {
      pending.completeError(StateError('superseded'));
    }
  }

  void _emitReply(AgentReply reply) {
    _lastReply = reply;
    if (!_replies.isClosed) _replies.add(reply);
  }

  void _setPhase(AgentPhase phase) {
    if (_phase == phase) return;
    _phase = phase;
    if (!_phases.isClosed) _phases.add(phase);
    // Entering answering/working/askingUser suppresses the countdown; returning
    // to idle rearms it (if the engine is awake and no longer speaking).
    _reviseIdleTimer();
    if (phase == AgentPhase.idle) _drainAnnouncements();
  }

  /// Single arbiter of the inactivity auto-sleep. Cancels any pending timer and,
  /// only when the engine is wake-gated and truly idle right now — awake, no
  /// answer in flight, not speaking, not awaiting an ask_user reply — starts a
  /// fresh [_kIdleSleepTimeout] countdown. Called on every event that changes
  /// idleness, so a genuine lull is what elapses; on fire the engine is put back
  /// to sleep and the wake word is needed again. History is left intact —
  /// sleeping is not closing, so context survives a wake→sleep→wake in one
  /// session (it clears on engine close, in [_onStatus]).
  void _reviseIdleTimer() {
    _idleSleepTimer?.cancel();
    _idleSleepTimer = null;

    final armed =
        _voice.config.enableWake &&
        _voice.status == VoiceStatus.listening &&
        _phase == AgentPhase.idle &&
        !_voice.isSpeaking &&
        _pendingAnswer == null;
    if (!armed) return;

    _idleSleepTimer = Timer(_kIdleSleepTimeout, () {
      _idleSleepTimer = null;
      // Re-check under the same guard: state may have moved on before we fired.
      if (!_voice.config.enableWake ||
          _voice.status != VoiceStatus.listening ||
          _phase != AgentPhase.idle ||
          _voice.isSpeaking ||
          _pendingAnswer != null) {
        return;
      }
      logInfo('idle ${_kIdleSleepTimeout.inSeconds}s: returning to wake-gated');
      _voice.sleepNow();
    });
  }

  Future<void> dispose() async {
    _cancelActive();
    _idleSleepTimer?.cancel();
    await _transcriptSub.cancel();
    await _statusSub.cancel();
    await _wakeSub.cancel();
    await _speakingSub.cancel();
    await _reminderSub?.cancel();
    await _replies.close();
    await _phases.close();
  }
}
