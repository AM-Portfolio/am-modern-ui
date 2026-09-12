import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';

import '../models/timing_bucket.dart';

/// Avg PnL (expectancy) bar chart — green up / red down.
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
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Avg PnL (₹)',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 160,
            child: buckets.isEmpty
                ? Center(
                    child: Text(
                      emptyMessage ?? 'No data',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                : BarChart(_chartData(theme)),
          ),
        ],
      ),
    );
  }

  BarChartData _chartData(ThemeData theme) {
    final maxAbs = buckets
        .map((b) => b.expectancy.abs())
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
              '${b.label}\n₹${b.expectancy.toStringAsFixed(0)}',
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
                return Text('0',
                    style: theme.textTheme.labelSmall?.copyWith(fontSize: 10));
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
              // Avoid label clutter on dense hour charts.
              final step = buckets.length > 10 ? 2 : 1;
              if (i % step != 0) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  buckets[i].label,
                  style: theme.textTheme.labelSmall?.copyWith(fontSize: 9),
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
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
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
                toY: buckets[i].expectancy,
                width: buckets.length > 12 ? 6 : 10,
                borderRadius: BorderRadius.circular(3),
                color: buckets[i].expectancy >= 0
                    ? ModuleColors.analytics
                    : theme.colorScheme.error,
              ),
            ],
          ),
      ],
    );
  }
}
