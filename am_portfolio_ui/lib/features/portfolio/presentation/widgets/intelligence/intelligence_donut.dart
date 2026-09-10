import 'package:flutter/material.dart';

import '../../../internal/domain/entities/portfolio_intelligence.dart';

/// Donut color helpers shared by X-Ray legend / bars.
class IntelligenceDonut {
  IntelligenceDonut._();

  static const palette = <Color>[
    Color(0xFFD4AF37),
    Color(0xFFFBBF24),
    Color(0xFFF472B6),
    Color(0xFF34D399),
    Color(0xFFA78BFA),
    Color(0xFFFB923C),
    Color(0xFF60A5FA),
    Color(0xFF2DD4BF),
  ];
}

Color intelligenceDonutColor(int index) =>
    IntelligenceDonut.palette[index % IntelligenceDonut.palette.length];

/// Legacy static donut (tests / fallback). Prefer interactive X-Ray painter.
class IntelligenceDonutView extends StatelessWidget {
  const IntelligenceDonutView({
    required this.weights,
    this.size = 148,
    this.centerLabel = 'Sectors',
    this.centerValue,
    super.key,
  });

  final List<XrayWeight> weights;
  final double size;
  final String centerLabel;
  final String? centerValue;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _SimpleDonutPainter(weights: weights),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                centerLabel,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).hintColor,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              if (centerValue != null)
                Text(
                  centerValue!,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SimpleDonutPainter extends CustomPainter {
  _SimpleDonutPainter({required this.weights});

  final List<XrayWeight> weights;

  @override
  void paint(Canvas canvas, Size size) {
    final slices = weights.where((w) => w.weightPct > 0).take(8).toList();
    if (slices.isEmpty) return;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2 - 8;
    var start = -3.14159 / 2;
    final total = slices.fold<double>(0, (s, w) => s + w.weightPct);
    for (var i = 0; i < slices.length; i++) {
      final sweep = (slices[i].weightPct / total) * 6.28318;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        sweep - 0.04,
        false,
        Paint()
          ..color = intelligenceDonutColor(i)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 18,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _SimpleDonutPainter oldDelegate) =>
      oldDelegate.weights != weights;
}
