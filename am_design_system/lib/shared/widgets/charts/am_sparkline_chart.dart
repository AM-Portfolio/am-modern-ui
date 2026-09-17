import 'package:flutter/material.dart';
import 'dart:math' as math;

/// A lightweight, reusable sparkline line chart.
class AmSparklineChart extends StatelessWidget {
  const AmSparklineChart({
    super.key,
    required this.data,
    this.color,
    this.lineWidth = 1.5,
  });

  final List<double> data;
  final Color? color;
  final double lineWidth;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();

    return CustomPaint(
      painter: _SparklinePainter(
        data: data,
        color: color ?? Theme.of(context).colorScheme.primary,
        lineWidth: lineWidth,
      ),
      size: Size.infinite,
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({
    required this.data,
    required this.color,
    required this.lineWidth,
  });

  final List<double> data;
  final Color color;
  final double lineWidth;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = lineWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final double maxVal = data.reduce(math.max);
    final double minVal = data.reduce(math.min);
    final double range = maxVal - minVal;

    final double xStep = size.width / (data.length - 1);
    
    final path = Path();
    for (int i = 0; i < data.length; i++) {
      final x = i * xStep;
      // If range is 0, draw in the middle
      final y = range == 0 
          ? size.height / 2 
          : size.height - ((data[i] - minVal) / range) * size.height;
          
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.data != data || 
           oldDelegate.color != color || 
           oldDelegate.lineWidth != lineWidth;
  }
}
