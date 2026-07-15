import 'dart:async';
import 'dart:io';

import 'package:genkit/genkit.dart';
import 'package:genkit_openai/genkit_openai.dart';
import 'package:http/io_client.dart';
import 'package:schemantic/schemantic.dart' show SchemanticType;

import '../../domain/models/agent.dart';
import '../../extensions/loggable.dart';

/// One tool the orchestrator may call: a JSON-schema-described function whose
/// result is fed back to the model as plain text.
class AgentTool {
  const AgentTool({
    required this.name,
    required this.description,
    required this.parameters,
    required this.run,
  });

  final String name;
  final String description;

  /// JSON Schema for the tool's input object.
  final Map<String, Object?> parameters;

  final Future<String> Function(Map<String, dynamic> args) run;
}

/// How the light model handled a question.
sealed class LightOutcome {
  const LightOutcome();
}

/// It answered directly; [text] is the complete reply (already streamed).
class LightAnswered extends LightOutcome {
  const LightAnswered(this.text);

  final String text;
}

/// It handed off to the orchestrator. [ack] is the one-sentence acknowledgement
/// to speak if the model streamed no text of its own; [brief] restates the task
/// for the pro model.
///
/// This is the light model's single routing decision. Today there is one
/// destination (the orchestrator); a future specialist worker would be selected
/// by adding a `target` here and dispatching on it in the caller — the light
/// model already decides *that* it hands off, so it is the place to decide
/// *where*.
class LightEscalated extends LightOutcome {
  const LightEscalated({required this.ack, required this.brief});

  final String ack;
  final String brief;
}

/// A question in flight: text deltas stream on [deltas] while [result] settles
/// once the model is done. [cancel] force-closes the underlying HTTP client
/// so a cancelled run's [result] completes with an error and [cancelled] tells
/// consumers to ignore it.
class AgentRun<T> {
  AgentRun(this.deltas, this.result, this._abort);

  final Stream<String> deltas;
  final Future<T> result;
  final void Function() _abort;

  bool _cancelled = false;

  bool get cancelled => _cancelled;

  void cancel() {
    _cancelled = true;
    _abort();
  }
}

/// The genkit boundary: everything LLM lives here, behind plain Dart types.
///
/// Each ask builds a throwaway `Genkit` over one OpenAI-compatible plugin
/// with an injected, optionally proxied HTTP client.
class AgentService with Loggable {
  static const String _namespace = 'agent';

  /// The orchestrator may take a few tool round-trips.
  static const int _maxTurns = 8;

  /// Upper bound on `ask_user` resume cycles.
  static const int _maxAskUserCycles = 2;

  /// Wall-clock stall guard on model I/O: if the endpoint yields no token for this long,
  /// the run is failed instead of left to hang forever.
  static const Duration _kModelStallTimeout = Duration(seconds: 30);

  @override
  String get logIdentifier => '[AgentService]';

  /// First pass: the light model either answers (streaming on `deltas`) or
  /// calls the `escalate` tool, which is intercepted (never executed) and
  /// surfaced as [LightEscalated].
  ///
  /// The light model has no tools of its own beyond `escalate`: anything that
  /// touches a tool — showing a page, fetching data, performing an action —
  /// escalates, so the orchestrator (which owns every tool) does it. That keeps
  /// this pass to a single clean turn: spoken text, or a hand-off.
  AgentRun<LightOutcome> askLight({
    required AgentSettings settings,
    required List<AgentTurn> history,
    required String userText,
    String? context,
  }) {
    logDebug(
      'askLight: model=${settings.lightModel.trim()} '
      'history=${history.length} userText=${_preview(userText)}',
    );
    return _start(settings, (session, deltas) async {
      final stream = session.ai.generateStream(
        model: openAI.model(settings.lightModel.trim(), namespace: _namespace),
        system: _lightSystem(settings, context),
        messages: _toMessages(history, userText),
        tools: [_escalateTool()],
        // Don't let genkit "execute" escalate and loop — it is a routing
        // decision we surface, acted on by the caller.
        returnToolRequests: true,
      );
      final onResult = stream.onResult;
      // A barge-in force-closes the HTTP client mid-stream; the delta loop then
      // throws before we await onResult, which would otherwise leave onResult's
      // error unobserved and surface as an unhandled exception. Observe it now
      // so the same error is handled no matter which await sees it first.
      unawaited(onResult.then((_) {}, onError: (_) {}));
      var deltaCount = 0;
      await for (final chunk in stream.timeout(_kModelStallTimeout)) {
        if (chunk.text.isNotEmpty) {
          deltaCount++;
          deltas.add(chunk.text);
        }
      }
      final res = await onResult.timeout(_kModelStallTimeout);
      logDebug(
        'askLight done: $deltaCount deltas, '
        'finishReason=${res.finishReason?.value} '
        'toolRequests=${res.toolRequests.map((r) => r.name).toList()}',
      );
      // Escalation is the light model's only non-answer move: hand the task to
      // the orchestrator, which owns the live-data tools and the screen.
      for (final req in res.toolRequests) {
        if (req.name == _escalateName) {
          final brief = req.input?['brief'] as String? ?? userText;
          logInfo('askLight escalated: brief=${_preview(brief)}');
          return LightEscalated(
            ack: req.input?['ack'] as String? ?? '',
            brief: brief,
          );
        }
      }
      logInfo('askLight answered: ${_preview(res.text)}');
      return LightAnswered(res.text);
    });
  }

