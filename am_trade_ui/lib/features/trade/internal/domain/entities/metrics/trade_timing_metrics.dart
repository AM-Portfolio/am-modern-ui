class TradeTimingMetrics {
  final double entryTimingScore;
  final double exitTimingScore;
  final Map<String, int> earlyEntries;
  final Map<String, int> optimalEntries;

  TradeTimingMetrics({
    required this.entryTimingScore,
    required this.exitTimingScore,
    required this.earlyEntries,
    required this.optimalEntries,
  });
}
