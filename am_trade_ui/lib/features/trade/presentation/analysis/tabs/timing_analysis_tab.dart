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
class TimingAnalysisTab extends StatefulWidget {
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
  State<TimingAnalysisTab> createState() => _TimingAnalysisTabState();
}

class _TimingAnalysisTabState extends State<TimingAnalysisTab> {
  TimingAvgBasis _avgBasis = TimingAvgBasis.perTrade;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TradeMetricsCubit, TradeMetricsState>(
      bloc: widget.cubit,
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
              onOpenCalendar: widget.onOpenCalendar,
              onOpenJournalInsights: widget.onOpenJournalInsights,
            ),
            _AvgBasisFilter(
              selected: _avgBasis,
              onChanged: (b) => setState(() => _avgBasis = b),
            ),
            const SizedBox(height: AppSpacing.sm),
            TimingKpiRow(
              performance: perf,
              distribution: dist,
              totalTradesCount: tradeCount,
              avgBasis: _avgBasis,
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(child: _buildBody(context, state)),
          ],
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, TradeMetricsState state) {
    if (state is TradeMetricsLoading || state is TradeMetricsInitial) {
      return Center(
        child: CircularProgressIndicator(color: ModuleColors.trade),
      );
    }
    if (state is TradeMetricsError) {
      return AmErrorWidget(
        message: 'Could not load timing metrics\n${state.message}',
        onRetry: widget.onApply,
      );
    }
    if (state is TradeMetricsLoaded) {
      final metrics = state.metrics;
      if (metrics.totalTradesCount <= 0) {
        return _EmptyTimingState(onRetry: widget.onApply);
      }
      return _TimingDashboard(metrics: metrics, avgBasis: _avgBasis);
    }
    return const SizedBox.shrink();
  }
}

class _AvgBasisFilter extends StatelessWidget {
  const _AvgBasisFilter({
    required this.selected,
    required this.onChanged,
  });

  final TimingAvgBasis selected;
  final ValueChanged<TimingAvgBasis> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    Widget pill(String label, TimingAvgBasis value) {
      return AmToggleChip(
        label: label,
        selected: selected == value,
        compact: true,
        accentColor: ModuleColors.trade,
        onTap: () => onChanged(value),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Row(
        children: [
          Text(
            'Avg basis:',
            style: context.text.label(compact: true).copyWith(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(width: AppSpacing.sm),
          pill(timingAvgBasisLabel(TimingAvgBasis.perTrade),
              TimingAvgBasis.perTrade),
          const SizedBox(width: AppSpacing.sm),
          pill(timingAvgBasisLabel(TimingAvgBasis.perActiveDay),
              TimingAvgBasis.perActiveDay),
        ],
      ),
    );
  }
}

class _EmptyTimingState extends StatelessWidget {
  const _EmptyTimingState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.insights_outlined,
                size: 44, color: colors.textSecondary),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No trades in this portfolio / range',
              style: context.text.sectionTitle(compact: true).copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Select the same portfolio you use in production '
              '(sidebar → Current Portfolio), keep “All time”, then Apply. '
              'Timing charts and the breakdown table will fill once trades load.',
              style: context.text.bodyMuted(compact: true).copyWith(
                    color: colors.textSecondary,
                    height: 1.4,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              text: 'Retry',
              type: AppButtonType.secondary,
              isOutlined: true,
              icon: Icons.refresh,
              onPressed: onRetry,
              height: 36,
              backgroundColor: ModuleColors.trade,
            ),
          ],
        ),
      ),
    );
  }
}

class _TimingDashboard extends StatefulWidget {
  const _TimingDashboard({
    required this.metrics,
    required this.avgBasis,
  });

  final TradeMetricsResponse metrics;
  final TimingAvgBasis avgBasis;

  @override
  State<_TimingDashboard> createState() => _TimingDashboardState();
}

class _TimingDashboardState extends State<_TimingDashboard> {
  TimingDimension _dimension = TimingDimension.session;
  TimingRankView _rankView = TimingRankView.all;

