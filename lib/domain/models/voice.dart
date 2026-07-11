import 'json_model.dart';

/// The lifecycle of the voice engine, as one value for the UI to switch on.
///
/// The engine itself has three states — closed, asleep (only the keyword
/// spotter runs) and awake (ASR runs) — but opening it takes seconds, and a
/// failed open must be visible.
enum VoiceStatus {
  /// The engine is closed; the microphone is released.
  off,

  /// `ve_open` is in flight: models are loading and the audio devices are being
  /// opened. Can take several seconds.
  starting,

  /// Open but asleep: only the keyword spotter runs, waiting for the wake word.
  /// A wake-gated engine sits here until woken.
  idle,

  /// Open and awake: the VAD and ASR are running and producing transcripts.
  listening,

  /// The last attempt to open the engine failed (see `VoiceRepository.error`).
  error;

  /// Whether the engine holds the microphone.
  bool get isOpen => this == idle || this == listening;
}

/// The user-facing, persisted configuration for the voice module: the single
/// on-disk [modelsDir] (with its `asr/`, `tts/` and `kws/` subfolders) plus the
/// recognizer and TTS options.
class VoiceSettings implements JsonModel {
  const VoiceSettings({
    this.modelsDir = '',
    this.language = 'auto',
    this.sid = 0,
    this.speed = 1.0,
    this.enableAec = true,
    this.enableWake = true,
    this.ttsBackend = 'local',
    this.ttsApiKey = '',
    this.ttsResourceId = '',
    this.ttsSpeaker = '',
    this.ttsModel = '',
    this.ttsBaseUrl = '',
    this.ttsLanguage = '',
    this.ttsInstructions = '',
    this.ttsProxy = '',
  });

  /// Root folder with the `asr/`, `tts/` and `kws/` model subfolders.
  final String modelsDir;
  final String language;
  final int sid;
  final double speed;
  final bool enableAec;

  /// Gate the ASR behind a wake word: the engine opens asleep and runs only the
  /// keyword-spotter until the wake phrase is heard.
  final bool enableWake;

  /// TTS backend: `'local'` (on-disk VITS/Kokoro), `'volcengine'` (Volcengine
  /// online WebSocket streaming TTS), `'vllm'` (a vLLM-Omni / OpenAI-compatible
  /// `/v1/audio/speech/stream` WebSocket), or `'openai'` (the OpenAI HTTP API
  /// `POST /v1/audio/speech`).
  final String ttsBackend;

  /// Online TTS API key. `X-Api-Key` for Volcengine; `Authorization: Bearer` for
  /// the vLLM and OpenAI backends (empty omits it).
  final String ttsApiKey;

  /// Volcengine TTS resource id (`X-Api-Resource-Id`); empty applies the default.
  final String ttsResourceId;

  /// Online TTS voice id (Volcengine speaker, e.g.
  /// `zh_female_gaolengyujie_uranus_bigtts`; vLLM voice, e.g. `vivian`; OpenAI
  /// voice, e.g. `alloy`).
  final String ttsSpeaker;

  /// Online TTS optional model version/id (e.g. `gpt-4o-mini-tts` for OpenAI).
  final String ttsModel;

  /// Online TTS server base URL (e.g. `http://localhost:8091` for vLLM,
  /// `https://api.openai.com/v1` for OpenAI).
  final String ttsBaseUrl;

  /// vLLM-Omni TTS language steer (e.g. `English`); empty omits it.
  final String ttsLanguage;

  /// Online TTS voice style/emotion instructions; empty omits them.
  final String ttsInstructions;

  /// Optional HTTP proxy for the online TTS connection (e.g.
  /// `http://127.0.0.1:1080`); empty connects directly.
  final String ttsProxy;

  /// Whether the Volcengine online WebSocket TTS backend is selected.
  bool get isVolcengineTts => ttsBackend == 'volcengine';

  /// Whether the vLLM-Omni online WebSocket TTS backend is selected.
  bool get isVllmTts => ttsBackend == 'vllm';

  /// Whether the OpenAI HTTP TTS backend is selected.
  bool get isOpenaiTts => ttsBackend == 'openai';

  /// Whether the local, on-disk TTS model backend is selected.
  bool get isLocalTts => ttsBackend == 'local';

  /// Whether no synthesizer is selected: the agent still listens and shows its
  /// replies, but speaks nothing and needs no TTS model or credentials.
  bool get isNoTts => ttsBackend == 'none';

  /// Whether an online (network) synthesizer is selected. These name their voice
  /// and, some, a model — unlike the local backend (numeric speaker id) and the
  /// `'none'` backend (no synthesizer at all).
  bool get isOnlineTts => isOpenaiTts || isVllmTts || isVolcengineTts;

  /// Whether speech synthesis is enabled (any backend other than `'none'`).
  bool get ttsEnabled => ttsBackend != 'none';

