import 'package:flutter/material.dart';

import 'comparison_toolbar_control.dart';

/// Series legend chip for comparison charts (swatch + label + optional metrics).
class ChartSeriesLegendChip extends StatelessWidget {
  const ChartSeriesLegendChip({
    required this.label,
    required this.seriesColor,
    super.key,
    this.priceLabel,
    this.changePct,
    this.hidden = false,
    this.compact = false,
  });

  final String label;
  final Color seriesColor;
  final String? priceLabel;
  final double? changePct;
  final bool hidden;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = Colors.grey;
    final labelColor = hidden
        ? muted
        : (isDark ? Colors.white70 : Colors.black87);
    final priceColor = hidden
        ? muted
        : (isDark ? Colors.white : Colors.black);
    final changeColor = hidden
        ? muted
        : (changePct != null && changePct! >= 0
            ? (isDark ? const Color(0xFF00FF9D) : Colors.green.shade700)
            : (isDark ? const Color(0xFFFF5252) : Colors.red.shade700));
    final fontSize = compact ? 10.0 : 11.0;
    final changeSize = compact ? 9.0 : 10.0;

    return ComparisonToolbarControl(
      accentColor: seriesColor,
      borderColor: hidden
          ? muted.withValues(alpha: 0.3)
          : seriesColor.withValues(alpha: 0.4),
      height: compact ? 26 : kComparisonChartHeaderRowHeight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: compact ? 8 : 10,
            height: 2,
            decoration: BoxDecoration(
              color: hidden ? muted : seriesColor,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: labelColor,
              decoration: hidden ? TextDecoration.lineThrough : null,
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              height: 1.1,
            ),
          ),
          if (priceLabel != null && priceLabel!.isNotEmpty) ...[
            const SizedBox(width: 4),
            Text(
              priceLabel!,
              style: TextStyle(
                color: priceColor,
                fontSize: fontSize,
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
            ),
          ],
          if (changePct != null) ...[
            const SizedBox(width: 3),
            Text(
              '${changePct! >= 0 ? '+' : ''}${changePct!.toStringAsFixed(2)}%',
              style: TextStyle(
                color: changeColor,
                fontSize: changeSize,
                fontWeight: FontWeight.w700,
                height: 1.1,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
