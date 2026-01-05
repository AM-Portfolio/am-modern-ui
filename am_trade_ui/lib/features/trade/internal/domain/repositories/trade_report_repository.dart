import '../entities/metrics/metrics_filter_request.dart';
import '../entities/report/trade_performance_summary.dart';
import '../entities/report/daily_performance.dart';
import '../entities/report/timing_analysis.dart';

/// Repository for accessing trade report data
abstract class TradeReportRepository {
  /// Get comprehensive trade performance summary
  Future<TradePerformanceSummary> getPerformanceSummary(MetricsFilterRequest filter);
  
  /// Get daily performance breakdown
  Future<List<DailyPerformance>> getDailyPerformance(MetricsFilterRequest filter);

  /// Get timing analysis (hourly, weekly, monthly, etc.)
  Future<TimingAnalysis> getTimingAnalysis(MetricsFilterRequest filter);
}
