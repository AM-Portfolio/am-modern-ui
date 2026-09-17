import '../../enums/metric_types.dart';

class MetricsFilterRequest {
  final List<String> portfolioIds;
  final DateTime startDate;
  final DateTime endDate;
  final String? timePeriod;
  final List<MetricTypes>? metricTypes;
  final List<String>? instruments;
  final List<String>? groupBy;
  final bool includeTradeDetails;
  final Map<String, dynamic>? customFilters;
  /// SCALPER | INTRADAY | SWING — null means all holding styles.
  final String? holdingStyle;

  MetricsFilterRequest({
    required this.portfolioIds,
    required this.endDate,
    DateTime? startDate,
    this.timePeriod,
    this.metricTypes,
    this.instruments,
    this.groupBy,
    this.includeTradeDetails = false,
    this.customFilters,
    this.holdingStyle,
  }) : startDate = startDate ?? DateTime(1919, 1, 1);
}
