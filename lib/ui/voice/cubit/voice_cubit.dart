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
  }

  final VoiceRepository _repository;

  late final StreamSubscription<VoiceStatus> _statusSub;
  late final StreamSubscription<bool> _speakingSub;
  late final StreamSubscription<VoiceTranscript> _transcriptSub;

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

  @override
  Future<void> close() async {
    await _statusSub.cancel();
    await _speakingSub.cancel();
    await _transcriptSub.cancel();
    return super.close();
  }
}
