import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../l10n/app_localizations.dart';
import '../cubit/timer_cubit.dart';

/// The timer's settings UI: a minutes and a seconds stepper.
class TimerSettingsView extends StatelessWidget {
  const TimerSettingsView({
    super.key,
    required this.duration,
    required this.onChanged,
  });

  final Duration duration;
  final ValueChanged<Duration> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);

    void apply(int min, int sec) {
      final clampedMin = min.clamp(0, 99);
      final clampedSec = sec.clamp(0, 59);
      var totalSec = clampedMin * 60 + clampedSec;
      if (totalSec < 1) totalSec = 1; // never a zero-length timer
      final total = Duration(seconds: totalSec);
      onChanged(total);
      // Reflect the change live while the timer is at rest.
      context.read<TimerCubit>().setDuration(total);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _DurationStepper(
          label: l10n.timerMinutes,
          value: minutes,
          max: 99,
          onChanged: (v) => apply(v, seconds),
        ),
        _DurationStepper(
          label: l10n.timerSeconds,
          value: seconds,
          max: 59,
          step: 5,
          onChanged: (v) => apply(minutes, v),
        ),
      ],
    );
  }
}

/// A labelled `– value +` row for picking a minutes/seconds component.
class _DurationStepper extends StatelessWidget {
  const _DurationStepper({
    required this.label,
    required this.value,
    required this.max,
    required this.onChanged,
    this.step = 1,
  });

  final String label;
  final int value;
  final int max;
  final int step;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: value <= 0 ? null : () => onChanged(value - step),
          ),
          SizedBox(
            width: 36,
            child: Text(
              value.toString().padLeft(2, '0'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFeatures: [FontFeature.tabularFigures()],
                fontSize: 18,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: value >= max ? null : () => onChanged(value + step),
          ),
        ],
      ),
    );
  }
}
