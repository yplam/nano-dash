import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../widgets/panel_text.dart';

/// A keyboard-first `HH:MM:SS` duration input: three two-digit fields laid out
/// as `[]:[]:[]`, with range validation and smart focus movement.
///
/// Editing rules:
///  * each field holds at most two digits; minutes and seconds are capped at 59
///    and hours at 99 — keystrokes that would exceed the cap are rejected.
///  * focus auto-advances once a field is "full": always at two digits, and for
///    minutes/seconds also after a single digit that can't be extended into a
///    valid value (6-9, since 60+ is out of range).
///  * Tab moves to the next field; Backspace on an empty field jumps back to the
///    previous one. Landing on a field selects its contents so typing overwrites.
///
/// [initial] is read once, at mount. Every edit is reported through [onChanged];
/// empty fields count as zero, so the reported duration may be zero.
class DurationField extends StatefulWidget {
  const DurationField({
    super.key,
    required this.initial,
    required this.onChanged,
    this.hourLabel,
    this.minuteLabel,
    this.secondLabel,
  });

  /// The duration the fields start on. Read once, at mount.
  final Duration initial;

  final ValueChanged<Duration> onChanged;

  /// Captions shown beneath each field; omitted when null.
  final String? hourLabel;
  final String? minuteLabel;
  final String? secondLabel;

  @override
  State<DurationField> createState() => _DurationFieldState();
}

class _DurationFieldState extends State<DurationField> {
  static const int _maxHours = 99;
  static const int _maxMinSec = 59;
  static const double _boxHeight = 56;
  static const double _boxWidth = 64;

  late final _Unit _hours;
  late final _Unit _minutes;
  late final _Unit _seconds;
  late final List<_Unit> _units;

  @override
  void initState() {
    super.initState();
    final d = widget.initial;
    _hours = _Unit(d.inHours, _maxHours, widget.hourLabel);
    _minutes = _Unit(d.inMinutes.remainder(60), _maxMinSec, widget.minuteLabel);
    _seconds = _Unit(d.inSeconds.remainder(60), _maxMinSec, widget.secondLabel);
    _units = [_hours, _minutes, _seconds];

    for (var i = 0; i < _units.length; i++) {
      final unit = _units[i];
      final prev = i > 0 ? _units[i - 1] : null;
      unit.node.addListener(() => _onFocusChange(unit));
      unit.node.onKeyEvent = (_, event) => _onKey(event, unit, prev);
    }
  }

  @override
  void dispose() {
    for (final u in _units) {
      u.dispose();
    }
    super.dispose();
  }

  Duration get _value => Duration(
    hours: _hours.value,
    minutes: _minutes.value,
    seconds: _seconds.value,
  );

  /// Select all on focus (so typing overwrites); pad to two digits on blur.
  void _onFocusChange(_Unit unit) {
    final ctrl = unit.controller;
    if (unit.node.hasFocus) {
      ctrl.selection = TextSelection(
        baseOffset: 0,
        extentOffset: ctrl.text.length,
      );
    } else {
      ctrl.text = unit.value.toString().padLeft(2, '0');
    }
  }

  /// Backspace on an empty field hops to the previous one; everything else is
  /// left to the field itself.
  KeyEventResult _onKey(KeyEvent event, _Unit unit, _Unit? prev) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        unit.controller.text.isEmpty &&
        prev != null) {
      prev.node.requestFocus();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _onUnitChanged(_Unit unit) {
    widget.onChanged(_value);
    final i = _units.indexOf(unit);
    if (unit.isFull && i + 1 < _units.length) {
      _units[i + 1].node.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildUnit(theme, _hours),
        _colon(theme),
        _buildUnit(theme, _minutes),
        _colon(theme),
        _buildUnit(theme, _seconds),
      ],
    );
  }

  Widget _buildUnit(ThemeData theme, _Unit unit) {
    return SizedBox(
      width: _boxWidth,
      height: _boxHeight,
      child: TextField(
        controller: unit.controller,
        focusNode: unit.node,
        textAlign: TextAlign.center,
        textAlignVertical: TextAlignVertical.center,
        keyboardType: TextInputType.number,
        style: panelFont(24, 600, theme.colorScheme.onSurface),
        decoration: InputDecoration(
          labelText: unit.label,
          floatingLabelBehavior: FloatingLabelBehavior.always,
          floatingLabelAlignment: FloatingLabelAlignment.center,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
        ),
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(2),
          _MaxValueFormatter(unit.max),
        ],
        onChanged: (_) => _onUnitChanged(unit),
      ),
    );
  }

  Widget _colon(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: SizedBox(
        height: _boxHeight,
        child: Center(child: Text(':', style: theme.textTheme.headlineSmall)),
      ),
    );
  }
}

/// One field's state: its controller, focus node, and value cap.
class _Unit {
  _Unit(int value, this.max, this.label)
    : controller = TextEditingController(
        text: value.toString().padLeft(2, '0'),
      ),
      node = FocusNode();

  final int max;
  final String? label;
  final TextEditingController controller;
  final FocusNode node;

  int get value => int.tryParse(controller.text) ?? 0;

  /// Whether focus should advance: two digits, or a single digit that can't be
  /// extended into a valid value (its smallest two-digit form already exceeds
  /// [max]).
  bool get isFull {
    final t = controller.text;
    if (t.length >= 2) return true;
    final v = int.tryParse(t);
    return v != null && v * 10 > max;
  }

  void dispose() {
    controller.dispose();
    node.dispose();
  }
}

/// Rejects an edit whose numeric value would exceed [max], so a field can never
/// hold an out-of-range number.
class _MaxValueFormatter extends TextInputFormatter {
  const _MaxValueFormatter(this.max);

  final int max;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;
    final v = int.tryParse(newValue.text);
    if (v == null || v > max) return oldValue;
    return newValue;
  }
}
