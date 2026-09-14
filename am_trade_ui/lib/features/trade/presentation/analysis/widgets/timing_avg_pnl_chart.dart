import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';

import '../models/timing_bucket.dart';

/// Avg PnL bar chart — semantic success up / error down.
class TimingAvgPnlChart extends StatelessWidget {
  const TimingAvgPnlChart({
    super.key,
    required this.title,
    required this.buckets,
    this.emptyMessage,
  });

  final String title;
  final List<TimingBucket> buckets;
  final String? emptyMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: colors.cardSurface,
        borderRadius: AppRadii.card,
        border: Border.all(
          color: colors.border.withValues(alpha: 0.45),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm + AppSpacing.xs,
        AppSpacing.sm + AppSpacing.xs,
        AppSpacing.sm + AppSpacing.xs,
        AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Avg PnL (₹)',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 160,
            child: buckets.isEmpty
                ? Center(
                    child: Text(
                      emptyMessage ?? 'No data',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                : BarChart(_chartData(context)),
          ),
        ],
      ),
    );
  }

  BarChartData _chartData(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;
    final success = context.statusSuccess;
    final error = context.statusError;
    final maxAbs = buckets
        .map((b) => b.avgPnl.abs())
        .fold<double>(0, (a, b) => a > b ? a : b);
    final pad = maxAbs == 0 ? 100.0 : maxAbs * 1.2;

    return BarChartData(
      alignment: BarChartAlignment.spaceAround,
      maxY: pad,
      minY: -pad,
      barTouchData: BarTouchData(
        enabled: true,
        touchTooltipData: BarTouchTooltipData(
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            final b = buckets[group.x.toInt()];
            return BarTooltipItem(
              '${b.label}\n₹${b.avgPnl.toStringAsFixed(0)}',
              TextStyle(
                color: theme.colorScheme.onInverseSurface,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            );
          },
        ),
      ),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 36,
            getTitlesWidget: (value, meta) {
              if (value == 0) {
                return Text(
                  '0',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 10,
                    color: colors.textSecondary,
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 22,
            getTitlesWidget: (value, meta) {
              final i = value.toInt();
              if (i < 0 || i >= buckets.length) {
                return const SizedBox.shrink();
              }
              final step = buckets.length > 10 ? 2 : 1;
              if (i % step != 0) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text(
                  buckets[i].label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 9,
                    color: colors.textSecondary,
                  ),
                ),
              );
            },
          ),
        ),
      ),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: pad,
        getDrawingHorizontalLine: (value) => FlLine(
          color: colors.border.withValues(alpha: 0.4),
          strokeWidth: 1,
        ),
      ),
      borderData: FlBorderData(show: false),
      barGroups: [
        for (var i = 0; i < buckets.length; i++)
          BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: buckets[i].avgPnl,
                width: buckets.length > 12 ? 6 : 10,
                borderRadius: BorderRadius.circular(AppRadii.xs),
                color: buckets[i].trades == 0
                    ? colors.border.withValues(alpha: 0.35)
                    : (buckets[i].avgPnl >= 0 ? success : error),
              ),
            ],
          ),
      ],
    );
  }
}
