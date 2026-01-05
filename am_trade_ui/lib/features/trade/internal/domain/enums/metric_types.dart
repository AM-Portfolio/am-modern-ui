import 'package:json_annotation/json_annotation.dart';

/// Types of metrics for trade analysis
@JsonEnum(fieldRename: FieldRename.screamingSnake)
enum MetricTypes {
  performance,
  risk,
  distribution,
  timing,
  pattern,
  profitLoss,
  winRate,
  riskReward,
  drawdown,
  sharpeRatio,
}

/// Extension for MetricTypes enum
extension MetricTypesExtension on MetricTypes {
  String get displayName {
    switch (this) {
      case MetricTypes.performance:
        return 'Performance';
      case MetricTypes.risk:
        return 'Risk';
      case MetricTypes.distribution:
        return 'Distribution';
      case MetricTypes.timing:
        return 'Timing';
      case MetricTypes.pattern:
        return 'Pattern';
      case MetricTypes.profitLoss:
        return 'Profit/Loss';
      case MetricTypes.winRate:
        return 'Win Rate';
      case MetricTypes.riskReward:
        return 'Risk/Reward';
      case MetricTypes.drawdown:
        return 'Drawdown';
      case MetricTypes.sharpeRatio:
        return 'Sharpe Ratio';
    }
  }
}
