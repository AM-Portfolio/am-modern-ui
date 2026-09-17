import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:am_design_system/am_design_system.dart';

import '../../../internal/domain/entities/metrics/trade_distribution_metrics.dart';
import '../models/timing_bucket.dart';
import 'timing_kpi_math.dart';

/// Five Timing KPI cards: Total P&L, Avg P&L, Win Rate, Best Session, Avg Hold.
/// All values come from distribution session maps (Timing universe) — never
/// PERFORMANCE fallbacks for Total / Avg / Win Rate / Hold.
class TimingKpiRow extends StatelessWidget {
  const TimingKpiRow({
    super.key,
    required this.distribution,
    this.avgBasis = TimingAvgBasis.perTrade,
  });

  final TradeDistributionMetrics? distribution;
  final TimingAvgBasis avgBasis;

  static final _inr = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context) {
    final dist = distribution;

    final totalPnl = timingTotalPnl(dist);
    final avgPnl = timingAvgPnlForBasis(dist, avgBasis);
    final winRate = timingWinRate(dist);
    final winCounts = timingWinCounts(dist);
    final holdMinutes = timingAvgHoldMinutes(dist);

    String? bestLabel;
    String? bestSub;
    if (dist != null) {
      final sessions = buildTimingBuckets(
        trades: dist.tradesBySession,
        profit: dist.profitBySession,
        winRate: dist.winRateBySession,
        avgPnl: dist.avgPnlBySession,
        avgPnlPerActiveDay: dist.avgPnlPerActiveDayBySession,
        eligible: dist.eligibleTradesBySession,
        activeTradingDays: dist.activeTradingDaysBySession,
        labelFor: formatSessionLabel,
        includeZeroTradeBuckets: true,
        orderedKeys: kSessionKeys,
        avgBasis: avgBasis,
      );
      final ranked = qualifyingForRank(sessions);
      if (ranked.isNotEmpty) {
        final best = sortByAvgPnlDesc(ranked).first;
        bestLabel = best.label;
        final basisHint =
            avgBasis == TimingAvgBasis.perActiveDay ? '/ day' : '/ trade';
        bestSub =
            '${best.avgPnl >= 0 ? '+' : ''}${_inr.format(best.avgPnl)} avg$basisHint';
      } else if (dist.bestSessionKey != null &&
          avgBasis == TimingAvgBasis.perTrade) {
        bestLabel = formatSessionLabel(dist.bestSessionKey!);
        final avg = dist.bestSessionAvgPnl;
        if (avg != null) {
          bestSub = '${avg >= 0 ? '+' : ''}${_inr.format(avg)} avg / trade';
        }
      }
    }

    final pnlSparklineData = dist?.profitByMonth.values.toList() ?? [];
    final avgPnlSparklineData = avgBasis == TimingAvgBasis.perActiveDay
        ? (dist?.avgPnlPerActiveDayByMonth.values.toList() ?? [])
        : (dist?.avgPnlByMonth.values.toList() ?? []);
    final sessionAvgPnlData = avgBasis == TimingAvgBasis.perActiveDay
        ? (dist?.avgPnlPerActiveDayBySession.values.toList() ?? [])
        : (dist?.avgPnlBySession.values.toList() ?? []);

    final totalColorSign = totalPnl ?? sparklineSeriesSign(pnlSparklineData);
    final avgColorSign = avgPnl ?? sparklineSeriesSign(avgPnlSparklineData);

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        final cards = [
          _KpiCard(
            title: 'Total P&L',
            value: totalPnl == null ? '—' : _signedInr(totalPnl),
            valueColor: totalPnl == null
                ? null
                : (totalPnl >= 0
                    ? context.statusSuccess
                    : context.statusError),
            sparkline: pnlSparklineData.isEmpty
                ? null
                : AmSparklineChart(
                    data: pnlSparklineData,
                    color: totalColorSign >= 0
                        ? context.statusSuccess
                        : context.statusError,
                  ),
          ),
          _KpiCard(
            title: timingAvgKpiTitle(avgBasis),
            value: avgPnl == null ? '—' : _signedInr(avgPnl),
            subtitle: avgBasis == TimingAvgBasis.perActiveDay &&
                    dist != null &&
                    dist.activeTradingDaysCount > 0
                ? '${dist.activeTradingDaysCount} active days'
                : null,
            valueColor: avgPnl == null
                ? null
                : (avgPnl >= 0
                    ? context.statusSuccess
                    : context.statusError),
            sparkline: avgPnlSparklineData.isEmpty
                ? null
                : AmSparklineChart(
                    data: avgPnlSparklineData,
                    color: avgColorSign >= 0
                        ? context.statusSuccess
                        : context.statusError,
                  ),
          ),
          _KpiCard(
            title: 'Win Rate',
            value: winRate == null ? '—' : '${winRate.toStringAsFixed(1)}%',
            valueColor: winRate == null
                ? null
                : (winRate >= 50
                    ? context.statusSuccess
                    : context.statusError),
            subtitle: winCounts == null
                ? null
                : '${winCounts.wins} wins / ${winCounts.losses} losses',
            sparkline: (winCounts != null && winCounts.eligible > 0)
                ? AmDonutSparkline(
                    value: winCounts.wins.toDouble(),
                    total: winCounts.eligible.toDouble(),
                    color: winRate != null && winRate >= 50
                        ? context.statusSuccess
                        : context.statusError,
                    backgroundColor: (winRate != null && winRate >= 50
                            ? context.statusSuccess
                            : context.statusError)
                        .withValues(alpha: 0.2),
                  )
                : null,
          ),
          _KpiCard(
            title: 'Best Session',
            value: bestLabel ?? '—',
            subtitle: bestSub,
            valueColor: bestLabel == null ? null : context.statusSuccess,
            subtitleColor: bestLabel == null ? null : context.statusSuccess,
            sparkline: sessionAvgPnlData.isEmpty
                ? null
                : AmBarSparkline(
                    data: sessionAvgPnlData,
                    positiveColor: context.statusSuccess,
                    negativeColor: context.statusError,
                  ),
          ),
          _KpiCard(
            title: 'Avg Hold Time',
            value: holdMinutes == null ? '—' : formatHoldDuration(holdMinutes),
            subtitle: holdMinutes == null ? null : 'Eligible sessions',
            sparkline: Icon(
              Icons.schedule,
              size: 40,
              color: context.colors.textSecondary.withValues(alpha: 0.25),
            ),
          ),
        ];

        if (wide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < cards.length; i++) ...[
                if (i > 0) const SizedBox(width: AppSpacing.sm),
                Expanded(child: cards[i]),
              ],
            ],
          );
        }
        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final c in cards)
              SizedBox(
                width: (constraints.maxWidth - AppSpacing.sm) / 2,
                child: c,
              ),
          ],
        );
      },
    );
  }

  static String _signedInr(double value) {
    final formatted = _inr.format(value.abs());
    if (value > 0) return '+$formatted';
    if (value < 0) return '-$formatted';
    return formatted;
  }
}