  /// The backend ids the settings UI offers, in display order. `'none'` is the
  /// text-only mode; the rest are real synthesizers.
  static const List<String> ttsBackends = [
    'none',
    'local',
    'openai',
    'volcengine',
    'vllm',
  ];

  /// The SenseVoice language steers the settings UI offers, in display order.
  static const List<String> languages = ['auto', 'zh', 'en', 'ja', 'ko', 'yue'];

  VoiceSettings copyWith({
    String? modelsDir,
    String? language,
    int? sid,
    double? speed,
    bool? enableAec,
    bool? enableWake,
    String? ttsBackend,
    String? ttsApiKey,
    String? ttsResourceId,
    String? ttsSpeaker,
    String? ttsModel,
    String? ttsBaseUrl,
    String? ttsLanguage,
    String? ttsInstructions,
    String? ttsProxy,
  }) {
    return VoiceSettings(
      modelsDir: modelsDir ?? this.modelsDir,
      language: language ?? this.language,
      sid: sid ?? this.sid,
      speed: speed ?? this.speed,
      enableAec: enableAec ?? this.enableAec,
      enableWake: enableWake ?? this.enableWake,
      ttsBackend: ttsBackend ?? this.ttsBackend,
      ttsApiKey: ttsApiKey ?? this.ttsApiKey,
      ttsResourceId: ttsResourceId ?? this.ttsResourceId,
      ttsSpeaker: ttsSpeaker ?? this.ttsSpeaker,
      ttsModel: ttsModel ?? this.ttsModel,
      ttsBaseUrl: ttsBaseUrl ?? this.ttsBaseUrl,
      ttsLanguage: ttsLanguage ?? this.ttsLanguage,
      ttsInstructions: ttsInstructions ?? this.ttsInstructions,
      ttsProxy: ttsProxy ?? this.ttsProxy,
    );
  }

  factory VoiceSettings.fromJson(Map<String, Object?> json) => VoiceSettings(
    modelsDir: json['modelsDir'] as String? ?? '',
    language: json['language'] as String? ?? 'auto',
    sid: (json['sid'] as num?)?.toInt() ?? 0,
    speed: (json['speed'] as num?)?.toDouble() ?? 1.0,
    enableAec: json['enableAec'] != false,
    enableWake: json['enableWake'] != false,
    ttsBackend: json['ttsBackend'] as String? ?? 'local',
    ttsApiKey: json['ttsApiKey'] as String? ?? '',
    ttsResourceId: json['ttsResourceId'] as String? ?? '',
    ttsSpeaker: json['ttsSpeaker'] as String? ?? '',
    ttsModel: json['ttsModel'] as String? ?? '',
    ttsBaseUrl: json['ttsBaseUrl'] as String? ?? '',
    ttsLanguage: json['ttsLanguage'] as String? ?? '',
    ttsInstructions: json['ttsInstructions'] as String? ?? '',
    ttsProxy: json['ttsProxy'] as String? ?? '',
  );

  @override
  Map<String, Object?> toJson() => {
    'modelsDir': modelsDir,
    'language': language,
    'sid': sid,
    'speed': speed,
    'enableAec': enableAec,
    'enableWake': enableWake,
    'ttsBackend': ttsBackend,
    'ttsApiKey': ttsApiKey,
    'ttsResourceId': ttsResourceId,
    'ttsSpeaker': ttsSpeaker,
    'ttsModel': ttsModel,
    'ttsBaseUrl': ttsBaseUrl,
    'ttsLanguage': ttsLanguage,
    'ttsInstructions': ttsInstructions,
    'ttsProxy': ttsProxy,
  };

  @override
  bool operator ==(Object other) =>
      other is VoiceSettings &&
      other.modelsDir == modelsDir &&
      other.language == language &&
      other.sid == sid &&
      other.speed == speed &&
      other.enableAec == enableAec &&
      other.enableWake == enableWake &&
      other.ttsBackend == ttsBackend &&
      other.ttsApiKey == ttsApiKey &&
      other.ttsResourceId == ttsResourceId &&
      other.ttsSpeaker == ttsSpeaker &&
      other.ttsModel == ttsModel &&
      other.ttsBaseUrl == ttsBaseUrl &&
      other.ttsLanguage == ttsLanguage &&
      other.ttsInstructions == ttsInstructions &&
      other.ttsProxy == ttsProxy;

  @override
  int get hashCode => Object.hash(
    modelsDir,
    language,
    sid,
    speed,
    enableAec,
    enableWake,
    ttsBackend,
    ttsApiKey,
    ttsResourceId,
    ttsSpeaker,
    ttsModel,
    ttsBaseUrl,
    ttsLanguage,
    ttsInstructions,
    ttsProxy,
  );
}

const voiceSettingsKey = SettingKey<VoiceSettings>(
  'voice_config_v3',
  VoiceSettings.fromJson,
  defaults: VoiceSettings(),
);
