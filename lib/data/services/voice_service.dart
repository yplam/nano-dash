import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:voice_engine/voice_engine.dart';

import '../../domain/models/voice.dart';
import '../../extensions/loggable.dart';

export 'package:voice_engine/voice_engine.dart'
    show VoiceTranscript, EnrollmentResult;

/// Thrown when the voice engine can't be started.
class VoiceException implements Exception {
  VoiceException(this.message);

  final String message;

  @override
  String toString() => 'VoiceException: $message';
}

/// Canned greetings spoken the instant the wake word fires, before the user has
/// said anything. One is chosen round-robin by the engine, which pre-synthesizes
/// and caches them with the local TTS model at open (that first synthesis also
/// warms up ONNX Runtime, so the first real reply is quicker) and plays the
/// cached audio with no synthesis latency on wake. Local backend + wake only.
const List<String> kWakeAckPhrases = <String>[
  '我在，有什么可以帮到你吗？',
  '嗯，我在听。',
  '你好呀，需要我做什么？',
];

/// Configuration for the full-duplex voice engine. The user points it at a
/// single [modelsDir]; the ASR, TTS and keyword-spotter models live in fixed
/// `asr/`, `tts/` and `kws/` subfolders, and the shared Silero VAD sits at the
/// root:
/// - [vadModelPath] (`<modelsDir>/silero_vad.onnx`) — the Silero VAD.
/// - [asrModelDir] (`<modelsDir>/asr`) — `tokens.txt` and the SenseVoice model as
///   `model.onnx` or `model.int8.onnx` (fp32 preferred).
/// - [ttsModelDir] (`<modelsDir>/tts`) — a VITS or Kokoro model (`model.onnx`,
///   `tokens.txt`, plus a lexicon — the engine sniffs the family).
/// - [kwsModelDir] (`<modelsDir>/kws`) — the wake-word model and `keywords.txt`
///   (only consulted when [enableWake]).
class VoiceConfig {
  const VoiceConfig({
    required this.modelsDir,
    this.language = 'auto',
    this.sid = 0,
    this.speed = 1.0,
    this.enableAec = true,
    this.enableWake = false,
    this.ttsBackend = 'local',
    this.ttsApiKey = '',
    this.ttsResourceId = '',
    this.ttsSpeaker = '',
    this.ttsModel = '',
    this.ttsBaseUrl = '',
    this.ttsLanguage = '',
    this.ttsInstructions = '',
    this.ttsProxy = '',
    this.wakeAckPhrases = kWakeAckPhrases,
    this.enableSpeakerId = false,
    this.speakerVerify = false,
  });

  /// Build the engine-facing config from the persisted user [settings].
  factory VoiceConfig.fromSettings(VoiceSettings settings) => VoiceConfig(
    modelsDir: settings.modelsDir,
    language: settings.language,
    sid: settings.sid,
    speed: settings.speed,
    enableAec: settings.enableAec,
    enableWake: settings.enableWake,
    ttsBackend: settings.ttsBackend,
    ttsApiKey: settings.ttsApiKey,
    ttsResourceId: settings.ttsResourceId,
    ttsSpeaker: settings.ttsSpeaker,
    ttsModel: settings.ttsModel,
    ttsBaseUrl: settings.ttsBaseUrl,
    ttsLanguage: settings.ttsLanguage,
    ttsInstructions: settings.ttsInstructions,
    ttsProxy: settings.ttsProxy,
    enableSpeakerId: settings.enableSpeakerId,
    speakerVerify: settings.enableSpeakerId,
  );

  /// Root folder holding the `asr/`, `tts/` and `kws/` model subfolders.
  final String modelsDir;
  final String language;
  final int sid;
  final double speed;
  final bool enableAec;

  /// TTS backend: `'local'` (the on-disk VITS/Kokoro model under [ttsModelDir]),
  /// `'volcengine'` (Volcengine online WebSocket streaming TTS), `'vllm'` (a
  /// vLLM-Omni / OpenAI-compatible `/v1/audio/speech/stream` WebSocket), or
  /// `'openai'` (the OpenAI HTTP API `POST /v1/audio/speech`).
  final String ttsBackend;

  /// Online TTS API key. For `'volcengine'` it is the `X-Api-Key` header; for
  /// `'vllm'`/`'openai'` it is sent as `Authorization: Bearer` (empty omits it).
  final String ttsApiKey;

