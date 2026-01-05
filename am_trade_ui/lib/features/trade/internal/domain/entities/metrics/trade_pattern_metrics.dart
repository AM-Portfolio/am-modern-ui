class TradePatternMetrics {
  final double emotionalControlScore;
  final double disciplineScore;
  final double patternConsistencyScore;
  final Map<String, int> patternFrequency;

  TradePatternMetrics({
    required this.emotionalControlScore,
    required this.disciplineScore,
    required this.patternConsistencyScore,
    required this.patternFrequency,
  });
}
