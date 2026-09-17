import 'package:flutter/material.dart';
import 'dart:math' as math;

/// A lightweight donut chart for sparkline/KPI usage.
class AmDonutSparkline extends StatelessWidget {
  const AmDonutSparkline({
    super.key,
    required this.value,
    required this.total,
    required this.color,
    required this.backgroundColor,
    this.strokeWidth = 3.0,
  });

  final double value;
  final double total;
  final Color color;
  final Color backgroundColor;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final fraction = total > 0 ? (value / total).clamp(0.0, 1.0) : 0.0;
    
    return CustomPaint(
      painter: _DonutPainter(
        fraction: fraction,
        color: color,
        backgroundColor: backgroundColor,
        strokeWidth: strokeWidth,
      ),
      size: Size.infinite,
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({
    required this.fraction,
    required this.color,
    required this.backgroundColor,
    required this.strokeWidth,
  });

  final double fraction;
  final Color color;
  final Color backgroundColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;

    final bgPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final fgPaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Draw background circle
    canvas.drawCircle(center, radius, bgPaint);

    // Draw foreground arc
    if (fraction > 0) {
      final sweepAngle = 2 * math.pi * fraction;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2, // Start from top
        sweepAngle,
        false,
        fgPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.fraction != fraction ||
           oldDelegate.color != color ||
           oldDelegate.backgroundColor != backgroundColor ||
           oldDelegate.strokeWidth != strokeWidth;
  }
}