  /// Online TTS resource id (`X-Api-Resource-Id`); empty applies the default.
  /// Only used when [ttsBackend] is `'volcengine'`.
  final String ttsResourceId;

  /// Online TTS voice id. For `'volcengine'` e.g.
  /// `zh_female_gaolengyujie_uranus_bigtts`; for `'vllm'` e.g. `vivian`; for
  /// `'openai'` e.g. `alloy`.
  final String ttsSpeaker;

  /// Online TTS optional model version/id (e.g. `gpt-4o-mini-tts` for OpenAI);
  /// empty omits it.
  final String ttsModel;

  /// Online TTS server base URL. For `'vllm'` (e.g. `http://localhost:8091`) a
  /// `ws(s)://.../v1/audio/speech/stream` endpoint is derived; for `'openai'`
  /// (e.g. `https://api.openai.com/v1`) the `/audio/speech` endpoint is derived.
  final String ttsBaseUrl;

  /// vLLM-Omni TTS language steer (Qwen3-TTS only, e.g. `English`); empty omits
  /// it. Used only when [ttsBackend] is `'vllm'`.
  final String ttsLanguage;

  /// Online TTS voice style/emotion instructions; empty omits them. Used when
  /// [ttsBackend] is `'vllm'` or `'openai'`.
  final String ttsInstructions;

  /// Optional HTTP proxy for the online TTS connection (e.g.
  /// `http://127.0.0.1:1080`); empty connects directly. Used when [ttsBackend]
  /// is `'vllm'` or `'openai'`.
  final String ttsProxy;

  /// Canned wake greetings (see [kWakeAckPhrases]). Passed to the engine only for
  /// the local backend with wake gating on; otherwise dropped, since only the
  /// local TTS worker caches and plays them.
  final List<String> wakeAckPhrases;

  /// Load the speaker-identification model (from [speakerModelDir]) so the user
  /// can enroll a voice. When `false` no speaker model is loaded.
  final bool enableSpeakerId;

  /// Enforce the speaker gate: drop transcripts from anyone but the enrolled
  /// voice. Needs [enableSpeakerId]; accepts all voices until someone is enrolled.
  final bool speakerVerify;

  /// Speaker-embedding model folder; its `model.onnx` is the voiceprint model.
  String get speakerModelDir => p.join(modelsDir, 'speaker');

  /// The speaker-embedding model file passed to the engine.
  String get speakerModelPath => p.join(speakerModelDir, 'model.onnx');

  /// Where enrolled voiceprints are persisted (survives restarts).
  String get speakerProfilePath => p.join(modelsDir, 'speaker_profile.json');

  /// Whether the Volcengine online WebSocket TTS backend is selected.
  bool get isVolcengineTts => ttsBackend == 'volcengine';

  /// Whether the vLLM-Omni online WebSocket TTS backend is selected.
  bool get isVllmTts => ttsBackend == 'vllm';

  /// Whether the OpenAI HTTP TTS backend is selected.
  bool get isOpenaiTts => ttsBackend == 'openai';

  /// Whether the local, on-disk TTS model backend is selected.
  bool get isLocalTts => ttsBackend == 'local';

  /// Gate the ASR behind a wake word: when `true`, the engine starts asleep and
  /// listens only for the keyword-spotter (from [kwsModelDir]) until woken.
  final bool enableWake;

  /// Silero VAD model file, shared by ASR and the wake path. Lives at the
  /// [modelsDir] root because the VAD is not an ASR model.
  String get vadModelPath => p.join(modelsDir, 'silero_vad.onnx');

  /// SenseVoice ASR model folder.
  String get asrModelDir => p.join(modelsDir, 'asr');

  /// TTS (VITS/Kokoro) model folder.
  String get ttsModelDir => p.join(modelsDir, 'tts');

  /// Keyword-spotter model folder. The wake phrases come from a tokenized
  /// `keywords.txt` in this directory (the engine reads it directly; see
  /// `kws.rs`). Only required when [enableWake].
  String get kwsModelDir => p.join(modelsDir, 'kws');

  /// Post-AEC RMS gate applied only while TTS is playing: mic frames quieter
  /// than this are zeroed before the VAD, so residual echo of the assistant's
  /// own voice can't trip a false barge-in. Genuine (louder) double-talk passes
  /// through. Hardcoded; tune here against real mic/speaker hardware (0 = off).
  static const double kEnergyGate = 0.1;

