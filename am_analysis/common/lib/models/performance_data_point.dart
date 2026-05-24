class PerformanceDataPoint {
  final DateTime date;
  final double value;

  PerformanceDataPoint({
    required this.date,
    required this.value,
  });
}

class PerformanceData {
  final List<PerformanceDataPoint> dataPoints;
  final double? totalReturnPercentage;
  final double? totalReturnValue;

  PerformanceData({
    required this.dataPoints,
    this.totalReturnPercentage,
    this.totalReturnValue,
  });
}
