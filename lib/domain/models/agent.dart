import 'json_model.dart';

/// What the agent is doing right now, as one value for the UI to switch on.
enum AgentPhase {
  /// No question in flight.
  idle,

  /// The light model is streaming an answer (or deciding to escalate).
  answering,

  /// The orchestrator (pro model) is planning, calling tools, or streaming
  /// its answer.
  working,

  /// The orchestrator asked the user a question and is waiting for the next
  /// utterance (or a timeout).
  askingUser,
}

/// One assistant reply as the dialogue UI sees it: the text accumulated so far
/// while streaming, then the full text once [done].
class AgentReply {
  const AgentReply({
    required this.text,
    required this.done,
    required this.started,
    required this.updated,
  });

  final String text;

  /// `false` while deltas are still streaming in.
  final bool done;

  /// When this reply's question started — stable across the streaming updates.
  final DateTime started;

  /// When the text last grew (or the reply finished), so a remounted page can
  /// honor a display dwell measured from the reply itself.
  final DateTime updated;
}

/// One turn of the rolling conversation history the agent keeps in memory.
/// Only plain user/assistant text.
class AgentTurn {
  const AgentTurn({required this.fromUser, required this.text});

  final bool fromUser;
  final String text;
}

/// The user-facing, persisted configuration for the agent module: one
/// OpenAI-compatible endpoint (key, base URL, optional HTTP proxy) and the two
/// model names — a light model that answers or routes, and a pro model that
/// orchestrates tools for complex questions.
class AgentSettings implements JsonModel {
  const AgentSettings({
    this.enabled = false,
    this.apiKey = '',
    this.baseUrl = 'https://api.openai.com/v1',
    this.proxy = '',
    this.lightModel = 'gpt-4o-mini',
    this.proModel = 'gpt-4o',
    this.persona = '',
  });

  /// Master switch; with it off, transcripts are ignored entirely.
  final bool enabled;

  /// Bearer key for the OpenAI-compatible endpoint.
  final String apiKey;

  /// OpenAI-compatible base URL (e.g. `https://api.openai.com/v1`,
  /// `https://openrouter.ai/api/v1`, `http://localhost:11434/v1`).
  final String baseUrl;

  /// Optional HTTP proxy for the LLM connection (e.g.
  /// `http://127.0.0.1:1080`); empty connects directly.
  final String proxy;

  /// Model that hears every question first: answers simple ones directly and
  /// escalates the rest.
  final String lightModel;

  /// Model behind the orchestrator: plans, calls tools, asks the user.
  final String proModel;

  /// Extra system-prompt text describing the assistant's character; empty
  /// keeps the built-in default.
  final String persona;

  /// Whether the agent has everything it needs to answer.
  bool get isConfigured =>
      enabled &&
      apiKey.trim().isNotEmpty &&
      baseUrl.trim().isNotEmpty &&
      lightModel.trim().isNotEmpty &&
      proModel.trim().isNotEmpty;

  AgentSettings copyWith({
    bool? enabled,
    String? apiKey,
    String? baseUrl,
    String? proxy,
    String? lightModel,
    String? proModel,
    String? persona,
  }) {
    return AgentSettings(
      enabled: enabled ?? this.enabled,
      apiKey: apiKey ?? this.apiKey,
      baseUrl: baseUrl ?? this.baseUrl,
      proxy: proxy ?? this.proxy,
      lightModel: lightModel ?? this.lightModel,
      proModel: proModel ?? this.proModel,
      persona: persona ?? this.persona,
    );
  }

  factory AgentSettings.fromJson(Map<String, Object?> json) => AgentSettings(
    enabled: json['enabled'] == true,
    apiKey: json['apiKey'] as String? ?? '',
    baseUrl: json['baseUrl'] as String? ?? 'https://api.openai.com/v1',
    proxy: json['proxy'] as String? ?? '',
    lightModel: json['lightModel'] as String? ?? 'gpt-4o-mini',
    proModel: json['proModel'] as String? ?? 'gpt-4o',
    persona: json['persona'] as String? ?? '',
  );

  @override
  Map<String, Object?> toJson() => {
    'enabled': enabled,
    'apiKey': apiKey,
    'baseUrl': baseUrl,
    'proxy': proxy,
    'lightModel': lightModel,
    'proModel': proModel,
    'persona': persona,
  };

  @override
  bool operator ==(Object other) =>
      other is AgentSettings &&
      other.enabled == enabled &&
      other.apiKey == apiKey &&
      other.baseUrl == baseUrl &&
      other.proxy == proxy &&
      other.lightModel == lightModel &&
      other.proModel == proModel &&
      other.persona == persona;

  @override
  int get hashCode => Object.hash(
    enabled,
    apiKey,
    baseUrl,
    proxy,
    lightModel,
    proModel,
    persona,
  );
}

/// Persistence handle for [AgentSettings].
const agentSettingsKey = SettingKey<AgentSettings>(
  'agent_config_v1',
  AgentSettings.fromJson,
  defaults: AgentSettings(),
);