  /// Build the engine config. Wake phrases are left empty so the engine reads
  /// the tokenized `keywords.txt` from [kwsModelDir] directly.
  VoiceEngineConfig toEngineConfig() => VoiceEngineConfig(
    asrModelDir: asrModelDir,
    vadModelPath: vadModelPath,
    language: language,
    // Inverse text normalization is always on (digits/punctuation in written
    // form); it is no longer user-configurable.
    useItn: true,
    ttsBackend: ttsBackend,
    ttsModelDir: ttsModelDir,
    ttsApiKey: ttsApiKey,
    ttsResourceId: ttsResourceId,
    ttsSpeaker: ttsSpeaker,
    ttsModel: ttsModel,
    ttsBaseUrl: ttsBaseUrl,
    ttsLanguage: ttsLanguage,
    ttsInstructions: ttsInstructions,
    ttsProxy: ttsProxy,
    sid: sid,
    speed: speed,
    enableAec: enableAec,
    energyGate: kEnergyGate,
    enableWake: enableWake,
    kwsModelDir: kwsModelDir,
    wakeAckPhrases: (isLocalTts && enableWake) ? wakeAckPhrases : const [],
    speakerModelPath: enableSpeakerId ? speakerModelPath : '',
    speakerProfilePath: enableSpeakerId ? speakerProfilePath : '',
    speakerVerify: enableSpeakerId && speakerVerify,
  );
}

/// Local, offline full-duplex voice loop, built on the native `voice_engine`:
/// the microphone is captured, echo-cancelled against what TTS is playing, run
/// through VAD + SenseVoice, and recognized utterances are emitted on
/// [transcripts]; reply text handed to [speak]/[speakText] is synthesized and
/// played. Because the AEC removes the played reply from the mic, capture and
/// playback run at the same time.
class VoiceService with Loggable {
  VoiceService();

  final VoiceEngineController _controller = VoiceEngineController();
  bool _running = false;
  bool _aecEnabled = true;

  @override
  String get logIdentifier => '[VoiceService]';

  /// Recognized utterances, one event per VAD-segmented span. Broadcast, so it
  /// is safe to listen before the first [start] and across restarts.
  Stream<VoiceTranscript> get transcripts => _controller.transcripts;

  /// Non-fatal engine errors (e.g. an AEC frame failure), for logging.
  Stream<String> get errors => _controller.errors;

  /// TTS playback state: `true` while a reply is being spoken, `false` once the
  /// audio drains. Drives the barge-in echo guard and the Live2D lip sync.
  Stream<bool> get speaking => _controller.speaking;

  /// Whether TTS audio is currently playing (latest [speaking] value).
  bool get isSpeaking => _controller.isSpeaking;

  /// The current lip-sync mouth-opening level in `[0, 1]`, from the RMS of the
  /// TTS audio playing out right now. Lock-free native read; poll it to drive
  /// Live2D lip sync (see [VoiceRepository.speakingLevel]).
  double get speakingLevel => _controller.speakingLevel;

  /// Fires when the wake word is recognized and ASR starts (wake-gated runs).
  /// Carries the canned greeting the engine began playing, or `null` when none.
  Stream<String?> get wake => _controller.wake;

  /// Fires when the engine returns to the idle (asleep) state.
  Stream<void> get sleep => _controller.sleep;

  /// Fires with the outcome of each [enrollEnd]. Only meaningful when started
  /// with `enableSpeakerId`.
  Stream<EnrollmentResult> get enrolled => _controller.enrolled;

  bool get isRunning => _running;

  /// Whether the running engine was started with acoustic echo cancellation.
  /// When `false`, played TTS bleeds into the mic and is transcribed, so a
  /// consumer should suppress barge-in while speaking rather than letting a
  /// reply interrupt itself. Reflects the last [start].
  bool get aecEnabled => _aecEnabled;