  /// Second pass: the pro model plans and calls tools  until it produces a
  /// final spoken answer, which is returned complete after having streamed on `deltas`.
  ///
  /// `ask_user` is a genkit interrupt: the generation pauses, [onAskUser] does
  /// the voice round-trip, and the run resumes with the user's answer (or a
  /// "no answer" note on `null`).
  AgentRun<String> askOrchestrator({
    required AgentSettings settings,
    required List<AgentTurn> history,
    required String userText,
    required String brief,
    required List<AgentTool> tools,
    required Future<String?> Function(String question) onAskUser,
    String? context,
  }) {
    logDebug(
      'askOrchestrator: model=${settings.proModel.trim()} '
      'history=${history.length} tools=${tools.map((t) => t.name).toList()} '
      'brief=${_preview(brief)}',
    );
    return _start(settings, (session, deltas) async {
      final genkitTools = [
        for (final tool in tools) _toGenkitTool(tool),
        _askUserTool(),
      ];
      var messages = _toMessages(history, userText);
      List<InterruptResponse>? respond;
      var askUserCycles = 0;
      while (true) {
        // A barge-in force-closed the client.
        if (session.aborted) {
          logDebug('askOrchestrator: aborted before turn, bailing');
          return '';
        }
        logDebug(
          'askOrchestrator turn: askUserCycles=$askUserCycles '
          'resuming=${respond != null}',
        );
        final stream = session.ai.generateStream(
          model: openAI.model(settings.proModel.trim(), namespace: _namespace),
          system: _orchestratorSystem(settings, brief, context),
          messages: messages,
          tools: genkitTools,
          maxTurns: _maxTurns,
          interruptRespond: respond,
        );
        final onResult = stream.onResult;
        // See askLight: keep onResult's error observed so a barge-in abort
        // can't escape as an unhandled exception.
        unawaited(onResult.then((_) {}, onError: (_) {}));
        var deltaCount = 0;
        await for (final chunk in stream.timeout(_kModelStallTimeout)) {
          if (chunk.text.isNotEmpty) {
            deltaCount++;
            deltas.add(chunk.text);
          }
        }
        final res = await onResult.timeout(_kModelStallTimeout);
        logDebug(
          'askOrchestrator turn done: $deltaCount deltas, '
          'finishReason=${res.finishReason?.value} '
          'interrupts=${res.interrupts.length}',
        );
        // A plain finish, or an "interrupted" finish with nothing to respond
        // to, ends the run — never dereference `interrupts.first` blindly.
        if (res.finishReason?.value != 'interrupted' ||
            res.interrupts.isEmpty) {
          logInfo('askOrchestrator answered: ${_preview(res.text)}');
          return res.text;
        }
        // Bound the resume loop so a model that keeps interrupting can't spin
        // it forever; take the best answer we have once the budget is spent.
        if (++askUserCycles > _maxAskUserCycles) {
          logInfo('askOrchestrator: ask_user budget spent, returning answer');
          return res.text;
        }
        final part = res.interrupts.first;
        final question = part.toolRequest.input?['question'] as String? ?? '';
        logInfo('askOrchestrator ask_user: ${_preview(question)}');
        final answer = await onAskUser(question);
        logDebug(
          'askOrchestrator ask_user answered='
          '${answer == null ? 'null' : _preview(answer)}',
        );
        messages = res.messages;
        respond = [
          InterruptResponse(
            part,
            answer ??
                'The user did not answer. Proceed with your best judgment, say '
                    'what you assumed, and do not ask again.',
          ),
        ];
      }
    });
  }

