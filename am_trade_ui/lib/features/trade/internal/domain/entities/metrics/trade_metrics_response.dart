import 'performance_metrics.dart';
import 'risk_metrics.dart';
import 'trade_distribution_metrics.dart';
import 'trade_timing_metrics.dart';
import 'trade_pattern_metrics.dart';
import 'strategy_performance_metrics.dart';
import 'trade_details.dart';

class TradeMetricsResponse {
  final List<String> portfolioIds;
  final DateTime startDate;
  final DateTime endDate;
  final int totalTradesCount;
  final List<TradeDetails>? tradeDetails;
  final PerformanceMetrics performanceMetrics;
  final RiskMetrics riskMetrics;
  final TradeDistributionMetrics distributionMetrics;
  final TradeTimingMetrics timingMetrics;
  final TradePatternMetrics patternMetrics;
  final Map<String, StrategyPerformanceMetrics> strategyMetrics;
  final Map<String, Map<String, dynamic>> groupedMetrics;
  final Map<String, dynamic> metadata;

  TradeMetricsResponse({
    required this.portfolioIds,
    required this.startDate,
    required this.endDate,
    required this.totalTradesCount,
    this.tradeDetails,
    required this.performanceMetrics,
    required this.riskMetrics,
    required this.distributionMetrics,
    required this.timingMetrics,
    required this.patternMetrics,
    required this.strategyMetrics,
    required this.groupedMetrics,
    required this.metadata,
  });
}
