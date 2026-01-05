import '../../../internal/domain/entities/report/report_performance_metrics.dart';
import '../../../internal/domain/entities/report/timing_analysis.dart';

enum ChartTimeFrame {
  // Linear / Historical
  dailyLinear('Daily'),
  weeklyLinear('Weekly'),
  monthlyLinear('Monthly'),
  
  // Seasonal / Aggregated
  hourSeason('Hourly (Seasonality)'),
  daySeason('Day of Week (Seasonality)'),
  monthSeason('Monthly (Seasonality)'),
  yearSeason('Yearly (Seasonality)');

  final String label;
  const ChartTimeFrame(this.label);
}

enum ChartType {
  line('Line'),
  area('Area'),
  bar('Bar');

  final String label;
  const ChartType(this.label);
}

enum ChartMetric {
  winRate('Win Rate (%)', isPercent: true),
  grossPnL('Gross PnL', isCurrency: true),
  avgWin('Avg Win', isCurrency: true),
  avgLoss('Avg Loss', isCurrency: true),
  holdTime('Avg Hold Time (hrs)'),
  profitFactor('Profit Factor'),
  tradeCount('Trade Count');

  final String label;
  final bool isPercent;
  final bool isCurrency;

  const ChartMetric(this.label, {this.isPercent = false, this.isCurrency = false});

  double getValue(ReportPerformanceMetrics metrics, {int? tradeCount}) {
    switch (this) {
      case ChartMetric.winRate:
        return (metrics.winPercentage?.toDouble() ?? 0) * 100;
      case ChartMetric.grossPnL:
        return metrics.grossPnL?.toDouble() ?? 0;
      case ChartMetric.avgWin:
        return metrics.avgWin?.toDouble() ?? 0;
      case ChartMetric.avgLoss:
        return metrics.avgLoss?.toDouble() ?? 0; 
      case ChartMetric.holdTime:
        return metrics.avgHoldTime?.toDouble() ?? 0;
      case ChartMetric.profitFactor:
        return metrics.profitFactor?.toDouble() ?? 0;
      case ChartMetric.tradeCount:
        return tradeCount?.toDouble() ?? 0;
    }
  }
}

class ChartDataPoint {
  final String xLabel;
  final double yValue;
  final int xIndex;

  ChartDataPoint({required this.xLabel, required this.yValue, required this.xIndex});
}
