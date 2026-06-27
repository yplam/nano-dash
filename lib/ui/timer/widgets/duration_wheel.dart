import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../widgets/panel_text.dart';

/// An `h:mm:ss` duration picker (Cupertino scroll wheels) themed to match the
/// panel typeface and the surrounding color scheme.
///
/// [CupertinoTimerPicker] consumes [initial] only when it first mounts and then
/// owns its scroll state, so feeding the live value back in on rebuild is
/// harmless. Every change is reported through [onChanged], clamped to [minimum]
/// so the timer is never armed at zero.
class DurationWheel extends StatelessWidget {
  const DurationWheel({
    super.key,
    required this.initial,
    required this.onChanged,
    this.minimum = const Duration(seconds: 1),
    this.color,
    this.fontSize = 21,
  });

  /// The duration the wheels start on. Read once, at mount.
  final Duration initial;

  final ValueChanged<Duration> onChanged;

  /// Smallest duration the wheels are allowed to report.
  final Duration minimum;

  /// Digit color; defaults to the scheme's `onSurface`.
  final Color? color;

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = color ?? theme.colorScheme.onSurface;

    return CupertinoTheme(
      data: CupertinoThemeData(
        brightness: theme.brightness,
        textTheme: CupertinoTextThemeData(
          pickerTextStyle: panelFont(fontSize, 600, textColor),
        ),
      ),
      child: CupertinoTimerPicker(
        mode: CupertinoTimerPickerMode.hms,
        initialTimerDuration: initial,
        onTimerDurationChanged: (d) => onChanged(d < minimum ? minimum : d),
      ),
    );
  }
}
