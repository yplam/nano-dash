part of 'agent_cubit.dart';

/// View state for the agent module.
class AgentState {
  const AgentState({
    required this.settings,
    this.phase = AgentPhase.idle,
    this.reply,
  });

  /// The persisted settings, mirrored so the settings sheet rebuilds on edit.
  final AgentSettings settings;

  /// What the agent is doing right now.
  final AgentPhase phase;

  /// The latest (possibly still streaming) assistant reply, or `null` if none
  /// this run.
  final AgentReply? reply;

  AgentState copyWith({
    AgentSettings? settings,
    AgentPhase? phase,
    AgentReply? reply,
  }) {
    return AgentState(
      settings: settings ?? this.settings,
      phase: phase ?? this.phase,
      reply: reply ?? this.reply,
    );
  }
}
