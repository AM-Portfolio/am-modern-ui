import 'package:freezed_annotation/freezed_annotation.dart';
import '../../enums/metric_types.dart';
import 'metrics/performance_metrics.dart';
import 'metrics/risk_metrics.dart';

part 'trade_report.freezed.dart';

/// Entity representing a comprehensive trade report
@freezed
class TradeReport with _$TradeReport {
  const factory TradeReport({
    /// Total number of trades in the report period
    required int totalTrades,
    
    /// Net profit/loss
    required double netProfitLoss,
    
    /// Win rate (0.0 to 1.0)
    required double winRate,
    
    /// Profit factor
    required double profitFactor,
    
    /// Maximum drawdown amount
    required double maxDrawdown,
    
    /// Average winning trade amount
    required double avgWin,
    
    /// Average losing trade amount
    required double avgLoss,
    
    /// List of key highlights or insights
    @Default([]) List<String> insights,
    
    /// Generation timestamp
    required DateTime generatedAt,
  }) = _TradeReport;
}
