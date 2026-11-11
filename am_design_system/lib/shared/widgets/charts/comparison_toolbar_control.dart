import 'package:flutter/material.dart';

import '../../../core/theme/app_radii.dart';
import '../../../core/theme/color_extensions.dart';

/// Canonical height for comparison-chart header controls (compact premium).
const double kComparisonChartHeaderRowHeight = 28.0;

/// Equal gap between 1D / + / expand (and other header controls).
const double kComparisonChartToolbarGap = 4.0;

/// Shared chrome for comparison-chart toolbar controls (TF, +, expand, legend).
class ComparisonToolbarControl extends StatelessWidget {
  const ComparisonToolbarControl({
    required this.child,
    required this.accentColor,
    super.key,
    this.borderColor,
    this.square = false,
    this.onTap,
    this.height = kComparisonChartHeaderRowHeight,
  });

  final Widget child;
  final Color accentColor;
  final Color? borderColor;
  final bool square;
  final VoidCallback? onTap;
  final double height;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final border = borderColor ?? accentColor.withValues(alpha: 0.35);
    final radius = BorderRadius.circular(AppRadii.xs);

    final box = Container(
      height: height,
      width: square ? height : null,
      padding: square
          ? EdgeInsets.zero
          : const EdgeInsets.symmetric(horizontal: 6),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.cardSurface,
        borderRadius: radius,
        border: Border.all(color: border, width: 1),
      ),
      child: child,
    );

    if (onTap == null) return box;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: box,
      ),
    );
  }
}
