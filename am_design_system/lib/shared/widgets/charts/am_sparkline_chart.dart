import 'package:flutter/material.dart';
import 'dart:math' as math;

import 'package:am_design_system/core/theme/app_spacing.dart';
import 'package:am_design_system/core/theme/app_text_styles.dart';
import 'package:am_design_system/core/theme/color_extensions.dart';
import 'package:intl/intl.dart';

/// A lightweight, reusable sparkline line chart.
class AmSparklineChart extends StatelessWidget {
  const AmSparklineChart({
    super.key,
    required this.data,
    this.color,
    this.lineWidth = 1.5,
    this.fill = false,
    this.lastDot = false,
    this.showYLabels = false,
    this.midlineColor,
    this.fillOpacity = 0.22,
  });

  final List<double> data;
  final Color? color;
  final double lineWidth;
  final bool fill;
  final bool lastDot;
  final bool showYLabels;
  final Color? midlineColor;
  final double fillOpacity;

  @override
  Widget build(BuildContext context) {
    if (data.length < 2) return const SizedBox.shrink();

    final stroke = color ?? context.marketPositive;
    final chart = CustomPaint(
      painter: _SparklinePainter(
        data: data,
        color: stroke,
        lineWidth: lineWidth,
        fill: fill,
        lastDot: lastDot,
        midlineColor: midlineColor,
        fillOpacity: fillOpacity,
      ),
      size: Size.infinite,
    );

    if (!showYLabels) return chart;

    final maxVal = data.reduce(math.max);
    final minVal = data.reduce(math.min);
    final midVal = (maxVal + minVal) / 2;
    final fmt = NumberFormat('#,##,##0', 'en_IN');
    final labelStyle = context.text.caption(compact: true).copyWith(
          color: context.textTertiary,
        );

    return Row(
      children: [
        Expanded(child: chart),
        SizedBox(width: AppSpacing.xs),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(fmt.format(maxVal), style: labelStyle),
              Text(fmt.format(midVal), style: labelStyle),
              Text(fmt.format(minVal), style: labelStyle),
            ],
          ),
        ),
      ],
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({
    required this.data,
    required this.color,
    required this.lineWidth,
    required this.fill,
    required this.lastDot,
    required this.midlineColor,
    required this.fillOpacity,
  });

  final List<double> data;
  final Color color;
  final double lineWidth;
  final bool fill;
  final bool lastDot;
  final Color? midlineColor;
  final double fillOpacity;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;

    final double maxVal = data.reduce(math.max);
    final double minVal = data.reduce(math.min);
    final double range = maxVal - minVal;
    final double xStep = size.width / (data.length - 1);
    final topPad = lastDot ? 4.0 : 0.0;
    final botPad = lastDot ? 4.0 : 0.0;
    final plotH = size.height - topPad - botPad;

    double yOf(double val) {
      if (range == 0) return topPad + plotH / 2;
      return topPad + plotH - ((val - minVal) / range) * plotH;
    }

    final path = Path();
    for (int i = 0; i < data.length; i++) {
      final x = i * xStep;
      final y = yOf(data[i]);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    if (fill) {
      final fillPath = Path.from(path)
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close();
      canvas.drawPath(
        fillPath,
        Paint()
          ..color = color.withValues(alpha: fillOpacity)
          ..style = PaintingStyle.fill,
      );
    }

    final mid = midlineColor;
    if (mid != null) {
      final midY = yOf((maxVal + minVal) / 2);
      final dashPaint = Paint()
        ..color = mid
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;
      const dash = 4.0;
      const gap = 3.0;
      var x = 0.0;
      while (x < size.width) {
        final x2 = math.min(x + dash, size.width);
        canvas.drawLine(Offset(x, midY), Offset(x2, midY), dashPaint);
        x += dash + gap;
      }
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = lineWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    if (lastDot) {
      final last = Offset((data.length - 1) * xStep, yOf(data.last));
      canvas.drawCircle(last, 3, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.color != color ||
        oldDelegate.lineWidth != lineWidth ||
        oldDelegate.fill != fill ||
        oldDelegate.lastDot != lastDot ||
        oldDelegate.midlineColor != midlineColor ||
        oldDelegate.fillOpacity != fillOpacity;
  }
}