  /// Wire one run: session (client + genkit) → body → always close the deltas
  /// and release the client, even on error or cancellation.
  AgentRun<T> _start<T>(
    AgentSettings settings,
    Future<T> Function(_Session session, StreamController<String> deltas) body,
  ) {
    final session = _Session(settings);
    final deltas = StreamController<String>();
    final completer = Completer<T>();

    runZonedGuarded(
      () async {
        try {
          final value = await body(session, deltas);
          if (!completer.isCompleted) completer.complete(value);
        } catch (e, s) {
          if (!completer.isCompleted) completer.completeError(e, s);
        }
      },
      (e, s) {
        if (!session.aborted && !completer.isCompleted) {
          completer.completeError(e, s);
        }
      },
    );

    final result = completer.future.whenComplete(() {
      unawaited(deltas.close());
      session.dispose();
    });
    return AgentRun(deltas.stream, result, session.abort);
  }

  static const String _escalateName = 'escalate';

  Tool<Map<String, dynamic>, String> _escalateTool() {
    return Tool(
      name: _escalateName,
      description:
          'Hand the question to the powerful assistant, which has live data '
          'tools and time to think. Call this instead of answering.',
      inputSchema: _objectSchema(
        {
          'ack': {
            'type': 'string',
            'description':
                'One short sentence, in the user\'s language, spoken to the '
                'user right now while they wait (e.g. an acknowledgement that '
                'you are looking into it).',
          },
          'brief': {
            'type': 'string',
            'description':
                'Restate the user\'s need for the powerful assistant, with any '
                'context from the conversation it will not see.',
          },
        },
        required: const ['ack', 'brief'],
      ),
      // Never runs: the light call sets returnToolRequests.
      fn: (_, _) async => '',
    );
  }

  static const String _askUserName = 'ask_user';

  Tool<Map<String, dynamic>, String> _askUserTool() {
    return Tool(
      name: _askUserName,
      description:
          'Ask the user one short clarifying question by voice and wait for '
          'their spoken answer. Use at most once, and only when guessing '
          'would likely waste the user\'s time.',
      inputSchema: _objectSchema(
        {
          'question': {
            'type': 'string',
            'description': 'The question, one short spoken sentence.',
          },
        },
        required: const ['question'],
      ),
      fn: (input, context) async => context.interrupt(input['question'] ?? ''),
    );
  }

  Tool<Map<String, dynamic>, String> _toGenkitTool(AgentTool tool) {
    return Tool(
      name: tool.name,
      description: tool.description,
      inputSchema: SchemanticType.from<Map<String, dynamic>>(
        jsonSchema: tool.parameters,
        parse: _asArgs,
      ),
      fn: (input, _) async {
        logDebug('tool ${tool.name} called: args=$input');
        try {
          final result = await tool.run(input);
          logDebug('tool ${tool.name} ok: ${_preview(result)}');
          return result;
        } catch (e) {
          // Feed failures back as text so the model can recover (try another
          // tool, or answer without) instead of aborting the whole run.
          logWarning('tool ${tool.name} failed: $e');
          return 'Tool error: $e';
        }
      },
    );
  }

  static SchemanticType<Map<String, dynamic>> _objectSchema(
    Map<String, Object?> properties, {
    required List<String> required,
  }) {
    return SchemanticType.from<Map<String, dynamic>>(
      jsonSchema: {
        'type': 'object',
        'properties': properties,
        'required': required,
      },
      parse: _asArgs,
    );
  }

  static Map<String, dynamic> _asArgs(dynamic json) =>
      (json as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};

  /// One-line, length-capped rendering of free text for logs, so a long model
  /// answer or brief doesn't flood the console (and newlines stay on one line).
  static String _preview(String text, {int max = 120}) {
    final flat = text.replaceAll('\n', ' ').trim();
    if (flat.length <= max) return '"$flat"';
    return '"${flat.substring(0, max)}…" (${flat.length} chars)';
  }

  static List<Message> _toMessages(List<AgentTurn> history, String userText) {
    return [
      for (final turn in history)
        Message(
          role: turn.fromUser ? Role.user : Role.model,
          content: [TextPart(text: turn.text)],
        ),
      Message(
        role: Role.user,
        content: [TextPart(text: userText)],
      ),
    ];
  }

