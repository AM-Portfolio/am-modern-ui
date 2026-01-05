import '../../domain/entities/report/daily_performance.dart';
import '../../domain/entities/report/report_performance_metrics.dart';
import '../../domain/entities/report/timing_analysis.dart';
import '../../domain/entities/report/trade_performance_summary.dart';
import '../dtos/report/daily_performance_dto.dart';
import '../dtos/report/performance_metrics_dto.dart';
import '../dtos/report/timing_analysis_dto.dart';
import '../dtos/report/trade_performance_summary_dto.dart';

class TradeReportMapper {
  static ReportPerformanceMetrics toPerformanceMetrics(PerformanceMetricsDto dto) {
    return ReportPerformanceMetrics(
      avgHoldTime: dto.avgHoldTime?.toDouble(),
      longestTradeDuration: dto.longestTradeDuration?.toDouble(),
      maxTradingWeeksDuration: dto.maxTradingWeeksDuration?.toDouble(),
      avgTradingWeeksDuration: dto.avgTradingWeeksDuration?.toDouble(),
      avgGrossTradePnL: dto.avgGrossTradePnL?.toDouble(),
      avgLoss: dto.avgLoss?.toDouble(),
      avgMaxTradeLoss: dto.avgMaxTradeLoss?.toDouble(),
      avgMaxTradeProfit: dto.avgMaxTradeProfit?.toDouble(),
      avgTradeWinLossRatio: dto.avgTradeWinLossRatio?.toDouble(),
      avgWeeklyGrossPnL: dto.avgWeeklyGrossPnL?.toDouble(),
      avgWeeklyWinLossRatio: dto.avgWeeklyWinLossRatio?.toDouble(),
      avgWin: dto.avgWin?.toDouble(),
      grossPnL: dto.grossPnL?.toDouble(),
      largestLosingTrade: dto.largestLosingTrade?.toDouble(),
      largestProfitableTrade: dto.largestProfitableTrade?.toDouble(),
      profitFactor: dto.profitFactor?.toDouble(),
      avgWeeklyGrossDrawdown: dto.avgWeeklyGrossDrawdown?.toDouble(),
      avgPlannedRMultiple: dto.avgPlannedRMultiple?.toDouble(),
      avgRealizedRMultiple: dto.avgRealizedRMultiple?.toDouble(),
      breakevenDays: dto.breakevenDays,
      breakevenTrades: dto.breakevenTrades,
      losingDays: dto.losingDays,
      maxWeeklyGrossDrawdown: dto.maxWeeklyGrossDrawdown?.toDouble(),
      avgWeeklyWinPercentage: dto.avgWeeklyWinPercentage?.toDouble(),
      longsWinPercentage: dto.longsWinPercentage?.toDouble(),
      maxConsecutiveLosingWeeks: dto.maxConsecutiveLosingWeeks,
      maxConsecutiveLosses: dto.maxConsecutiveLosses,
      maxConsecutiveWinningWeeks: dto.maxConsecutiveWinningWeeks,
      maxConsecutiveWins: dto.maxConsecutiveWins,
      shortsWinPercentage: dto.shortsWinPercentage?.toDouble(),
      winPercentage: dto.winPercentage?.toDouble(),
      winningDays: dto.winningDays,
    );
  }

  static TradePerformanceSummary toSummary(TradePerformanceSummaryDto dto) {
    return TradePerformanceSummary(
      totalTrades: dto.totalTrades,
      winningTrades: dto.winningTrades,
      losingTrades: dto.losingTrades,
      breakEvenTrades: dto.breakEvenTrades,
      winPercentage: dto.winPercentage,
      totalProfitLoss: dto.totalProfitLoss,
      averageProfitPerTrade: dto.averageProfitPerTrade,
      averageWinAmount: dto.averageWinAmount,
      averageLossAmount: dto.averageLossAmount,
      averageHoldingTimeWin: dto.averageHoldingTimeWin,
      averageHoldingTimeLoss: dto.averageHoldingTimeLoss,
      maxDrawdown: dto.maxDrawdown,
      profitFactor: dto.profitFactor,
      largestWin: dto.largestWin,
      largestLoss: dto.largestLoss,
      metrics: toPerformanceMetrics(dto.metrics),
    );
  }