  /// Validate the model directories, then load the models, open the audio
  /// devices and start the engine. Throws [VoiceException] on missing files or a
  /// startup failure. No-op if already running.
  Future<void> start(VoiceConfig config) async {
    if (_running) return;

    if (config.modelsDir.trim().isEmpty) {
      throw VoiceException('No models folder is set.');
    }

    final missing = <String>[
      // The shared Silero VAD sits at the models root, not in the ASR dir.
      if (!File(config.vadModelPath).existsSync()) config.vadModelPath,
      ...['tokens.txt']
          .map((f) => p.join(config.asrModelDir, f))
          .where((f) => !File(f).existsSync()),
      if (config.isLocalTts)
        ...['model.onnx', 'tokens.txt']
            .map((f) => p.join(config.ttsModelDir, f))
            .where((f) => !File(f).existsSync()),
      // Speaker verification needs its embedding model when enabled.
      if (config.enableSpeakerId && !File(config.speakerModelPath).existsSync())
        config.speakerModelPath,
    ];

    // The Volcengine backend needs credentials instead of model files.
    if (config.isVolcengineTts) {
      if (config.ttsApiKey.trim().isEmpty) {
        throw VoiceException(
          'Online TTS is selected but the API key is empty.',
        );
      }
      if (config.ttsSpeaker.trim().isEmpty) {
        throw VoiceException(
          'Online TTS is selected but no voice (speaker) is set.',
        );
      }
    }
    // The OpenAI HTTP backend requires a bearer key (the public API rejects
    // unauthenticated requests).
    if (config.isOpenaiTts && config.ttsApiKey.trim().isEmpty) {
      throw VoiceException('OpenAI TTS is selected but the API key is empty.');
    }
    // SenseVoice ships as either fp32 (`model.onnx`) or int8
    // (`model.int8.onnx`); require at least one to be present.
    final hasAsrModel = [
      'model.onnx',
      'model.int8.onnx',
    ].any((f) => File(p.join(config.asrModelDir, f)).existsSync());
    if (!hasAsrModel) {
      missing.add(p.join(config.asrModelDir, 'model.onnx'));
    }
    // Wake-word gating needs the streaming keyword-spotter model plus a
    // tokenized `keywords.txt` (the wake phrases) alongside it.
    if (config.enableWake) {
      missing.addAll(
        [
              'encoder.onnx',
              'decoder.onnx',
              'joiner.onnx',
              'tokens.txt',
              'keywords.txt',
            ]
            .map((f) => p.join(config.kwsModelDir, f))
            .where((f) => !File(f).existsSync()),
      );
    }
    if (missing.isNotEmpty) {
      throw VoiceException('Missing model files:\n${missing.join('\n')}');
    }

    _controller.init();
    try {
      await _controller.open(config.toEngineConfig());
    } on VoiceEngineException catch (e) {
      throw VoiceException(e.message);
    }
    _running = true;
    _aecEnabled = config.enableAec;
    logInfo('engine running (models=${config.modelsDir})');
  }

  /// Stop the engine and close the audio devices, keeping it ready for a fast
  /// restart.
  Future<void> stop() async {
    if (!_running) return;
    _running = false;
    await _controller.close();
    logInfo('engine stopped');
  }

  /// Speak a stream of text deltas (e.g. an LLM token stream) in real time.
  Future<void> speak(Stream<String> textDeltas) =>
      _controller.speak(textDeltas);

  /// Speak a single, already-complete string.
  Future<void> speakText(String text) => _controller.speakText(text);

  /// Barge-in: cancel current speech and discard queued/in-flight audio.
  Future<void> stopSpeaking() => _controller.stop();

  /// Begin capturing the enrolled voice: the engine accumulates mic audio (and
  /// pauses ASR) until [enrollEnd]. No-op unless started with `enableSpeakerId`.
  /// Have the user speak a short phrase, then call [enrollEnd].
  void enrollBegin() => _controller.enrollBegin();

  /// Finish enrollment: store the voiceprint under [name] (empty uses the default
  /// `'owner'`). The outcome arrives on [enrolled]. Call the pair a few times to
  /// enroll several samples for a more robust voiceprint.
  void enrollEnd([String name = '']) => _controller.enrollEnd(name);

  /// Forget every voiceprint under [name] (empty uses `'owner'`) to re-enroll.
  void enrollReset([String name = '']) => _controller.enrollReset(name);

  /// Put the engine back to sleep (listen only for the wake word). No-op unless
  /// started with `enableWake`.
  void sleepEngine() => _controller.sleepEngine();

  /// Force the engine awake without the wake word (manual "tap to talk").
  void wakeEngine() => _controller.wakeEngine();

  Future<void> dispose() async {
    _running = false;
    _controller.dispose();
  }
}
