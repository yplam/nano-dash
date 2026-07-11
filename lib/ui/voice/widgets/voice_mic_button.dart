import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/models/voice.dart';
import '../cubit/voice_cubit.dart';

/// The shared voice control: a round mic button any panel page can drop in to
/// open and close the voice engine.
///
/// Tap toggles the engine on and off. When the engine is open and wake-gated it
/// sits asleep on the keyword spotter ([VoiceStatus.idle]); a long-press forces
/// it awake without the wake word ("tap to talk"). A tap while it is speaking
/// still closes it, which also stops the reply.
///
/// It renders nothing until [VoiceSettings.modelsDir] is set, since the engine
/// refuses to open without its models.
///
/// Everything is sized from [diameter] and nothing is read from `MediaQuery`, so
/// a panel page can drive it straight from its `PanelMetrics` and it renders at
/// the right size on the round ~360px LCD as well as on screen.
class VoiceMicButton extends StatefulWidget {
  const VoiceMicButton({super.key, required this.diameter});

  /// Outer diameter of the button, in the panel's pixels.
  final double diameter;

  @override
  State<VoiceMicButton> createState() => _VoiceMicButtonState();
}

class _VoiceMicButtonState extends State<VoiceMicButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncPulse(
      _MicVisual.of(
        context.read<VoiceCubit>().state,
        Theme.of(context).colorScheme,
      ).pulses,
    );
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  /// Run the halo only while the engine is actually hearing or speaking, so an
  /// idle panel isn't repainting forever.
  void _syncPulse(bool active) {
    if (active == _pulse.isAnimating) return;
    if (active) {
      _pulse.repeat();
    } else {
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final cubit = context.read<VoiceCubit>();
    final d = widget.diameter;

    // The pulse is driven from the listener, not the builder: starting or
    // stopping the controller notifies its AnimatedBuilder, which would be a
    // markNeedsBuild during build.
    return BlocConsumer<VoiceCubit, VoiceState>(
      listener: (context, state) =>
          _syncPulse(_MicVisual.of(state, scheme).pulses),
      builder: (context, state) {
        // Without a models folder every tap would only latch VoiceStatus.error,
        // so offer no button at all until one is chosen in settings.
        if (state.settings.modelsDir.trim().isEmpty) {
          return const SizedBox.shrink();
        }
        final visual = _MicVisual.of(state, scheme);
        return SizedBox(
          width: d,
          height: d,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // The halo grows past the button but paints beneath a circle that
              // stays exactly [diameter] wide, so the layout box never changes.
              if (visual.pulses)
                AnimatedBuilder(
                  animation: _pulse,
                  builder: (context, _) {
                    final t = _pulse.value;
                    return Container(
                      width: d * (1 + 0.18 * t),
                      height: d * (1 + 0.18 * t),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: visual.background.withValues(
                          alpha: 0.35 * (1 - t),
                        ),
                      ),
                    );
                  },
                ),
              SizedBox(
                width: d,
                height: d,
                child: Material(
                  color: visual.background,
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: cubit.toggle,
                    // Only a wake-gated, sleeping engine has anything to wake.
                    onLongPress: state.status == VoiceStatus.idle
                        ? cubit.wakeNow
                        : null,
                    child: Center(
                      child: visual.busy
                          ? SizedBox(
                              width: d * 0.4,
                              height: d * 0.4,
                              child: CircularProgressIndicator(
                                strokeWidth: d * 0.05,
                                color: visual.foreground,
                              ),
                            )
                          : Icon(
                              visual.icon,
                              size: d * 0.5,
                              color: visual.foreground,
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// How the button paints for one [VoiceState].
class _MicVisual {
  const _MicVisual({
    required this.icon,
    required this.background,
    required this.foreground,
    this.busy = false,
    this.pulses = false,
  });

  final IconData icon;
  final Color background;
  final Color foreground;

  /// Show a spinner instead of [icon] — the engine is loading its models.
  final bool busy;

  /// Whether the halo animates.
  final bool pulses;

  factory _MicVisual.of(VoiceState state, ColorScheme scheme) {
    // Speaking is orthogonal to the lifecycle: an open engine that is playing a
    // reply reads as "speaking" whether or not the ASR happens to be awake.
    if (state.speaking && state.status.isOpen) {
      return _MicVisual(
        icon: Icons.graphic_eq,
        background: scheme.tertiary,
        foreground: scheme.onTertiary,
        pulses: true,
      );
    }
    return switch (state.status) {
      VoiceStatus.off => _MicVisual(
        icon: Icons.mic_off_outlined,
        background: scheme.surfaceContainerHighest,
        foreground: scheme.onSurfaceVariant,
      ),
      VoiceStatus.starting => _MicVisual(
        icon: Icons.mic_none,
        background: scheme.surfaceContainerHighest,
        foreground: scheme.onSurfaceVariant,
        busy: true,
      ),
      VoiceStatus.idle => _MicVisual(
        icon: Icons.mic_none,
        background: scheme.secondaryContainer,
        foreground: scheme.onSecondaryContainer,
      ),
      VoiceStatus.listening => _MicVisual(
        icon: Icons.mic,
        background: scheme.primary,
        foreground: scheme.onPrimary,
        pulses: true,
      ),
      VoiceStatus.error => _MicVisual(
        icon: Icons.mic_off,
        background: scheme.errorContainer,
        foreground: scheme.onErrorContainer,
      ),
    };
  }
}