  static DailyPerformance toDaily(DailyPerformanceDto dto) {
    return DailyPerformance(
      date: DateTime.tryParse(dto.date) ?? DateTime.now(),
      totalProfitLoss: dto.totalProfitLoss,
      tradeCount: dto.tradeCount,
      winCount: dto.winCount,
      lossCount: dto.lossCount,
      winRate: dto.winRate,
      bestTradeSymbol: dto.bestTradeSymbol,
      bestTradePnL: dto.bestTradePnL,
      metrics: toPerformanceMetrics(dto.metrics),
    );
  }

  static TimingAnalysis toTimingAnalysis(TimingAnalysisDto dto) {
    return TimingAnalysis(
      hourlyPerformance: dto.hourlyPerformance.map((e) => HourlyPerformance(
        hour: e.hour,
        tradeCount: e.tradeCount,
        winCount: e.winCount,
        lossCount: e.lossCount,
        winRate: e.winRate,
        totalProfitLoss: e.totalProfitLoss,
        averageWinAmount: e.averageWinAmount,
        averageLossAmount: e.averageLossAmount,
        averageHoldingTime: e.averageHoldingTime,
        metrics: toPerformanceMetrics(e.metrics),
      )).toList(),
      dayOfWeekPerformance: dto.dayOfWeekPerformance.map((e) => DayOfWeekPerformance(
        dayOfWeek: e.dayOfWeek,
        dayOrder: e.dayOrder,
        tradeCount: e.tradeCount,
        winCount: e.winCount,
        lossCount: e.lossCount,
        winRate: e.winRate,
        totalProfitLoss: e.totalProfitLoss,
        averageWinAmount: e.averageWinAmount,
        averageLossAmount: e.averageLossAmount,
        averageHoldingTime: e.averageHoldingTime,
        metrics: toPerformanceMetrics(e.metrics),
      )).toList(),
      monthlyPerformance: dto.monthlyPerformance.map((e) => MonthlyPerformance(
        month: e.month,
        monthOrder: e.monthOrder,
        tradeCount: e.tradeCount,
        winCount: e.winCount,
        lossCount: e.lossCount,
        winRate: e.winRate,
        totalProfitLoss: e.totalProfitLoss,
        averageWinAmount: e.averageWinAmount,
        averageLossAmount: e.averageLossAmount,
        averageHoldingTime: e.averageHoldingTime,
        metrics: toPerformanceMetrics(e.metrics),
      )).toList(),
      yearlyPerformance: dto.yearlyPerformance.map((e) => YearlyPerformance(
        year: e.year,
        tradeCount: e.tradeCount,
        winCount: e.winCount,
        lossCount: e.lossCount,
        winRate: e.winRate,
        totalProfitLoss: e.totalProfitLoss,
        averageWinAmount: e.averageWinAmount,
        averageLossAmount: e.averageLossAmount,
        averageHoldingTime: e.averageHoldingTime,
        metrics: toPerformanceMetrics(e.metrics),
      )).toList(),
      weeklyPerformance: dto.weeklyPerformance.map((e) => WeeklyPerformance(
        weekId: e.weekId,
        tradeCount: e.tradeCount,
        winCount: e.winCount,
        lossCount: e.lossCount,
        winRate: e.winRate,
        totalProfitLoss: e.totalProfitLoss,
        metrics: toPerformanceMetrics(e.metrics),
      )).toList(),
      bestTradingHour: dto.bestTradingHour,
      worstTradingHour: dto.worstTradingHour,
      bestTradingDay: dto.bestTradingDay,
      worstTradingDay: dto.worstTradingDay,
      bestTradingMonth: dto.bestTradingMonth,
      worstTradingMonth: dto.worstTradingMonth,
    );
  }
}
