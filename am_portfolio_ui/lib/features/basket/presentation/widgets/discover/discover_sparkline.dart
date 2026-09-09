import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'discover_layout.dart';

/// Thin sparkline; returns empty if series is missing or too short.
class DiscoverSparkline extends StatelessWidget {
  const DiscoverSparkline({
    super.key,
    required this.data,
    required this.color,
    this.width = DiscoverLayout.sparklineWidth,
    this.height = DiscoverLayout.sparklineHeight,
  });

  final List<double>? data;
  final Color color;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final series = data;
    if (series == null || series.length < 2) {
      return SizedBox(width: width, height: height);
    }
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: DiscoverSparklinePainter(data: series, color: color),
      ),
    );
  }
}

class DiscoverSparklinePainter extends CustomPainter {
  DiscoverSparklinePainter({
    required this.data,
    required this.color,
  });

  final List<double> data;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;

    var maxVal = data.reduce(math.max);
    var minVal = data.reduce(math.min);
    if (maxVal == minVal) {
      maxVal += 1;
      minVal -= 1;
    }

    final stepX = size.width / (data.length - 1);
    final rangeY = maxVal - minVal;

    double getY(double val) =>
        size.height - ((val - minVal) / rangeY * size.height);

    final path = Path()..moveTo(0, getY(data[0]));
    for (var i = 0; i < data.length - 1; i++) {
      final x1 = i * stepX;
      final y1 = getY(data[i]);
      final x2 = (i + 1) * stepX;
      final y2 = getY(data[i + 1]);
      final cpX = x1 + (x2 - x1) / 2;
      path.cubicTo(cpX, y1, cpX, y2, x2, y2);
    }

    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant DiscoverSparklinePainter oldDelegate) =>
      oldDelegate.data != data || oldDelegate.color != color;
}
