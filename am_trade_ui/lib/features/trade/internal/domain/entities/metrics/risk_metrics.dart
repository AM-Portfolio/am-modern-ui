class RiskMetrics {
  final double maxDrawdown;
  final double sharpeRatio;
  final double sortinoRatio;
  final double valueAtRisk;
  final double probabilityOfRuin;

  RiskMetrics({
    required this.maxDrawdown,
    required this.sharpeRatio,
    required this.sortinoRatio,
    required this.valueAtRisk,
    required this.probabilityOfRuin,
  });
}
