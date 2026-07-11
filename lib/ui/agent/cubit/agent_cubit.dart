import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/agent_repository.dart';
import '../../../domain/models/agent.dart';

part 'agent_state.dart';

/// Projects [AgentRepository]'s streams into the state the agent UI renders.
/// It holds no agent state of its own.
class AgentCubit extends Cubit<AgentState> {
  AgentCubit(this._repository)
    : super(
        AgentState(
          settings: _repository.config,
          phase: _repository.phase,
          reply: _repository.lastReply,
        ),
      ) {
    _replySub = _repository.replies.listen((reply) {
      if (isClosed) return;
      emit(state.copyWith(reply: reply));
    });
    _phaseSub = _repository.phaseChanges.listen((phase) {
      if (isClosed) return;
      emit(state.copyWith(phase: phase));
    });
  }

  final AgentRepository _repository;

  late final StreamSubscription<AgentReply> _replySub;
  late final StreamSubscription<AgentPhase> _phaseSub;

  /// Stop the current answer without closing the voice engine.
  Future<void> stop() => _repository.stop();

  /// Persist edited settings. They are read per question, so they apply from
  /// the next utterance.
  Future<void> updateSettings(AgentSettings settings) async {
    if (settings == state.settings) return;
    emit(state.copyWith(settings: settings));
    await _repository.save(settings);
  }

  @override
  Future<void> close() async {
    await _replySub.cancel();
    await _phaseSub.cancel();
    return super.close();
  }
}
