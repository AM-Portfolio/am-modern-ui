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

  // We could add nested filter objects here (InstrumentFilterCriteria, etc.) 
  // but for now keeping it simple or dynamic as per schema usage complexity.
  // Accessing specialized filters might be better done via customFilters map or dedicated objects if critical.
  
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
  }) : startDate = startDate ?? DateTime(1919, 1, 1);
}
