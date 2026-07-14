/// Pure-Dart types shared by the FFI ([voice_engine_controller_io.dart]) and
/// web-stub ([voice_engine_controller_stub.dart]) implementations of
/// [VoiceEngineController]. Kept free of `dart:ffi` so it imports cleanly on the
/// web.
library;

import 'package:flutter/foundation.dart';

/// Open-time configuration. Field names + defaults mirror the Rust
/// `EngineConfig`; [toJson] uses the snake_case keys it deserializes.
///
/// [asrModelDir] must contain `tokens.txt` and the SenseVoice model as
/// `model.onnx` or `model.int8.onnx` (fp32 preferred over the int8 build); the
/// Silero VAD is supplied separately via [vadModelPath].
/// [ttsModelDir] must contain a VITS or Kokoro model (`model.onnx`, `tokens.txt`,
/// plus a lexicon — the engine sniffs the family).
@immutable
class VoiceEngineConfig {
  const VoiceEngineConfig({
    required this.asrModelDir,
    this.vadModelPath = '',
    this.language = 'auto',
    this.useItn = true,
    this.ttsBackend = 'local',
    required this.ttsModelDir,
    this.ttsApiKey = '',
    this.ttsResourceId = '',
    this.ttsEndpoint = '',
    this.ttsSpeaker = '',
    this.ttsModel = '',
    this.ttsBaseUrl = '',
    this.ttsLanguage = '',
    this.ttsInstructions = '',
    this.ttsProxy = '',
    this.sid = 0,
    this.speed = 1.0,
    this.streamDelayMs,
    this.enableAec = true,
    this.energyGate = 0.0,
    this.enableWake = false,
    this.kwsModelDir = '',
    this.wakeKeywords = '',
    this.wakeScore = 0.0,
    this.wakeThreshold = 0.0,
    this.wakeAckPhrases = const [],
    this.speakerModelPath = '',
    this.speakerProfilePath = '',
    this.speakerVerify = false,
    this.speakerThreshold = 0.0,
  });

  /// Folder with the SenseVoice ASR model files (`model.onnx`/`model.int8.onnx`,
  /// `tokens.txt`).
  final String asrModelDir;

  /// Path to the Silero VAD model (`silero_vad.onnx`). The VAD is not an ASR
  /// model, so it can live outside [asrModelDir]; empty falls back to
  /// `asrModelDir/silero_vad.onnx`.
  final String vadModelPath;

  /// SenseVoice language steer: `'auto'`, `'zh'`, `'en'`, `'ja'`, `'ko'`, `'yue'`.
  final String language;

  /// Inverse text normalization (digits, punctuation).
  final bool useItn;

  /// Which synthesizer to drive: `'local'` (VITS/Kokoro from [ttsModelDir]),
  /// `'volcengine'` (Volcengine WebSocket streaming TTS), `'vllm'` (a vLLM-Omni /
  /// OpenAI-compatible `/v1/audio/speech/stream` WebSocket), or `'openai'` (the
  /// OpenAI HTTP API `POST /v1/audio/speech`).
  final String ttsBackend;

  /// Folder with the VITS/Kokoro TTS model. Only used when [ttsBackend] is
  /// `'local'`.
  final String ttsModelDir;

  /// Online TTS API key. For `'volcengine'` it is the Volcengine `X-Api-Key`
  /// header; for `'vllm'`/`'openai'` it is sent as `Authorization: Bearer` (empty
  /// omits it).
  final String ttsApiKey;

  /// Online WebSocket TTS — `X-Api-Resource-Id` header (model family); empty lets
  /// the engine apply its default. Only used when [ttsBackend] is `'volcengine'`.
  final String ttsResourceId;

  /// Online WebSocket TTS endpoint; empty lets the engine apply its default.
  /// Only used when [ttsBackend] is `'volcengine'`.
  final String ttsEndpoint;

  /// Online TTS voice/speaker id. For `'volcengine'` e.g.
  /// `zh_female_gaolengyujie_uranus_bigtts`; for `'vllm'` e.g. `vivian`; for
  /// `'openai'` e.g. `alloy` (empty falls back to the engine default). Used when
  /// [ttsBackend] is `'volcengine'`, `'vllm'`, or `'openai'`.
  final String ttsSpeaker;

  /// Online TTS optional `model` id. For `'volcengine'` the cloned-voice version;
  /// for `'vllm'` the served model id; for `'openai'` e.g. `gpt-4o-mini-tts`.
  /// Used when [ttsBackend] is `'volcengine'`, `'vllm'`, or `'openai'`.
  final String ttsModel;

  /// Online TTS server base URL. For `'vllm'` (e.g. `http://localhost:8091`) a
  /// `ws(s)://.../v1/audio/speech/stream` endpoint is derived; for `'openai'`
  /// (e.g. `https://api.openai.com/v1`) the `/audio/speech` endpoint is derived.
  /// Used when [ttsBackend] is `'vllm'` or `'openai'`.
  final String ttsBaseUrl;

  /// vLLM-Omni TTS language steer (Qwen3-TTS only, e.g. `English`); empty omits
  /// it. Only used when [ttsBackend] is `'vllm'`.
  final String ttsLanguage;

  /// Online TTS voice style/emotion instructions; empty omits them. Used when
  /// [ttsBackend] is `'vllm'` or `'openai'`.
  final String ttsInstructions;

  /// Optional HTTP proxy (e.g. `http://127.0.0.1:1080`) for the online TTS
  /// connection; empty connects directly. For `'vllm'` (WebSocket) the proxy
  /// must support `CONNECT`. Used when [ttsBackend] is `'vllm'` or `'openai'`.
  final String ttsProxy;

