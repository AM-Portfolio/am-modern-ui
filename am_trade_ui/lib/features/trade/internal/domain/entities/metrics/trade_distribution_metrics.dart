class TradingStyleHint {
  final String style;
  final double confidencePercent;
  final String basis;
  final int sampleSize;

  const TradingStyleHint({
    required this.style,
    required this.confidencePercent,
    required this.basis,
    required this.sampleSize,
  });
}

class TradeDistributionMetrics {
  final Map<String, int> tradesByDay;
  final Map<String, double> profitByDay;
  final Map<String, double> winRateByDay;
  final Map<String, double> avgPnlByDay;
  final Map<String, double> avgPnlPerActiveDayByDay;
  final Map<String, int> eligibleTradesByDay;
  final Map<String, int> activeTradingDaysByDay;
  final Map<String, double> avgHoldMinutesByDay;
  final Map<String, double> riskRewardByDay;

  final Map<String, int> tradesByHour;
  final Map<String, double> profitByHour;
  final Map<String, double> winRateByHour;
  final Map<String, double> avgPnlByHour;
  final Map<String, double> avgPnlPerActiveDayByHour;
  final Map<String, int> eligibleTradesByHour;
  final Map<String, int> activeTradingDaysByHour;
  final Map<String, double> avgHoldMinutesByHour;
  final Map<String, double> riskRewardByHour;

  final Map<String, int> tradesByMonth;
  final Map<String, double> profitByMonth;
  final Map<String, double> winRateByMonth;
  final Map<String, double> avgPnlByMonth;
  final Map<String, double> avgPnlPerActiveDayByMonth;
  final Map<String, int> eligibleTradesByMonth;
  final Map<String, int> activeTradingDaysByMonth;
  final Map<String, double> avgHoldMinutesByMonth;
  final Map<String, double> riskRewardByMonth;

  final Map<String, int> tradesBySession;
  final Map<String, double> profitBySession;
  final Map<String, double> winRateBySession;
  final Map<String, double> avgPnlBySession;
  final Map<String, double> avgPnlPerActiveDayBySession;
  final Map<String, int> eligibleTradesBySession;
  final Map<String, int> activeTradingDaysBySession;
  final Map<String, double> avgHoldMinutesBySession;
  final Map<String, double> riskRewardBySession;

  final Map<String, int> tradeCountByAssetClass;
  final Map<String, int> tradeCountByStrategy;

  final int skippedMissingEntryCount;
  final int openOrMissingPnlCount;
  final int badTimestampCount;
  final String timezoneNote;
  final TradingStyleHint? tradingStyleHint;
  final String? bestSessionKey;
  final double? bestSessionAvgPnl;

  /// Distinct entry dates with eligible PnL across Timing universe.
  final int activeTradingDaysCount;
  /// Overall eligible PnL ÷ [activeTradingDaysCount].
  final double? avgPnlPerActiveDay;

  TradeDistributionMetrics({
    required this.tradesByDay,
    required this.profitByDay,
    this.winRateByDay = const {},
    this.avgPnlByDay = const {},
    this.avgPnlPerActiveDayByDay = const {},
    this.eligibleTradesByDay = const {},
    this.activeTradingDaysByDay = const {},
    this.avgHoldMinutesByDay = const {},
    this.riskRewardByDay = const {},
    required this.tradesByHour,
    required this.profitByHour,
    this.winRateByHour = const {},
    this.avgPnlByHour = const {},
    this.avgPnlPerActiveDayByHour = const {},
    this.eligibleTradesByHour = const {},
    this.activeTradingDaysByHour = const {},
    this.avgHoldMinutesByHour = const {},
    this.riskRewardByHour = const {},
    this.tradesByMonth = const {},
    this.profitByMonth = const {},
    this.winRateByMonth = const {},
    this.avgPnlByMonth = const {},
    this.avgPnlPerActiveDayByMonth = const {},
    this.eligibleTradesByMonth = const {},
    this.activeTradingDaysByMonth = const {},
    this.avgHoldMinutesByMonth = const {},
    this.riskRewardByMonth = const {},
    this.tradesBySession = const {},
    this.profitBySession = const {},
    this.winRateBySession = const {},
    this.avgPnlBySession = const {},
    this.avgPnlPerActiveDayBySession = const {},
    this.eligibleTradesBySession = const {},
    this.activeTradingDaysBySession = const {},
    this.avgHoldMinutesBySession = const {},
    this.riskRewardBySession = const {},
    required this.tradeCountByAssetClass,
    required this.tradeCountByStrategy,
    this.skippedMissingEntryCount = 0,
    this.openOrMissingPnlCount = 0,
    this.badTimestampCount = 0,
    this.timezoneNote = 'entry_local_as_stored',
    this.tradingStyleHint,
    this.bestSessionKey,
    this.bestSessionAvgPnl,
    this.activeTradingDaysCount = 0,
    this.avgPnlPerActiveDay,
  });
}
