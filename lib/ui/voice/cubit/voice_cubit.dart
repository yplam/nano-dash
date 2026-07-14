import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/voice_repository.dart';
import '../../../domain/models/voice.dart';
import '../../../extensions/loggable.dart';

part 'voice_state.dart';

/// Projects [VoiceRepository]'s streams into the state the voice UI renders.
class VoiceCubit extends Cubit<VoiceState> with Loggable {
  VoiceCubit(this._repository)
    : super(VoiceState(settings: _repository.config)) {
    _statusSub = _repository.statusChanges.listen((status) {
      if (isClosed) return;
      emit(
        status == VoiceStatus.error
            ? state.copyWith(status: status, error: _repository.error)
            : state.copyWith(status: status, clearError: true),
      );
    });
    _speakingSub = _repository.speaking.listen((speaking) {
      if (isClosed) return;
      emit(state.copyWith(speaking: speaking));
    });
    _transcriptSub = _repository.transcripts.listen((transcript) {
      if (isClosed) return;
      emit(state.copyWith(lastTranscript: transcript));
    });
    _enrolledSub = _repository.enrolled.listen((result) {
      if (isClosed) return;
      emit(
        state.copyWith(
          enrolling: false,
          enrollCount: result.count,
          enrollOk: result.ok,
          enrollMessage: result.message,
        ),
      );
    });
  }

  final VoiceRepository _repository;

  late final StreamSubscription<VoiceStatus> _statusSub;
  late final StreamSubscription<bool> _speakingSub;
  late final StreamSubscription<VoiceTranscript> _transcriptSub;
  late final StreamSubscription<EnrollmentResult> _enrolledSub;

  /// Whether we powered the engine on ourselves just so the user could record a
  /// voiceprint from the settings sheet. Set when [startEnroll] opens a closed
  /// engine; [endEnrollSession] closes it again when the sheet is dismissed.
  bool _autoStartedForEnroll = false;

  @override
  String get logIdentifier => '[VoiceCubit]';

  /// Open the engine if it is closed, close it if it is open.
  Future<void> toggle() =>
      state.status.isOpen ? _repository.disable() : _repository.enable();

  /// Force a wake-gated engine awake without the wake word ("tap to talk").
  void wakeNow() => _repository.wakeNow();

  /// Send a wake-gated engine back to sleep.
  void sleepNow() => _repository.sleepNow();

  /// Persist edited settings.
  Future<void> updateSettings(VoiceSettings settings) async {
    if (settings == state.settings) return;
    emit(state.copyWith(settings: settings));
    await _repository.save(settings);
  }

  /// Begin capturing a voiceprint, powering the mic on first if it is off. When
  /// the engine was closed we open it (a few seconds, [VoiceStatus.starting])
  /// and remember we did so, so [endEnrollSession] can close it again once the
  /// settings sheet is dismissed. Pair with [stopEnroll] once the user has
  /// spoken. No-op while a capture or a start is already in flight.
  Future<void> startEnroll() async {
    if (state.enrolling || state.status == VoiceStatus.starting) return;
    if (!state.status.isOpen) {
      _autoStartedForEnroll = true;
      await _repository.enable();
      if (isClosed) return;
      // The engine failed to open (status is now error); leave it be.
      if (!state.status.isOpen) {
        _autoStartedForEnroll = false;
        return;
      }
    }
    emit(state.copyWith(enrolling: true));
    _repository.enrollBegin();
  }

  /// Close the engine if the last enrollment session opened it. Call when the
  /// voice settings sheet is dismissed. A no-op when the user had the mic on
  /// before recording — we only undo what we started.
  Future<void> endEnrollSession() async {
    if (!_autoStartedForEnroll) return;
    _autoStartedForEnroll = false;
    await _repository.disable();
  }

  /// Finish the capture started by [startEnroll]; the outcome (sample count or a
  /// failure) lands back in the state via the engine's `enrolled` event.
  void stopEnroll() {
    if (!state.enrolling) return;
    _repository.enrollEnd();
  }

  /// Forget the enrolled voiceprint so it can be recorded again.
  void forgetVoiceprint() {
    _repository.enrollReset();
    emit(state.copyWith(enrolling: false, clearEnroll: true));
  }

  @override
  Future<void> close() async {
    await _statusSub.cancel();
    await _speakingSub.cancel();
    await _transcriptSub.cancel();
    await _enrolledSub.cancel();
    return super.close();
  }
}
