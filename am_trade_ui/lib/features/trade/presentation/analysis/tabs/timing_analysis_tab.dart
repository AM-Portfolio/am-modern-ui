import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:am_design_system/am_design_system.dart';

import '../../../internal/domain/entities/metrics/trade_metrics_response.dart';
import '../../metrics/cubit/trade_metrics_cubit.dart';
import '../../metrics/cubit/trade_metrics_state.dart';
import '../models/timing_bucket.dart';
import '../widgets/timing_avg_pnl_chart.dart';
import '../widgets/timing_insights_banner.dart';
import '../widgets/timing_kpi_row.dart';
import '../widgets/timing_rank_table.dart';

/// Analysis → Timing: insights, KPIs, session/day/month charts + rank table.
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
        final dist = state is TradeMetricsLoaded
            ? state.metrics.distributionMetrics
            : null;
        final perf = state is TradeMetricsLoaded
            ? state.metrics.performanceMetrics
            : null;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TimingInsightsBanner(
              tradeCount: tradeCount,
              styleHint: dist?.tradingStyleHint,
              timezoneNote: dist?.timezoneNote,
              skippedMissingEntry: dist?.skippedMissingEntryCount ?? 0,
              openOrMissingPnl: dist?.openOrMissingPnlCount ?? 0,
              badTimestamp: dist?.badTimestampCount ?? 0,
              onOpenCalendar: onOpenCalendar,
              onOpenJournalInsights: onOpenJournalInsights,
            ),
            const SizedBox(height: AppSpacing.md),
            TimingKpiRow(
              performance: perf,
              distribution: dist,
              totalTradesCount: tradeCount,
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

class _TimingDashboard extends StatefulWidget {
  const _TimingDashboard({required this.metrics});

  final TradeMetricsResponse metrics;

  @override
  State<_TimingDashboard> createState() => _TimingDashboardState();
}

class _TimingDashboardState extends State<_TimingDashboard> {
  TimingDimension _dimension = TimingDimension.session;
  TimingRankView _rankView = TimingRankView.all;

  @override
  Widget build(BuildContext context) {
    final dist = widget.metrics.distributionMetrics;

    final sessions = buildTimingBuckets(
      trades: dist.tradesBySession,
      profit: dist.profitBySession,
      winRate: dist.winRateBySession,
      avgPnl: dist.avgPnlBySession,
      eligible: dist.eligibleTradesBySession,
      avgHoldMinutes: dist.avgHoldMinutesBySession,
      riskReward: dist.riskRewardBySession,
      labelFor: formatSessionLabel,
      includeZeroTradeBuckets: true,
      orderedKeys: kSessionKeys,
    );
    final days = buildTimingBuckets(
      trades: dist.tradesByDay,
      profit: dist.profitByDay,
      winRate: dist.winRateByDay,
      avgPnl: dist.avgPnlByDay,
      eligible: dist.eligibleTradesByDay,
      avgHoldMinutes: dist.avgHoldMinutesByDay,
      riskReward: dist.riskRewardByDay,
      labelFor: formatWeekdayLabel,
    );
    final months = buildTimingBuckets(
      trades: dist.tradesByMonth,
      profit: dist.profitByMonth,
      winRate: dist.winRateByMonth,
      avgPnl: dist.avgPnlByMonth,
      eligible: dist.eligibleTradesByMonth,
      avgHoldMinutes: dist.avgHoldMinutesByMonth,
      riskReward: dist.riskRewardByMonth,
      labelFor: formatMonthLabel,
    );

    final sessionChart = sortForChart(sessions, TimingDimension.session);
    final dayChart = sortForChart(days, TimingDimension.weekday);
    final monthChart = sortForChart(months, TimingDimension.month);

    final activeBuckets = switch (_dimension) {
      TimingDimension.session => sessions,
      TimingDimension.weekday => days,
      TimingDimension.month => months,
    };
    final rankRows = rowsForRankView(activeBuckets, _rankView);
    final bucketLabel = switch (_dimension) {
      TimingDimension.session => 'Session',
      TimingDimension.weekday => 'Day',
      TimingDimension.month => 'Month',
    };
    final rankTitle = 'Breakdown ($bucketLabel)';
    final emptyRank = _rankView == TimingRankView.all
        ? 'No timing data yet'
        : 'Need at least $minTradesForRank trades with PnL in a bucket to rank';

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 980;

        final charts = [
          TimingAvgPnlChart(
            title: 'Performance by Session (Entry Time)',
            buckets: sessionChart,
            emptyMessage:
                'No session breakdown yet.\nEntry timestamps required.',
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
            const SizedBox(height: AppSpacing.lg),
            _RankControls(
              dimension: _dimension,
              rankView: _rankView,
              onDimension: (d) => setState(() => _dimension = d),
              onRankView: (v) => setState(() => _rankView = v),
            ),
            const SizedBox(height: AppSpacing.sm),
            TimingRankTable(
              title: rankTitle,
              bucketLabel: bucketLabel,
              rows: rankRows,
              emptyMessage: emptyRank,
              subtitle: switch (_rankView) {
                TimingRankView.all => 'All · ranked by Avg PnL',
                TimingRankView.best => 'Best · ranked by Avg PnL',
                TimingRankView.worst => 'Worst · ranked by Avg PnL',
              },
              showLowSampleBadges: _rankView == TimingRankView.all,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        );
      },
    );
  }
}

class _RankControls extends StatelessWidget {
  const _RankControls({
    required this.dimension,
    required this.rankView,
    required this.onDimension,
    required this.onRankView,
  });

  final TimingDimension dimension;
  final TimingRankView rankView;
  final ValueChanged<TimingDimension> onDimension;
  final ValueChanged<TimingRankView> onRankView;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final labelStyle = Theme.of(context).textTheme.labelMedium?.copyWith(
          color: colors.textSecondary,
          fontWeight: FontWeight.w600,
        );

    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text('Dimension:', style: labelStyle),
        AmToggleChip(
          label: 'Session',
          selected: dimension == TimingDimension.session,
          compact: true,
          accentColor: ModuleColors.trade,
          onTap: () => onDimension(TimingDimension.session),
        ),
        AmToggleChip(
          label: 'Day',
          selected: dimension == TimingDimension.weekday,
          compact: true,
          accentColor: ModuleColors.trade,
          onTap: () => onDimension(TimingDimension.weekday),
        ),
        AmToggleChip(
          label: 'Month',
          selected: dimension == TimingDimension.month,
          compact: true,
          accentColor: ModuleColors.trade,
          onTap: () => onDimension(TimingDimension.month),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text('View:', style: labelStyle),
        AmToggleChip(
          label: 'All',
          selected: rankView == TimingRankView.all,
          compact: true,
          accentColor: ModuleColors.trade,
          onTap: () => onRankView(TimingRankView.all),
        ),
        AmToggleChip(
          label: 'Best',
          selected: rankView == TimingRankView.best,
          compact: true,
          accentColor: ModuleColors.trade,
          onTap: () => onRankView(TimingRankView.best),
        ),
        AmToggleChip(
          label: 'Worst',
          selected: rankView == TimingRankView.worst,
          compact: true,
          accentColor: ModuleColors.trade,
          onTap: () => onRankView(TimingRankView.worst),
        ),
      ],
    );
  }
}
