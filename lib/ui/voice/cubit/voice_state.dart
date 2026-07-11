part of 'voice_cubit.dart';

/// View state for the voice module and the shared [VoiceMicButton].
class VoiceState {
  const VoiceState({
    required this.settings,
    this.status = VoiceStatus.off,
    this.speaking = false,
    this.lastTranscript,
    this.error,
  });

  /// The persisted settings, mirrored so the settings sheet rebuilds on edit.
  final VoiceSettings settings;

  final VoiceStatus status;

  /// Whether synthesized speech is playing right now.
  final bool speaking;

  /// The most recent recognized utterance, or `null` if none this run.
  final VoiceTranscript? lastTranscript;

  /// Why the last enable attempt failed; non-null only when [status] is
  /// [VoiceStatus.error].
  final String? error;

  VoiceState copyWith({
    VoiceSettings? settings,
    VoiceStatus? status,
    bool? speaking,
    VoiceTranscript? lastTranscript,
    String? error,
    bool clearError = false,
  }) {
    return VoiceState(
      settings: settings ?? this.settings,
      status: status ?? this.status,
      speaking: speaking ?? this.speaking,
      lastTranscript: lastTranscript ?? this.lastTranscript,
      error: clearError ? null : (error ?? this.error),
    );
  }
}
