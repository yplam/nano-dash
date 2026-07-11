import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/models/agent.dart';
import '../../l10n/app_localizations.dart';
import '../agent/cubit/agent_cubit.dart';
import '../voice/cubit/voice_cubit.dart';
import '../voice/widgets/voice_mic_button.dart';

/// The shared assistant control: [VoiceMicButton] wrapped with the agent's
/// state, so one widget shows both the voice engine's lifecycle *and* what the
/// LLM is doing between hearing an utterance and speaking the answer.
///
/// The mic button is reused verbatim — it still owns tap (toggle the engine)
/// and long-press (wake). Layered around it:
///  * a progress ring while the agent is busy ([AgentPhase.answering] /
///    [AgentPhase.working] / [AgentPhase.askingUser]) — the silent "thinking"
///    window the mic button alone can't show, since the engine sits idle there;
///  * a small stop badge that barges in on the current answer without closing
///    the engine (the mic keeps listening), via [AgentCubit.stop].
///
class VoiceAgentButton extends StatelessWidget {
  const VoiceAgentButton({super.key, required this.diameter});

  /// Diameter of the inner mic button, in the panel's pixels. The widget's own
  /// footprint is [kBoxScale] times this.
  final double diameter;

  /// The reserved box is this multiple of [diameter], leaving a margin for the
  /// ring and the stop badge (and clearing the mic's own listening halo).
  static const double kBoxScale = 1.3;

  @override
  Widget build(BuildContext context) {
    final d = diameter;
    return BlocBuilder<VoiceCubit, VoiceState>(
      buildWhen: (prev, curr) =>
          prev.settings.modelsDir.trim().isEmpty !=
          curr.settings.modelsDir.trim().isEmpty,
      builder: (context, voice) {
        if (voice.settings.modelsDir.trim().isEmpty) {
          return const SizedBox.shrink();
        }
        return SizedBox(
          width: d * kBoxScale,
          height: d * kBoxScale,
          child: BlocBuilder<AgentCubit, AgentState>(
            // Only the phase changes the chrome; a streaming reply's text
            // deltas are the dialogue box's business, not this button's.
            buildWhen: (prev, curr) => prev.phase != curr.phase,
            builder: (context, agent) {
              final ring = _RingVisual.of(
                agent.phase,
                Theme.of(context).colorScheme,
              );
              return Stack(
                alignment: Alignment.center,
                children: [
                  // The ring exists only while busy, so nothing repaints on an
                  // idle panel (CircularProgressIndicator animates itself).
                  if (ring != null)
                    SizedBox(
                      width: d * 1.18,
                      height: d * 1.18,
                      child: CircularProgressIndicator(
                        strokeWidth: d * 0.055,
                        color: ring,
                      ),
                    ),
                  VoiceMicButton(diameter: d),
                  if (ring != null)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: _StopBadge(
                        diameter: d * 0.34,
                        onTap: () => context.read<AgentCubit>().stop(),
                      ),
                    ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

/// The ring colour for one [AgentPhase], or `null` when the agent is idle.
class _RingVisual {
  static Color? of(AgentPhase phase, ColorScheme scheme) => switch (phase) {
    AgentPhase.idle => null,
    AgentPhase.answering => scheme.secondary,
    AgentPhase.working => scheme.tertiary,
    AgentPhase.askingUser => scheme.primary,
  };
}

/// The small round "stop the current answer" control shown over the mic's
/// lower-right while the agent is busy.
class _StopBadge extends StatelessWidget {
  const _StopBadge({required this.diameter, required this.onTap});

  final double diameter;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final d = diameter;
    return Tooltip(
      message: AppLocalizations.of(context).agentStop,
      child: Material(
        color: scheme.surfaceContainerHighest,
        shape: const CircleBorder(),
        elevation: 3,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: d,
            height: d,
            child: Icon(
              Icons.stop_rounded,
              size: d * 0.6,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
