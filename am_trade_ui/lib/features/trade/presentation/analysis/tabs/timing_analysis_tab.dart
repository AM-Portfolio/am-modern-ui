import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:am_design_system/am_design_system.dart';

import '../../../internal/domain/entities/metrics/trade_distribution_metrics.dart';
import '../../../internal/domain/entities/metrics/trade_metrics_response.dart';
import '../../metrics/cubit/trade_metrics_cubit.dart';
import '../../metrics/cubit/trade_metrics_state.dart';
import '../models/timing_bucket.dart';
import '../widgets/timing_avg_pnl_chart.dart';
import '../widgets/timing_rank_table.dart';

/// Analysis → Timing: session/day/month charts + one All/Best/Worst rank card.
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

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ContextBanner(
              tradeCount: tradeCount,
              skippedMissingEntry: dist?.skippedMissingEntryCount ?? 0,
              openOrMissingPnl: dist?.openOrMissingPnlCount ?? 0,
              badTimestamp: dist?.badTimestampCount ?? 0,
              onOpenCalendar: onOpenCalendar,
              onOpenJournalInsights: onOpenJournalInsights,
            ),
            const SizedBox(height: AppSpacing.sm),
            if (dist?.tradingStyleHint != null) ...[
              _StyleHintChip(hint: dist!.tradingStyleHint!),
              const SizedBox(height: AppSpacing.sm),
            ],
            Text(
              'Entry times as stored on the trade '
              '(${dist?.timezoneNote ?? 'entry_local_as_stored'}; typically IST for India books). '
              'NSE session windows; lunch sits inside 1:00–3:00.',
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
    required this.skippedMissingEntry,
    required this.openOrMissingPnl,
    required this.badTimestamp,
    required this.onOpenCalendar,
    required this.onOpenJournalInsights,
  });

  final int? tradeCount;
  final int skippedMissingEntry;
  final int openOrMissingPnl;
  final int badTimestamp;
  final VoidCallback onOpenCalendar;
  final VoidCallback onOpenJournalInsights;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final countLabel = tradeCount == null
        ? '…'
        : NumberFormat.decimalPattern('en_IN').format(tradeCount);

    final secondaryParts = <String>[];
    if (skippedMissingEntry > 0) {
      secondaryParts.add('$skippedMissingEntry skipped (no entry time)');
    }
    if (openOrMissingPnl > 0) {
      secondaryParts.add(
        '$openOrMissingPnl open/missing PnL excluded from Win% and Avg PnL',
      );
    }
    if (badTimestamp > 0) {
      secondaryParts.add('$badTimestamp bad timestamps excluded from style');
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: ModuleColors.trade.withValues(alpha: 0.08),
        borderRadius: AppRadii.card,
        border: Border.all(
          color: ModuleColors.trade.withValues(alpha: 0.28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 18, color: ModuleColors.trade),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: context.colors.textPrimary,
                    ),
                    children: [
                      const TextSpan(text: 'Showing data for '),
                      TextSpan(
                        text: '$countLabel trades',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      if (secondaryParts.isNotEmpty)
                        TextSpan(
                          text: '. ${secondaryParts.join(' · ')}',
                          style: TextStyle(
                            color: context.colors.textSecondary,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              AppButton(
                text: 'View Calendar',
                type: AppButtonType.text,
                onPressed: onOpenCalendar,
                height: 36,
                textColor: ModuleColors.trade,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              ),
              AppButton(
                text: 'Journal Insights',
                type: AppButtonType.text,
                onPressed: onOpenJournalInsights,
                height: 36,
                textColor: ModuleColors.trade,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StyleHintChip extends StatelessWidget {
  const _StyleHintChip({required this.hint});

  final TradingStyleHint hint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;
    final label = styleHintDisplayLabel(hint.style);
    final isUnknown = hint.style.toUpperCase() == 'UNKNOWN';

    final primary = isUnknown
        ? 'Book style (from hold time): Not enough closed trades to infer style'
        : 'Book style (from hold time): Mostly $label · '
            '${hint.confidencePercent.toStringAsFixed(0)}% of ${hint.sampleSize} trades';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.cardSurface,
        borderRadius: AppRadii.card,
        border: Border.all(
          color: ModuleColors.trade.withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.menu_book_outlined, size: 20, color: ModuleColors.trade),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  primary,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Inferred from hold time in the current filters (date + holding style). '
                  'Does not change session time windows — use the Holding style chips to filter.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
      labelFor: formatWeekdayLabel,
    );
    final months = buildTimingBuckets(
      trades: dist.tradesByMonth,
      profit: dist.profitByMonth,
      winRate: dist.winRateByMonth,
      avgPnl: dist.avgPnlByMonth,
      eligible: dist.eligibleTradesByMonth,
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
    final rankTitle = switch (_rankView) {
      TimingRankView.all => 'All $bucketLabel',
      TimingRankView.best => 'Best $bucketLabel',
      TimingRankView.worst => 'Worst $bucketLabel',
    };
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
              showLowSampleBadges: _rankView == TimingRankView.all,
            ),
            const SizedBox(height: AppSpacing.md),
            const _EntryExampleTip(),
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

    Widget chipGroup<T>({
      required String label,
      required List<(T, String)> options,
      required T selected,
      required ValueChanged<T> onChanged,
    }) {
      return Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(label, style: labelStyle),
          for (final (value, text) in options)
            AmToggleChip(
              label: text,
              selected: selected == value,
              compact: true,
              accentColor: ModuleColors.trade,
              onTap: () => onChanged(value),
            ),
        ],
      );
    }

    return Wrap(
      spacing: AppSpacing.lg,
      runSpacing: AppSpacing.sm,
      children: [
        chipGroup<TimingDimension>(
          label: 'Dimension',
          options: const [
            (TimingDimension.session, 'Session'),
            (TimingDimension.weekday, 'Day'),
            (TimingDimension.month, 'Month'),
          ],
          selected: dimension,
          onChanged: onDimension,
        ),
        chipGroup<TimingRankView>(
          label: 'View',
          options: const [
            (TimingRankView.all, 'All'),
            (TimingRankView.best, 'Best'),
            (TimingRankView.worst, 'Worst'),
          ],
          selected: rankView,
          onChanged: onRankView,
        ),
      ],
    );
  }
}

class _EntryExampleTip extends StatelessWidget {
  const _EntryExampleTip();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: ModuleColors.trade.withValues(alpha: 0.08),
        borderRadius: AppRadii.card,
        border: Border.all(
          color: ModuleColors.trade.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline, size: 18, color: ModuleColors.trade),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: theme.textTheme.bodySmall?.copyWith(
                  color: context.colors.textPrimary,
                  height: 1.4,
                ),
                children: const [
                  TextSpan(
                    text: 'Example: ',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(
                    text:
                        'Buy at 10:00 / Sell at 15:00 → Session bucket 9:15–11:00 '
                        '(entry time). Holding style: Intraday (~5 hours).',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
