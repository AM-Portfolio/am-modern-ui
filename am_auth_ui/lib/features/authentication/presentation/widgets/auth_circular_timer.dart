import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:am_design_system/core/theme/color_extensions.dart';

/// Circular countdown using actionPrimaryBg (same accent as email Sign In).
class AuthCircularTimer extends StatelessWidget {
  const AuthCircularTimer({
    super.key,
    required this.remainingSeconds,
    required this.totalSeconds,
    this.size = 56,
  });

  final int remainingSeconds;
  final int totalSeconds;
  final double size;

  @override
  Widget build(BuildContext context) {
    final total = totalSeconds <= 0 ? 1 : totalSeconds;
    final progress = (remainingSeconds / total).clamp(0.0, 1.0);
    final primary = context.colors.actionPrimaryBg;

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _AuthCircularTimerPainter(
          progress: progress,
          trackColor: context.colors.border.withValues(alpha: 0.35),
          progressColor: primary,
        ),
        child: Center(
          child: Text(
            '${remainingSeconds}s',
            style: TextStyle(
              fontSize: size * 0.28,
              fontWeight: FontWeight.w700,
              color: context.colors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthCircularTimerPainter extends CustomPainter {
  _AuthCircularTimerPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
  });

  final double progress;
  final Color trackColor;
  final Color progressColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 4;
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _AuthCircularTimerPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.progressColor != progressColor;
  }
}
