import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/app_localizations.dart';
import '../../widgets/panel_text.dart';
import '../models/timer_config.dart';
import '../widgets/duration_field.dart';

/// The timer module's settings: a managed list of timers. Each can be renamed,
/// have its duration and sound/vibrate flags edited, or be removed; a button
/// appends a new one. Every edit is reported through [onChanged] as the full,
/// updated list.
class TimerSettingsView extends StatelessWidget {
  const TimerSettingsView({
    super.key,
    required this.timers,
    required this.onChanged,
  });

  final List<TimerConfig> timers;
  final ValueChanged<List<TimerConfig>> onChanged;

  void _replace(TimerConfig updated) {
    onChanged([
      for (final t in timers)
        if (t.id == updated.id) updated else t,
    ]);
  }

  void _delete(String id) {
    onChanged([
      for (final t in timers)
        if (t.id != id) t,
    ]);
  }

  void _add(AppLocalizations l10n) {
    onChanged([
      ...timers,
      TimerConfig(
        id: TimerConfig.newId(),
        name: l10n.timerNewName,
        duration: const Duration(minutes: 5),
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final t in timers)
            _TimerRow(
              key: ValueKey(t.id),
              config: t,
              displayName: t.displayName(l10n),
              hourLabel: l10n.timerHours,
              minuteLabel: l10n.timerMinutes,
              secondLabel: l10n.timerSeconds,
              nameLabel: l10n.timerName,
              soundLabel: l10n.timerSound,
              vibrateLabel: l10n.timerVibrate,
              pomodoroLabel: l10n.timerPomodoro,
              shortBreakLabel: l10n.timerShortBreak,
              longBreakLabel: l10n.timerLongBreak,
              deleteTooltip: l10n.timerDelete,
              onChanged: _replace,
              onDelete: () => _delete(t.id),
            ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: () => _add(l10n),
              icon: const Icon(Icons.add),
              label: Text(l10n.timerAdd),
            ),
          ),
        ],
      ),
    );
  }
}

/// One editable timer card. Owns the name field's controller so typing isn't
/// disrupted by the rebuilds each edit triggers; duration and the switches feed
/// straight back through [onChanged].
class _TimerRow extends StatefulWidget {
  const _TimerRow({
    super.key,
    required this.config,
    required this.displayName,
    required this.hourLabel,
    required this.minuteLabel,
    required this.secondLabel,
    required this.nameLabel,
    required this.soundLabel,
    required this.vibrateLabel,
    required this.pomodoroLabel,
    required this.shortBreakLabel,
    required this.longBreakLabel,
    required this.deleteTooltip,
    required this.onChanged,
    required this.onDelete,
  });

  final TimerConfig config;

  /// The localized text to seed the name field with: the user's name, or the
  /// default preset's localized label when it hasn't been renamed yet.
  final String displayName;
  final String hourLabel;
  final String minuteLabel;
  final String secondLabel;
  final String nameLabel;
  final String soundLabel;
  final String vibrateLabel;
  final String pomodoroLabel;
  final String shortBreakLabel;
  final String longBreakLabel;
  final String deleteTooltip;
  final ValueChanged<TimerConfig> onChanged;
  final VoidCallback onDelete;

  @override
  State<_TimerRow> createState() => _TimerRowState();
}

class _TimerRowState extends State<_TimerRow> {
  late final TextEditingController _name;

  @override
  void initState() {
    super.initState();
    // Seed with the resolved label so default presets show their localized name
    // rather than an empty box.
    _name = TextEditingController(text: widget.displayName);
  }

