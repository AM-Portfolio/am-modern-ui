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
  final Map<String, int> eligibleTradesByDay;

  final Map<String, int> tradesByHour;
  final Map<String, double> profitByHour;
  final Map<String, double> winRateByHour;
  final Map<String, double> avgPnlByHour;
  final Map<String, int> eligibleTradesByHour;

  final Map<String, int> tradesByMonth;
  final Map<String, double> profitByMonth;
  final Map<String, double> winRateByMonth;
  final Map<String, double> avgPnlByMonth;
  final Map<String, int> eligibleTradesByMonth;

  final Map<String, int> tradesBySession;
  final Map<String, double> profitBySession;
  final Map<String, double> winRateBySession;
  final Map<String, double> avgPnlBySession;
  final Map<String, int> eligibleTradesBySession;

  final Map<String, int> tradeCountByAssetClass;
  final Map<String, int> tradeCountByStrategy;

  final int skippedMissingEntryCount;
  final int openOrMissingPnlCount;
  final int badTimestampCount;
  final String timezoneNote;
  final TradingStyleHint? tradingStyleHint;

  TradeDistributionMetrics({
    required this.tradesByDay,
    required this.profitByDay,
    this.winRateByDay = const {},
    this.avgPnlByDay = const {},
    this.eligibleTradesByDay = const {},
    required this.tradesByHour,
    required this.profitByHour,
    this.winRateByHour = const {},
    this.avgPnlByHour = const {},
    this.eligibleTradesByHour = const {},
    this.tradesByMonth = const {},
    this.profitByMonth = const {},
    this.winRateByMonth = const {},
    this.avgPnlByMonth = const {},
    this.eligibleTradesByMonth = const {},
    this.tradesBySession = const {},
    this.profitBySession = const {},
    this.winRateBySession = const {},
    this.avgPnlBySession = const {},
    this.eligibleTradesBySession = const {},
    required this.tradeCountByAssetClass,
    required this.tradeCountByStrategy,
    this.skippedMissingEntryCount = 0,
    this.openOrMissingPnlCount = 0,
    this.badTimestampCount = 0,
    this.timezoneNote = 'entry_local_as_stored',
    this.tradingStyleHint,
  });
}