String formatHoldDuration(double minutes) {
  if (minutes < 60) {
    final m = minutes.round();
    return '${m}m';
  }
  if (minutes < 24 * 60) {
    final h = minutes ~/ 60;
    final m = (minutes % 60).round();
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }
  final days = minutes / (24 * 60);
  return '${days.toStringAsFixed(1)}d';
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.title,
    required this.value,
    this.subtitle,
    this.valueColor,
    this.subtitleColor,
    this.sparkline,
  });

  final String title;
  final String value;
  final String? subtitle;
  final Color? valueColor;
  final Color? subtitleColor;
  final Widget? sparkline;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: colors.cardSurface,
        borderRadius: AppRadii.card,
        border: Border.all(color: colors.border.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: context.text.caption(compact: true).copyWith(
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xxs),
                    Icon(
                      Icons.info_outline,
                      size: 12,
                      color: colors.textSecondary.withValues(alpha: 0.6),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  value,
                  style: context.text.heroTitle(compact: true).copyWith(
                    fontWeight: FontWeight.bold,
                    color: valueColor ?? colors.textPrimary,
                    height: 1.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    subtitle!,
                    style: context.text.caption(compact: true).copyWith(
                      color: subtitleColor ?? colors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (sparkline != null) ...[
            const SizedBox(width: AppSpacing.sm),
            SizedBox(
              width: 64,
              height: 56,
              child: Center(child: sparkline!),
            ),
          ],
        ],
      ),
    );
  }
}
