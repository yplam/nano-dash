import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A circular progress ring sized to fill its (square) box, with [child] centered inside.
///
/// [progress] is clamped to 0..1 and swept clockwise from the top (12 o'clock).
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
    this.child,
  });

  /// Fraction of the ring to fill, 0..1.
  final double progress;

  /// Color of the swept arc.
  final Color color;

  /// Color of the unfilled track beneath the arc.
  final Color trackColor;

  /// Thickness of both the track and the arc.
  final double strokeWidth;

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _RingPainter(
        progress: progress.clamp(0.0, 1.0),
        color: color,
        trackColor: trackColor,
        strokeWidth: strokeWidth,
      ),
      child: Center(child: child),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
  });

  final double progress;
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final side = math.min(size.width, size.height);
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (side - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = trackColor;
    canvas.drawCircle(center, radius, track);

    if (progress <= 0) return;

    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = color;
    // Sweep clockwise from the top (12 o'clock).
    const start = -math.pi / 2;
    canvas.drawArc(rect, start, 2 * math.pi * progress, false, arc);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress ||
      old.color != color ||
      old.trackColor != trackColor ||
      old.strokeWidth != strokeWidth;
}
