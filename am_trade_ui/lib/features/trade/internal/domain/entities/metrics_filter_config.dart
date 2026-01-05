import 'package:freezed_annotation/freezed_annotation.dart';

import '../enums/group_by_dimensions.dart';
import '../enums/metric_types.dart';
import 'filter_criteria.dart';

part 'metrics_filter_config.freezed.dart';

/// Domain entity for metrics filter configuration
@freezed
abstract class MetricsFilterConfig with _$MetricsFilterConfig {
  const factory MetricsFilterConfig({
    @Default([]) List<String> portfolioIds,
    DateRangeFilter? dateRange,
    String? timePeriod,
    @Default([]) List<MetricTypes> metricTypes,
    @Default([]) List<GroupByDimensions> groupBy,
    @Default([]) List<String> instruments,
    InstrumentFilterCriteria? instrumentFilters,
    TradeCharacteristicsFilter? tradeCharacteristics,
    ProfitLossFilter? profitLossFilters,
  }) = _MetricsFilterConfig;

  /// Create empty config
  factory MetricsFilterConfig.empty() => const MetricsFilterConfig();
}
