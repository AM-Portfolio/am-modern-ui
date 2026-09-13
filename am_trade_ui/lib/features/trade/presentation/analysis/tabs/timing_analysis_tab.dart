import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:am_design_system/am_design_system.dart';

import '../../../internal/domain/entities/metrics/trade_metrics_response.dart';
import '../../metrics/cubit/trade_metrics_cubit.dart';
import '../../metrics/cubit/trade_metrics_state.dart';
import '../models/timing_bucket.dart';
import '../widgets/timing_avg_pnl_chart.dart';
import '../widgets/timing_rank_table.dart';

/// Analysis → Timing: Avg PnL charts + best/worst hour · DOW · month tables.
class TimingAnalysisTab extends StatelessWidget {
  const TimingAnalysisTab({
    super.key,
    required this.cubit,
    required this.onOpenCalendar,
    required this.onOpenJournalInsights,
    required this.onApply,
  });

  final TradeMetricsCubit cubit;
  final VoidCallback onOpenCalendar;
  final VoidCallback onOpenJournalInsights;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TradeMetricsCubit, TradeMetricsState>(
      bloc: cubit,
      builder: (context, state) {
        final tradeCount =
            state is TradeMetricsLoaded ? state.metrics.totalTradesCount : null;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ContextBanner(
              tradeCount: tradeCount,
              onOpenCalendar: onOpenCalendar,
              onOpenJournalInsights: onOpenJournalInsights,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Entry times as stored on the trade (exchange-local; IST for India books).',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.colors.textSecondary,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(child: _buildBody(context, state)),
          ],
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, TradeMetricsState state) {
    final colors = context.colors;
    if (state is TradeMetricsLoading || state is TradeMetricsInitial) {
      return Center(
        child: CircularProgressIndicator(color: ModuleColors.trade),
      );
    }
    if (state is TradeMetricsError) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: context.statusError, size: 40),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Could not load timing metrics',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colors.textPrimary,
                  ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              state.message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              text: 'Retry',
              type: AppButtonType.secondary,
              isOutlined: true,
              icon: Icons.refresh,
              onPressed: onApply,
              height: 36,
              backgroundColor: ModuleColors.trade,
            ),
          ],
        ),
      );
    }
    if (state is TradeMetricsLoaded) {
      return _TimingDashboard(metrics: state.metrics);
    }
    return const SizedBox.shrink();
  }
}

class _ContextBanner extends StatelessWidget {
  const _ContextBanner({
    required this.tradeCount,
    required this.onOpenCalendar,
    required this.onOpenJournalInsights,
  });

  final int? tradeCount;
  final VoidCallback onOpenCalendar;
  final VoidCallback onOpenJournalInsights;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final countLabel = tradeCount == null
        ? '…'
        : NumberFormat.decimalPattern('en_IN').format(tradeCount);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: ModuleColors.trade.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: ModuleColors.trade.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: ModuleColors.trade),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Showing data for $countLabel trades',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: context.colors.textPrimary,
              ),
            ),
          ),
          AppButton(
            text: 'View Calendar',
            type: AppButtonType.text,
            onPressed: onOpenCalendar,
            height: 32,
            textColor: ModuleColors.trade,
          ),
          AppButton(
            text: 'Journal Insights',
            type: AppButtonType.text,
            onPressed: onOpenJournalInsights,
            height: 32,
            textColor: ModuleColors.trade,
          ),
        ],
      ),
    );
  }
}

class _TimingDashboard extends StatelessWidget {
  const _TimingDashboard({required this.metrics});

  final TradeMetricsResponse metrics;

  @override
  Widget build(BuildContext context) {
    final dist = metrics.distributionMetrics;

    final hours = buildTimingBuckets(
      trades: dist.tradesByHour,
      profit: dist.profitByHour,
      winRate: dist.winRateByHour,
      labelFor: formatEntryHourLabel,
    );
    final days = buildTimingBuckets(
      trades: dist.tradesByDay,
      profit: dist.profitByDay,
      winRate: dist.winRateByDay,
      labelFor: formatWeekdayLabel,
    );
    final months = buildTimingBuckets(
      trades: dist.tradesByMonth,
      profit: dist.profitByMonth,
      winRate: dist.winRateByMonth,
      labelFor: formatMonthLabel,
    );

    final hourChart = sortForChart(hours, TimingDimension.hour);
    final dayChart = sortForChart(days, TimingDimension.weekday);
    final monthChart = sortForChart(months, TimingDimension.month);

    final hourSplit = splitBestWorst(hours);
    final daySplit = splitBestWorst(days);
    final monthSplit = splitBestWorst(months);

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 980;

        final charts = [
          TimingAvgPnlChart(
            title: 'Performance by Hour (Entry Time)',
            buckets: hourChart,
            emptyMessage:
                'No hour breakdown yet.\nEntry timestamps required.',
          ),
          TimingAvgPnlChart(
            title: 'Performance by Day of Week',
            buckets: dayChart,
          ),
          TimingAvgPnlChart(
            title: 'Performance by Month',
            buckets: monthChart,
          ),
        ];

        final bestTables = [
          TimingRankTable(
            title: 'Best Hours',
            bucketLabel: 'Hour',
            rows: hourSplit.best,
            isBest: true,
            emptyMessage: 'No hour data yet',
          ),
          TimingRankTable(
            title: 'Best Days',
            bucketLabel: 'Day',
            rows: daySplit.best,
            isBest: true,
          ),
          TimingRankTable(
            title: 'Best Months',
            bucketLabel: 'Month',
            rows: monthSplit.best,
            isBest: true,
          ),
        ];

        final worstTables = [
          TimingRankTable(
            title: 'Worst Hours',
            bucketLabel: 'Hour',
            rows: hourSplit.worst,
            isBest: false,
            emptyMessage: hourSplit.best.isEmpty
                ? 'No hour data yet'
                : 'Not enough buckets to rank worst',
          ),
          TimingRankTable(
            title: 'Worst Days',
            bucketLabel: 'Day',
            rows: daySplit.worst,
            isBest: false,
          ),
          TimingRankTable(
            title: 'Worst Months',
            bucketLabel: 'Month',
            rows: monthSplit.worst,
            isBest: false,
          ),
        ];

        Widget threeCol(List<Widget> children) {
          if (wide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  if (i > 0) const SizedBox(width: AppSpacing.md),
                  Expanded(child: children[i]),
                ],
              ],
            );
          }
          return Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) const SizedBox(height: AppSpacing.md),
                children[i],
              ],
            ],
          );
        }

        return ListView(
          children: [
            threeCol(charts),
            const SizedBox(height: AppSpacing.md),
            threeCol(bestTables),
            const SizedBox(height: AppSpacing.md),
            threeCol(worstTables),
            const SizedBox(height: AppSpacing.sm),
          ],
        );
      },
    );
  }
}