  /// Speaker id for multi-speaker local TTS models.
  final int sid;

  /// Speaking rate (larger is faster).
  final double speed;

  /// AEC render→capture delay hint (ms); `null` lets AEC3 estimate it.
  final int? streamDelayMs;

  /// Run the webrtc AEC on the mic before ASR (disable for A/B testing).
  final bool enableAec;

  /// Post-AEC RMS gate: while > 0, mic frames quieter than this are zeroed
  /// before the VAD, suppressing low-level echo residue. `0` disables it.
  final double energyGate;

  /// Gate the ASR behind a wake word. When `true` the engine starts asleep and
  /// only runs the keyword-spotter until [wakeKeywords] is heard. `false` keeps
  /// the always-transcribing behavior.
  final bool enableWake;

  /// Folder with the keyword-spotter model (`encoder/decoder/joiner.onnx`,
  /// `tokens.txt`). Required when [enableWake].
  final String kwsModelDir;

  /// Inline, tokenized wake phrase(s); empty falls back to a `keywords.txt` in
  /// [kwsModelDir].
  final String wakeKeywords;

  /// KWS boost score; `0` keeps the engine default.
  final double wakeScore;

  /// KWS detection threshold; `0` keeps the engine default.
  final double wakeThreshold;

  /// Canned greetings spoken the instant the wake word fires. The local TTS
  /// backend pre-synthesizes and caches them at open (which also warms up ORT),
  /// then plays one round-robin with no synthesis latency; the chosen text comes
  /// back on the [VoiceEngineController.wake] stream. Only honored with the local
  /// backend + [enableWake]; empty disables the greeting.
  final List<String> wakeAckPhrases;

  /// Path to a speaker-embedding ONNX model (e.g. a 3D-Speaker CAM++ model).
  /// Empty (the default) disables speaker verification entirely. When set, the
  /// model is loaded so enrollment ([VoiceEngineController.enrollBegin]) can run
  /// even before [speakerVerify] is turned on.
  final String speakerModelPath;

  /// JSON file the enrolled voiceprint(s) are persisted to. Empty keeps
  /// enrollment in memory only (lost on close). Ignored when [speakerModelPath]
  /// is empty.
  final String speakerProfilePath;

  /// Enforce the speaker gate: drop transcripts whose speaker doesn't match an
  /// enrolled voice. `false` (the default) still loads the model (so enrollment
  /// works) but accepts every voice. Ignored when [speakerModelPath] is empty.
  final bool speakerVerify;

  /// Cosine-similarity acceptance threshold in `[0, 1]`; higher is stricter.
  /// `0` (the default) uses the engine default (0.5).
  final double speakerThreshold;

  Map<String, dynamic> toJson() => {
    'asr_model_dir': asrModelDir,
    'vad_model': vadModelPath,
    'language': language,
    'use_itn': useItn,
    'tts_backend': ttsBackend,
    'tts_model_dir': ttsModelDir,
    'volcengine_tts': {
      'api_key': ttsApiKey,
      'resource_id': ttsResourceId,
      'endpoint': ttsEndpoint,
      'speaker': ttsSpeaker,
      'model': ttsModel,
    },
    'vllm_tts': {
      'base_url': ttsBaseUrl,
      'api_key': ttsApiKey,
      'model': ttsModel,
      'voice': ttsSpeaker,
      'language': ttsLanguage,
      'instructions': ttsInstructions,
      'proxy': ttsProxy,
    },
    'openai_tts': {
      'base_url': ttsBaseUrl,
      'api_key': ttsApiKey,
      'model': ttsModel,
      'voice': ttsSpeaker,
      'instructions': ttsInstructions,
      'proxy': ttsProxy,
    },
    'sid': sid,
    'speed': speed,
    'stream_delay_ms': streamDelayMs,
    'enable_aec': enableAec,
    'energy_gate': energyGate,
    'enable_wake': enableWake,
    'kws_model_dir': kwsModelDir,
    'wake_keywords': wakeKeywords,
    'wake_score': wakeScore,
    'wake_threshold': wakeThreshold,
    'wake_ack_phrases': wakeAckPhrases,
    'speaker_model': speakerModelPath,
    'speaker_profile': speakerProfilePath,
    'speaker_verify': speakerVerify,
    'speaker_threshold': speakerThreshold,
  };
}

/// Outcome of an enrollment attempt, pushed after [VoiceEngineController.enrollEnd].
@immutable
class EnrollmentResult {
  const EnrollmentResult({required this.ok, required this.count, this.message});

  /// Whether the voiceprint was captured and stored.
  final bool ok;

  /// How many recordings are now enrolled under the name (0 on failure). Capture
  /// a few for a more robust voiceprint.
  final int count;

  /// Failure reason when [ok] is false (e.g. audio too short); `null` on success.
  final String? message;

  @override
  String toString() => 'EnrollmentResult(ok: $ok, count: $count, message: $message)';
}

/// Thrown when a native call fails.
class VoiceEngineException implements Exception {
  VoiceEngineException(this.message);
  final String message;
  @override
  String toString() => 'VoiceEngineException: $message';
}

/// A recognized utterance pushed from the engine's ASR.
@immutable
class VoiceTranscript {
  VoiceTranscript(this.text, {DateTime? time}) : time = time ?? DateTime.now();

  final String text;
  final DateTime time;

  @override
  String toString() => 'VoiceTranscript($text)';
}
