import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:am_design_system/am_design_system.dart';

import '../models/timing_bucket.dart';

/// Avg PnL bar chart — semantic success up / error down.
class TimingAvgPnlChart extends StatelessWidget {
  const TimingAvgPnlChart({
    super.key,
    required this.title,
    required this.buckets,
    this.avgAxisLabel = 'Avg PnL (₹)',
    this.emptyMessage,
  });

  final String title;
  final List<TimingBucket> buckets;
  final String avgAxisLabel;
  final String? emptyMessage;

  static final _inr = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  static String _signedInr(double value) {
    final formatted = _inr.format(value.abs());
    if (value > 0) return '+$formatted';
    if (value < 0) return '-$formatted';
    return formatted;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final ranked = buckets.where((b) => b.trades > 0).toList()
      ..sort((a, b) => b.avgPnl.compareTo(a.avgPnl));
    final best = ranked.isEmpty ? null : ranked.first;
    final weakest = ranked.length < 2 ? null : ranked.last;

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: context.text.sectionTitle(compact: true).copyWith(
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
              Text(
                avgAxisLabel,
                style: context.text.caption(compact: true).copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 200,
            child: buckets.isEmpty
                ? Center(
                    child: Text(
                      emptyMessage ?? 'No data',
                      style: context.text.bodyMuted(compact: true).copyWith(
                        color: colors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                : BarChart(_chartData(context)),
          ),
          if (best != null || weakest != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.sm,
              alignment: WrapAlignment.spaceBetween,
              children: [
                if (weakest != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xxs,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: context.statusError.withValues(alpha: 0.5)),
                          borderRadius: BorderRadius.circular(AppRadii.md),
                        ),
                        child: Text(
                          'Weakest: ${weakest.label}',
                          style: context.text.caption(compact: true).copyWith(
                            color: context.statusError,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        _signedInr(weakest.avgPnl),
                        style: context.text.caption(compact: true).copyWith(
                          color: context.statusError,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                if (best != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xxs,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: context.statusSuccess.withValues(alpha: 0.5)),
                          borderRadius: BorderRadius.circular(AppRadii.md),
                        ),
                        child: Text(
                          'Best: ${best.label}',
                          style: context.text.caption(compact: true).copyWith(
                            color: context.statusSuccess,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        _signedInr(best.avgPnl),
                        style: context.text.caption(compact: true).copyWith(
                          color: context.statusSuccess,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
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
              context.text.caption().copyWith(
                color: theme.colorScheme.onInverseSurface,
                fontWeight: FontWeight.w600,
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
              if (value == 0 || (value.abs() - pad).abs() < 1e-4) {
                String text;
                if (value == 0) {
                  text = '0';
                } else {
                  final absVal = value.abs();
                  text = absVal >= 1000 
                      ? '${(absVal / 1000).toStringAsFixed(0)}K' 
                      : absVal.toStringAsFixed(0);
                  if (value < 0) text = '-$text';
                }
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.xs),
                  child: Text(
                    text,
                    style: context.text.caption(compact: true).copyWith(
                      color: colors.textSecondary,
                    ),
                    textAlign: TextAlign.right,
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
                  style: context.text.caption(compact: true).copyWith(
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
        horizontalInterval: pad > 0 ? pad : 1,
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
                toY: buckets[i].avgPnl == 0 ? (pad * 0.015) : buckets[i].avgPnl,
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