  /// Shared voice-assistant ground rules: everything both models say is piped
  /// straight into TTS on a small smart display.
  static String _voiceStyle(AgentSettings settings) {
    final persona = settings.persona.trim();
    return 'You are a voice assistant on a small smart display. Everything '
        'you say is spoken aloud by TTS, so reply with short, conversational, '
        'plain-text sentences: no markdown, no lists, no emojis, no URLs. '
        'Always reply in the language the user spoke. '
        'The current local date and time is ${DateTime.now()} '
        '(${DateTime.now().timeZoneName}).'
        '${persona.isEmpty ? '' : '\nYour character: $persona'}';
  }

  static String _lightSystem(AgentSettings settings, String? context) {
    return '${_voiceStyle(settings)}\n'
        'You are the fast first responder. Answer directly, in a couple of '
        'spoken sentences, when you can do so confidently and completely: small '
        'talk, general knowledge, or a question the snapshot below already '
        'answers (the weather, the day\'s calendar, a timer, a reminder).\n'
        'Otherwise do not attempt an answer — call the $_escalateName tool. '
        'Escalate whenever the request needs something you cannot do in words '
        'alone: data the snapshot does not cover (a different place, fresher '
        'figures than its "as of" time, market prices, current events, '
        'research), an action to perform (create, start, cancel, schedule), a '
        'page to be shown on the screen, or any multi-step reasoning. The '
        'powerful assistant behind you holds all the tools and the screen; you '
        'hold none, so never promise to show or do something yourself — '
        'escalate and let it act.'
        '${_contextBlock(context)}';
  }

  static String _orchestratorSystem(
    AgentSettings settings,
    String brief,
    String? context,
  ) {
    return '${_voiceStyle(settings)}\n'
        'You are the capable assistant behind the fast responder, which has '
        'already acknowledged the user. Use your tools to gather what you '
        'need, then give one final spoken answer; only say things meant for '
        'the user\'s ears. If a crucial detail is missing, you may use '
        '$_askUserName once.\n'
        'The fast responder\'s brief: $brief'
        '${_contextBlock(context)}';
  }

  /// The ambient snapshot, framed so both models treat it as possibly-stale
  /// context to be superseded by live tools. Empty string when there is none.
  static String _contextBlock(String? context) {
    if (context == null || context.trim().isEmpty) return '';
    return '\n\nLive snapshot of the user\'s device and data. It may be '
        'slightly stale — the "as of" times say when each part was last '
        'refreshed. Use it to answer directly, but rely on your tools for '
        'anything newer, for a different place, or not shown here:\n$context';
  }
}

/// One run's genkit stack. The `dart:io` [HttpClient] is kept because it is
/// the only abort handle: `close(force: true)` kills the in-flight request,
/// which genkit itself cannot do.
class _Session {
  _Session(AgentSettings settings) : _io = HttpClient() {
    final proxy = settings.proxy.trim();
    if (proxy.isNotEmpty) {
      final uri = Uri.parse(proxy.contains('://') ? proxy : 'http://$proxy');
      final port = uri.hasPort ? uri.port : 8080;
      _io.findProxy = (_) => 'PROXY ${uri.host}:$port';
    }
    final models = {settings.lightModel.trim(), settings.proModel.trim()};
    ai = Genkit(
      plugins: [
        openAI(
          name: AgentService._namespace,
          apiKey: settings.apiKey.trim(),
          baseUrl: settings.baseUrl.trim(),
          httpClient: IOClient(_io),
          models: [
            for (final name in models)
              CustomModelDefinition(
                name: name,
                // Free-form model IDs get heuristic capabilities; claim tool
                // support explicitly or the plugin strips the tools payload.
                info: ModelInfo(
                  supports: {
                    'tools': true,
                    'multiturn': true,
                    'systemRole': true,
                  },
                ),
              ),
          ],
        ),
      ],
      // No .prompt folder: don't touch the filesystem of a packaged app.
      promptDir: null,
    );
  }

  final HttpClient _io;
  late final Genkit ai;
  bool _aborted = false;

  /// True once [abort] has force-closed the client. Any genkit error after
  /// this is the expected fallout of cancelling, to be swallowed rather than
  /// surfaced (see `_start`).
  bool get aborted => _aborted;

  void abort() {
    _aborted = true;
    _io.close(force: true);
  }

  void dispose() {
    _io.close(force: true);
    unawaited(ai.shutdown());
  }
}
