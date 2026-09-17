import '../../../internal/domain/entities/metrics/trade_distribution_metrics.dart';
import '../models/timing_bucket.dart';

/// Pure O(buckets) Timing KPI math from distribution session maps.
/// Source of truth: Doc/analysis_kpi_zero_fix_plan.md / Doc/analysis_avg_basis_filter_plan.md

double? timingTotalPnl(TradeDistributionMetrics? dist) {
  if (dist == null || dist.profitBySession.isEmpty) return null;
  var sum = 0.0;
  for (final v in dist.profitBySession.values) {
    sum += v;
  }
  return sum;
}

int timingEligibleSum(TradeDistributionMetrics? dist) {
  if (dist == null) return 0;
  var sum = 0;
  for (final v in dist.eligibleTradesBySession.values) {
    sum += v;
  }
  return sum;
}

double? timingAvgPnl(TradeDistributionMetrics? dist) {
  final total = timingTotalPnl(dist);
  final eligible = timingEligibleSum(dist);
  if (total == null || eligible <= 0) return null;
  return total / eligible;
}

double? timingAvgPnlForBasis(
  TradeDistributionMetrics? dist,
  TimingAvgBasis basis,
) {
  switch (basis) {
    case TimingAvgBasis.perTrade:
      return timingAvgPnl(dist);
    case TimingAvgBasis.perActiveDay:
      if (dist == null) return null;
      if (dist.avgPnlPerActiveDay != null) return dist.avgPnlPerActiveDay;
      final total = timingTotalPnl(dist);
      final days = dist.activeTradingDaysCount;
      if (total == null || days <= 0) return null;
      return total / days;
  }
}

/// Weighted Win% = Σ (winRate/100 * eligible) / Σ eligible.
double? timingWinRate(TradeDistributionMetrics? dist) {
  final counts = timingWinCounts(dist);
  if (counts == null || counts.eligible <= 0) return null;
  return (counts.winsExact / counts.eligible) * 100.0;
}

/// Win / loss counts derived from distribution session maps only.
({int wins, int losses, int eligible, double winsExact})? timingWinCounts(
  TradeDistributionMetrics? dist,
) {
  if (dist == null) return null;
  var winsExact = 0.0;
  var eligible = 0;
  for (final entry in dist.eligibleTradesBySession.entries) {
    final e = entry.value;
    if (e <= 0) continue;
    final wr = dist.winRateBySession[entry.key];
    if (wr == null) continue;
    winsExact += (wr / 100.0) * e;
    eligible += e;
  }
  if (eligible <= 0) return null;
  final wins = winsExact.round().clamp(0, eligible);
  return (
    wins: wins,
    losses: eligible - wins,
    eligible: eligible,
    winsExact: winsExact,
  );
}

/// Eligible-weighted mean hold minutes across sessions (distribution only).
double? timingAvgHoldMinutes(TradeDistributionMetrics? dist) {
  if (dist == null || dist.avgHoldMinutesBySession.isEmpty) return null;
  var weighted = 0.0;
  var eligible = 0;
  for (final entry in dist.avgHoldMinutesBySession.entries) {
    final e = dist.eligibleTradesBySession[entry.key] ?? 0;
    if (e <= 0) continue;
    weighted += entry.value * e;
    eligible += e;
  }
  if (eligible <= 0) return null;
  return weighted / eligible;
}

/// Sign hint for sparkline when Total P&L is null — sum of series values.
double sparklineSeriesSign(List<double> series) {
  var sum = 0.0;
  for (final v in series) {
    sum += v;
  }
  return sum;
}