  @override
  void didUpdateWidget(_TimerRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reflect a name changed elsewhere, but never fight the user's own typing.
    if (widget.displayName != _name.text) {
      _name.text = widget.displayName;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _name,
                    decoration: InputDecoration(
                      labelText: widget.nameLabel,
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    // Typing turns a default preset into a user-named timer:
                    // store the explicit name and drop the semantic label key.
                    onChanged: (v) => widget.onChanged(widget.config.rename(v)),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: widget.deleteTooltip,
                  onPressed: widget.onDelete,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                DurationField(
                  initial: widget.config.duration,
                  onChanged: (d) {
                    if (d <= Duration.zero) return;
                    widget.onChanged(widget.config.copyWith(duration: d));
                  },
                  hourLabel: widget.hourLabel,
                  minuteLabel: widget.minuteLabel,
                  secondLabel: widget.secondLabel,
                ),
                const Spacer(),
                // The duration boxes carry floating labels that sit above the
                // box, lifting their optical centre; offset the icons up to
                // match it rather than the row's geometric centre.
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ToggleIcon(
                        tooltip: widget.soundLabel,
                        icon: Icons.notifications_off_outlined,
                        selectedIcon: Icons.notifications_active,
                        value: widget.config.sound,
                        onChanged: (v) =>
                            widget.onChanged(widget.config.copyWith(sound: v)),
                      ),
                      const SizedBox(width: 4),
                      _ToggleIcon(
                        tooltip: widget.vibrateLabel,
                        icon: Icons.smartphone_outlined,
                        selectedIcon: Icons.vibration,
                        value: widget.config.vibrate,
                        onChanged: (v) => widget.onChanged(
                          widget.config.copyWith(vibrate: v),
                        ),
                      ),
                      const SizedBox(width: 4),
                      _ToggleIcon(
                        tooltip: widget.pomodoroLabel,
                        icon: Icons.local_cafe_outlined,
                        selectedIcon: Icons.local_cafe,
                        value: widget.config.pomodoro,
                        onChanged: (v) => widget.onChanged(
                          widget.config.copyWith(pomodoro: v),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (widget.config.pomodoro) ...[
              const SizedBox(height: 12),
              _BreakConfig(
                config: widget.config,
                shortBreakLabel: widget.shortBreakLabel,
                longBreakLabel: widget.longBreakLabel,
                minuteLabel: widget.minuteLabel,
                onChanged: widget.onChanged,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The Pomodoro break settings revealed when a timer is marked as a task: the
/// short and long break lengths, laid out side by side as two minutes fields.
/// Keyed by the config id so the fields re-seed when switched to a different
/// timer.
class _BreakConfig extends StatelessWidget {
  const _BreakConfig({
    required this.config,
    required this.shortBreakLabel,
    required this.longBreakLabel,
    required this.minuteLabel,
    required this.onChanged,
  });

  final TimerConfig config;
  final String shortBreakLabel;
  final String longBreakLabel;
  final String minuteLabel;
  final ValueChanged<TimerConfig> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _MinuteField(
          key: ValueKey('short-${config.id}'),
          initial: config.shortBreak,
          label: shortBreakLabel,
          minuteLabel: minuteLabel,
          onChanged: (d) => onChanged(config.copyWith(shortBreak: d)),
        ),
        const SizedBox(width: 12),
        _MinuteField(
          key: ValueKey('long-${config.id}'),
          initial: config.longBreak,
          label: longBreakLabel,
          minuteLabel: minuteLabel,
          onChanged: (d) => onChanged(config.copyWith(longBreak: d)),
        ),
      ],
    );
  }
}

/// A single minutes input, styled to match [DurationField]: a floating [label]
/// sitting on the outlined border and the same panel typeface. Seeds from
/// [initial], reports the value back as a `Duration` of whole minutes; values
/// below one minute are ignored.
class _MinuteField extends StatefulWidget {
  const _MinuteField({
    super.key,
    required this.initial,
    required this.label,
    required this.minuteLabel,
    required this.onChanged,
  });

  final Duration initial;
  final String label;
  final String minuteLabel;
  final ValueChanged<Duration> onChanged;

  @override
  State<_MinuteField> createState() => _MinuteFieldState();
}

class _MinuteFieldState extends State<_MinuteField> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: '${widget.initial.inMinutes}');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 100,
      child: TextField(
        controller: _ctrl,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        style: panelFont(18, 600, theme.colorScheme.onSurface),
        decoration: InputDecoration(
          labelText: widget.label,
          floatingLabelBehavior: FloatingLabelBehavior.always,
          border: const OutlineInputBorder(),
          suffixText: widget.minuteLabel,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 12,
          ),
        ),
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(3),
        ],
        onChanged: (v) {
          final m = int.tryParse(v) ?? 0;
          if (m <= 0) return;
          widget.onChanged(Duration(minutes: m));
        },
      ),
    );
  }
}

/// A compact on/off icon button: filled-tonal when on, plain when off. Used for
/// the per-timer sound and vibrate flags.
class _ToggleIcon extends StatelessWidget {
  const _ToggleIcon({
    required this.tooltip,
    required this.icon,
    required this.selectedIcon,
    required this.value,
    required this.onChanged,
  });

  final String tooltip;
  final IconData icon;
  final IconData selectedIcon;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return IconButton(
      tooltip: tooltip,
      isSelected: value,
      iconSize: 24,
      // visualDensity: VisualDensity.compact,
      style: IconButton.styleFrom(
        minimumSize: const Size(32, 32),
        padding: const EdgeInsets.all(6),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        backgroundColor: value ? scheme.secondaryContainer : null,
        foregroundColor: value ? scheme.onSecondaryContainer : null,
      ),
      icon: Icon(icon),
      selectedIcon: Icon(selectedIcon),
      onPressed: () => onChanged(!value),
    );
  }
}
