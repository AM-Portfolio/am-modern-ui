import 'package:flutter/material.dart';
import 'dart:math' as math;

/// A lightweight bar chart for sparkline/KPI usage.
class AmBarSparkline extends StatelessWidget {
  const AmBarSparkline({
    super.key,
    required this.data,
    required this.positiveColor,
    required this.negativeColor,
    this.barWidth = 4.0,
    this.spacing = 2.0,
  });

  final List<double> data;
  final Color positiveColor;
  final Color negativeColor;
  final double barWidth;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();

    return CustomPaint(
      painter: _BarSparklinePainter(
        data: data,
        positiveColor: positiveColor,
        negativeColor: negativeColor,
        barWidth: barWidth,
        spacing: spacing,
      ),
      size: Size.infinite,
    );
  }
}

class _BarSparklinePainter extends CustomPainter {
  _BarSparklinePainter({
    required this.data,
    required this.positiveColor,
    required this.negativeColor,
    required this.barWidth,
    required this.spacing,
  });

  final List<double> data;
  final Color positiveColor;
  final Color negativeColor;
  final double barWidth;
  final double spacing;

  @override
  void paint(Canvas canvas, Size size) {
    final maxAbs = data.map((e) => e.abs()).fold<double>(0, math.max);
    if (maxAbs == 0) return;

    final centerY = size.height / 2;
    // We try to fit as many bars as possible from right to left,
    // or just draw them left to right if they fit.
    final totalRequiredWidth = data.length * (barWidth + spacing) - spacing;
    
    // Start drawing from the left, or align right if they overflow?
    // Let's just draw left to right.
    double currentX = 0;

    for (final val in data) {
      if (currentX > size.width) break; // Don't draw outside

      final barHeight = (val.abs() / maxAbs) * (size.height / 2);
      final paint = Paint()
        ..color = val >= 0 ? positiveColor : negativeColor
        ..style = PaintingStyle.fill;
        
      final rect = val >= 0
          ? Rect.fromLTRB(currentX, centerY - barHeight, currentX + barWidth, centerY)
          : Rect.fromLTRB(currentX, centerY, currentX + barWidth, centerY + barHeight);

      // Add a slight corner radius if it's tall enough
      final rRect = RRect.fromRectAndRadius(rect, const Radius.circular(1.0));
      canvas.drawRRect(rRect, paint);
      
      currentX += barWidth + spacing;
    }
  }

  @override
  bool shouldRepaint(covariant _BarSparklinePainter oldDelegate) {
    return oldDelegate.data != data ||
           oldDelegate.positiveColor != positiveColor ||
           oldDelegate.negativeColor != negativeColor;
  }
}
