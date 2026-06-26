import 'package:flutter/material.dart';

/// A round, finger-sized icon button for on-panel module controls.
class PanelButton extends StatelessWidget {
  const PanelButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.diameter,
    required this.color,
    required this.foreground,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final double diameter;

  /// Filled background color.
  final Color color;

  /// Icon (foreground) color.
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: diameter,
      height: diameter,
      child: Material(
        color: color,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: Icon(icon, size: diameter * 0.5, color: foreground),
        ),
      ),
    );
  }
}
