import 'dart:ui';
import 'package:flutter/material.dart';
import 'dart:math' as math;

class PortfolioMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color accentColor;
  final IconData? icon;
  final bool? isPositive;
  final bool isHighlight;
  final bool compact;
  final String? tooltip;
  final List<double>? sparklineData;
  final bool glowBorder;

  const PortfolioMetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.accentColor,
    this.icon,
    this.isPositive,
    this.isHighlight = false,
    this.compact = false,
    this.tooltip,
    this.sparklineData,
    this.glowBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;
    final vPad = compact ? 12.0 : 16.0;
    final hPad = compact ? 12.0 : 16.0;

    final Color cardBase =
        isDark ? const Color(0xFF0D1B2A) : const Color(0xFFFFFFFF);
    final bool useAccentValue = glowBorder || isPositive != null;

    return Tooltip(
      message: tooltip ?? title,
      child: Stack(
        children: [
          // ── Ambient glow behind card (performance-safe RadialGradient) ──
          if (glowBorder)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: RadialGradient(
                    center: Alignment.bottomLeft,
                    radius: 1.2,
                    colors: [
                      accentColor.withValues(alpha: 0.18),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          // ── Card body ──
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: isHighlight
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            accentColor.withValues(alpha: 0.25),
                            accentColor.withValues(alpha: 0.1),
                          ],
                        )
                      : LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            cardBase.withValues(alpha: isDark ? 0.3 : 0.5),
                            cardBase.withValues(alpha: isDark ? 0.1 : 0.15),
                          ],
                        ),
                  border: Border.all(
                    color: glowBorder
                        ? accentColor.withValues(alpha: 0.35)
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.07)
                            : Colors.black.withValues(alpha: 0.06)),
                    width: 1,
                  ),
                  // No drop shadows on compact (mobile) — keeps the grid tight.
                  boxShadow: compact
                      ? null
                      : glowBorder
                          ? [
                              BoxShadow(
                                color: accentColor.withValues(alpha: 0.22),
                                blurRadius: 24,
                                spreadRadius: -2,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : [
                              BoxShadow(
                                color: Colors.black.withValues(
                                    alpha: isDark ? 0.3 : 0.06),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Stack(
                    children: [
                      // ── Watermark Icon (clipped by card) ──
                      if (icon != null)
                        Positioned(
                          right: 0,
                          bottom: -4,
                          child: Transform.rotate(
                            angle: -math.pi / 12,
                            child: Icon(
                              icon,
                              size: compact ? 56 : 76,
                              color: isHighlight
                                  ? Colors.white.withValues(alpha: 0.14)
                                  : accentColor.withValues(alpha: 0.07),
                            ),
                          ),
                        ),

                      // ── Main Content ──
                      Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: hPad, vertical: vPad),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Title
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.bodySmall?.copyWith(
                                fontSize: compact ? 10 : 11,
                                color: isHighlight
                                    ? Colors.white.withValues(alpha: 0.85)
                                    : (isDark
                                        ? Colors.white.withValues(alpha: 0.5)
                                        : Colors.black.withValues(alpha: 0.45)),
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.4,
                              ),
                            ),
                            SizedBox(height: compact ? 8 : 12),

                            // Main value
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                value,
                                style: textTheme.headlineSmall?.copyWith(
                                  fontSize: compact ? 18 : 22,
                                  fontWeight: FontWeight.bold,
                                  color: isHighlight
                                      ? Colors.white
                                      : (useAccentValue
                                          ? accentColor
                                          : (isDark
                                              ? Colors.white
                                              : const Color(0xFF1A1A2E))),
                                  height: 1.1,
                                  shadows: (glowBorder && isDark)
                                      ? [
                                          Shadow(
                                            color: accentColor
                                                .withValues(alpha: 0.6),
                                            blurRadius: 12,
                                          ),
                                        ]
                                      : null,
                                ),
                              ),
                            ),
                            SizedBox(height: compact ? 6 : 8),

                            // Subtitle
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isPositive != null) ...[
                                  Icon(
                                    isPositive!
                                        ? Icons.arrow_upward_rounded
                                        : Icons.arrow_downward_rounded,
                                    size: compact ? 10 : 12,
                                    color: isHighlight
                                        ? Colors.white.withValues(alpha: 0.9)
                                        : accentColor,
                                  ),
                                  const SizedBox(width: 2),
                                ],
                                Flexible(
                                  child: Text(
                                    subtitle,
                                    style: textTheme.bodySmall?.copyWith(
                                      fontSize: compact ? 9 : 11,
                                      color: isHighlight
                                          ? Colors.white.withValues(alpha: 0.75)
                                          : (isPositive != null
                                              ? accentColor
                                                  .withValues(alpha: 0.9)
                                              : (isDark
                                                  ? Colors.white
                                                      .withValues(alpha: 0.4)
                                                  : Colors.black
                                                      .withValues(alpha: 0.4))),
                                      fontWeight:
                                          (isPositive != null && isPositive!)
                                              ? FontWeight.w600
                                              : FontWeight.w400,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SparklinePainter extends CustomPainter {
  final List<double> data;
  final Color color;
  final bool drawGlow;

  SparklinePainter({
    required this.data,
    required this.color,
    this.drawGlow = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    double maxVal = data.reduce(math.max);
    double minVal = data.reduce(math.min);
    if (maxVal == minVal) {
      maxVal += 1;
      minVal -= 1;
    }

    final stepX = size.width / (data.length - 1);
    final rangeY = maxVal - minVal;

    double getY(double val) =>
        size.height - ((val - minVal) / rangeY * size.height);

    final path = Path();
    path.moveTo(0, getY(data[0]));

    for (int i = 0; i < data.length - 1; i++) {
      final x1 = i * stepX;
      final y1 = getY(data[i]);
      final x2 = (i + 1) * stepX;
      final y2 = getY(data[i + 1]);
      final cpX = x1 + (x2 - x1) / 2;
      path.cubicTo(cpX, y1, cpX, y2, x2, y2);
    }

    // Glow pass
    if (drawGlow) {
      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.35)
        ..strokeWidth = 5.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawPath(path, glowPaint);
    }

    // Crisp line
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant SparklinePainter oldDelegate) =>
      oldDelegate.data != data ||
      oldDelegate.color != color ||
      oldDelegate.drawGlow != drawGlow;
}
