part of 'voice_cubit.dart';

/// View state for the voice module and the shared [VoiceMicButton].
class VoiceState {
  const VoiceState({
    required this.settings,
    this.status = VoiceStatus.off,
    this.speaking = false,
    this.lastTranscript,
    this.error,
    this.enrolling = false,
    this.enrollCount,
    this.enrollMessage,
    this.enrollOk = true,
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

  /// Whether a voiceprint capture is in progress (between the record toggle's
  /// start and stop). Reset when the enrollment result arrives.
  final bool enrolling;

  /// Recordings enrolled after the last [VoiceCubit.stopEnroll] this session, or
  /// `null` before any enrollment has completed. There is no way to read the
  /// persisted count from the engine, so this reflects only this session.
  final int? enrollCount;

  /// The failure reason from the last enrollment, or `null` on success.
  final String? enrollMessage;

  /// Whether the last enrollment succeeded.
  final bool enrollOk;

  VoiceState copyWith({
    VoiceSettings? settings,
    VoiceStatus? status,
    bool? speaking,
    VoiceTranscript? lastTranscript,
    String? error,
    bool clearError = false,
    bool? enrolling,
    int? enrollCount,
    String? enrollMessage,
    bool? enrollOk,
    bool clearEnroll = false,
  }) {
    return VoiceState(
      settings: settings ?? this.settings,
      status: status ?? this.status,
      speaking: speaking ?? this.speaking,
      lastTranscript: lastTranscript ?? this.lastTranscript,
      error: clearError ? null : (error ?? this.error),
      enrolling: enrolling ?? this.enrolling,
      enrollCount: clearEnroll ? null : (enrollCount ?? this.enrollCount),
      enrollMessage: clearEnroll ? null : (enrollMessage ?? this.enrollMessage),
      enrollOk: clearEnroll ? true : (enrollOk ?? this.enrollOk),
    );
  }
}
