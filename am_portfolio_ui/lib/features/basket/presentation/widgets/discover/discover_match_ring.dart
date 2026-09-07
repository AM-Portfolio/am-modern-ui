import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';

/// Shared portfolio-match ring for Discover cards and table.
class DiscoverMatchRing extends StatelessWidget {
  const DiscoverMatchRing({
    super.key,
    required this.score,
    this.size = 48,
    this.showPercentText = true,
  });

  final double score;
  final double size;
  final bool showPercentText;

  @override
  Widget build(BuildContext context) {
    final clamped = score.clamp(0.0, 100.0);
    final color = clamped >= 70
        ? context.statusSuccess
        : clamped >= 40
            ? context.statusWarning
            : context.statusError;
    final stroke = size >= 40 ? 4.0 : 3.0;
    final labelStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w800,
          color: color,
          fontSize: size >= 40 ? 11 : 9,
        );

    // Tight square + Positioned.fill keeps the ring circular (avoids oval stretch
    // when parent flex gives non-square max constraints on web).
    return SizedBox.square(
      dimension: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: clamped / 100),
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOutCubic,
        builder: (context, value, _) {
          return Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: CircularProgressIndicator(
                  value: value,
                  strokeWidth: stroke,
                  strokeCap: StrokeCap.round,
                  backgroundColor: color.withValues(alpha: 0.15),
                  color: color,
                ),
              ),
              if (showPercentText)
                Text(
                  '${clamped.toStringAsFixed(0)}%',
                  style: labelStyle,
                ),
            ],
          );
        },
      ),
    );
  }

  static Color colorFor(BuildContext context, double score) {
    final clamped = score.clamp(0.0, 100.0);
    if (clamped >= 70) return context.statusSuccess;
    if (clamped >= 40) return context.statusWarning;
    return context.statusError;
  }
}