  @override
  Widget build(BuildContext context) {
    final dist = widget.metrics.distributionMetrics;
    final basis = widget.avgBasis;

    final sessions = buildTimingBuckets(
      trades: dist.tradesBySession,
      profit: dist.profitBySession,
      winRate: dist.winRateBySession,
      avgPnl: dist.avgPnlBySession,
      avgPnlPerActiveDay: dist.avgPnlPerActiveDayBySession,
      eligible: dist.eligibleTradesBySession,
      activeTradingDays: dist.activeTradingDaysBySession,
      avgHoldMinutes: dist.avgHoldMinutesBySession,
      riskReward: dist.riskRewardBySession,
      labelFor: formatSessionLabel,
      includeZeroTradeBuckets: true,
      orderedKeys: kSessionKeys,
      avgBasis: basis,
    );
    final days = buildTimingBuckets(
      trades: dist.tradesByDay,
      profit: dist.profitByDay,
      winRate: dist.winRateByDay,
      avgPnl: dist.avgPnlByDay,
      avgPnlPerActiveDay: dist.avgPnlPerActiveDayByDay,
      eligible: dist.eligibleTradesByDay,
      activeTradingDays: dist.activeTradingDaysByDay,
      avgHoldMinutes: dist.avgHoldMinutesByDay,
      riskReward: dist.riskRewardByDay,
      labelFor: formatWeekdayLabel,
      avgBasis: basis,
    );
    final months = buildTimingBuckets(
      trades: dist.tradesByMonth,
      profit: dist.profitByMonth,
      winRate: dist.winRateByMonth,
      avgPnl: dist.avgPnlByMonth,
      avgPnlPerActiveDay: dist.avgPnlPerActiveDayByMonth,
      eligible: dist.eligibleTradesByMonth,
      activeTradingDays: dist.activeTradingDaysByMonth,
      avgHoldMinutes: dist.avgHoldMinutesByMonth,
      riskReward: dist.riskRewardByMonth,
      labelFor: formatMonthLabel,
      avgBasis: basis,
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
    final avgAxis = timingAvgAxisLabel(basis);

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 980;

        final charts = [
          TimingAvgPnlChart(
            title: 'Performance by Session (Entry Time)',
            buckets: sessionChart,
            avgAxisLabel: avgAxis,
            emptyMessage:
                'No session breakdown yet.\nEntry timestamps required.',
          ),
          TimingAvgPnlChart(
            title: 'Performance by Day of Week',
            buckets: dayChart,
            avgAxisLabel: avgAxis,
          ),
          TimingAvgPnlChart(
            title: 'Performance by Month',
            buckets: monthChart,
            avgAxisLabel: avgAxis,
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
              rowCount: rankRows.length,
              bucketLabel: bucketLabel,
            ),
            const SizedBox(height: AppSpacing.sm),
            TimingRankTable(
              title: rankTitle,
              bucketLabel: bucketLabel,
              rows: rankRows,
              avgColumnLabel: basis == TimingAvgBasis.perActiveDay
                  ? 'AVG / DAY (₹)'
                  : 'AVG / TRADE (₹)',
              emptyMessage: emptyRank,
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
    required this.rowCount,
    required this.bucketLabel,
  });

  final TimingDimension dimension;
  final TimingRankView rankView;
  final ValueChanged<TimingDimension> onDimension;
  final ValueChanged<TimingRankView> onRankView;
  final int rowCount;
  final String bucketLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final labelStyle = context.text.label(compact: true).copyWith(
          color: colors.textSecondary,
          fontWeight: FontWeight.w600,
        );

    Widget group({
      required String label,
      required List<Widget> chips,
    }) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: labelStyle),
          const SizedBox(width: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            children: chips,
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              group(
                label: 'Dimension:',
                chips: [
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
                ],
              ),
              group(
                label: 'View:',
                chips: [
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
              ),
            ],
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.table_rows_outlined, size: 16, color: colors.textSecondary),
            const SizedBox(width: AppSpacing.xs),
            Text(
              'Showing $rowCount '
              '${rowCount == 1 ? bucketLabel.toLowerCase() : '${bucketLabel.toLowerCase()}s'}',
              style: context.text.caption(compact: true).copyWith(
                    color: colors.textSecondary,
                  ),
            ),
          ],
        ),
      ],
    );
  }
}
