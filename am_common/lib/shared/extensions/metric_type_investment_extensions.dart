import '../enums/metric_type.dart';

/// Extensions for MetricType to provide investment-specific lists
extension MetricTypeInvestmentTypes on MetricType {
  /// Metrics suitable for portfolio analysis
  static List<MetricType> get portfolioMetrics => [
    MetricType.changePercent,
    MetricType.marketValue,
    MetricType.volume,
    MetricType.returns,
  ];

  /// Metrics suitable for index analysis
  static List<MetricType> get indexMetrics => [
    MetricType.changePercent,
    MetricType.marketValue,
    MetricType.volume,
    MetricType.returns,
  ];

  /// Metrics suitable for mutual funds analysis
  static List<MetricType> get fundMetrics => [
    MetricType.changePercent,
    MetricType.marketValue,
    MetricType.volume,
  ];

  /// Metrics suitable for ETF analysis
  static List<MetricType> get etfMetrics => [
    MetricType.changePercent,
    MetricType.marketValue,
    MetricType.volume,
    MetricType.returns,
  ];
}
