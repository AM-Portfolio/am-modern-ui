import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';

import '../../data/mf_dto.dart';

/// Lightweight NAV sparkline (no fl_chart dependency).
class MfNavChart extends StatelessWidget {
  const MfNavChart({
    required this.points,
    this.height = 140,
    super.key,
  });

  final List<MfNavPoint> points;
  final double height;

  @override
  Widget build(BuildContext context) {
    final accent =
        ModuleColorProvider.maybeOf(context) ?? ModuleColors.mutualFund;

    if (points.length < 2) {
      return Container(
        height: height,
        alignment: Alignment.center,
        child: Text(
          points.isEmpty
              ? 'No NAV history yet'
              : 'Need at least 2 points for a chart',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: context.textSecondary,
              ),
        ),
      );
    }

    final values = points.map((p) => p.nav).toList();
    final minV = values.reduce((a, b) => a < b ? a : b);
    final maxV = values.reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: height,
          child: CustomPaint(
            painter: _NavLinePainter(
              values: values,
              minV: minV,
              maxV: maxV,
              lineColor: accent,
              fillColor: accent.withValues(alpha: 0.12),
              gridColor: context.borderColor,
            ),
            child: const SizedBox.expand(),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Text(
              points.first.date,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: context.textSecondary,
                  ),
            ),
            const Spacer(),
            Text(
              '₹${minV.toStringAsFixed(2)} – ₹${maxV.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: context.textSecondary,
                  ),
            ),
            const Spacer(),
            Text(
              points.last.date,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: context.textSecondary,
                  ),
            ),
          ],
        ),
      ],
    );
  }
}

class _NavLinePainter extends CustomPainter {
  _NavLinePainter({
    required this.values,
    required this.minV,
    required this.maxV,
    required this.lineColor,
    required this.fillColor,
    required this.gridColor,
  });

  final List<double> values;
  final double minV;
  final double maxV;
  final Color lineColor;
  final Color fillColor;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final range = (maxV - minV).abs() < 1e-9 ? 1.0 : (maxV - minV);
    final padY = 8.0;
    final h = size.height - padY * 2;
    final w = size.width;

    final grid = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (var i = 0; i < 3; i++) {
      final y = padY + h * (i / 2);
      canvas.drawLine(Offset(0, y), Offset(w, y), grid);
    }

    Offset pt(int i) {
      final x = w * (i / (values.length - 1));
      final y = padY + h * (1 - ((values[i] - minV) / range));
      return Offset(x, y);
    }

    final path = Path()..moveTo(pt(0).dx, pt(0).dy);
    for (var i = 1; i < values.length; i++) {
      path.lineTo(pt(i).dx, pt(i).dy);
    }

    final fill = Path.from(path)
      ..lineTo(w, size.height - padY)
      ..lineTo(0, size.height - padY)
      ..close();
    canvas.drawPath(fill, Paint()..color = fillColor);

    canvas.drawPath(
      path,
      Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _NavLinePainter oldDelegate) =>
      oldDelegate.values != values ||
      oldDelegate.lineColor != lineColor ||
      oldDelegate.minV != minV ||
      oldDelegate.maxV != maxV;
}
