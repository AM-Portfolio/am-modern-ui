import 'package:json_annotation/json_annotation.dart';

import '../../domain/enums/group_by_dimensions.dart';
import '../../domain/enums/metric_types.dart';

part 'metrics_filter_config_dto.g.dart';

/// DTO for metrics filter configuration
/// Uses Map<String, dynamic> for nested filters to match API schema flexibility
@JsonSerializable()
class MetricsFilterConfigDto {
  const MetricsFilterConfigDto({
    this.portfolioIds,
    this.dateRange,
    this.timePeriod,
    this.metricTypes,
    this.groupBy,
    this.instruments,
    this.instrumentFilters,
    this.tradeCharacteristics,
    this.profitLossFilters,
  });

  factory MetricsFilterConfigDto.fromJson(Map<String, dynamic> json) => _$MetricsFilterConfigDtoFromJson(json);

  final List<String>? portfolioIds;
  final Map<String, dynamic>? dateRange;
  final Map<String, dynamic>? timePeriod;
  final List<MetricTypes>? metricTypes;
  final List<GroupByDimensions>? groupBy;
  final List<String>? instruments;
  final Map<String, dynamic>? instrumentFilters;
  final Map<String, dynamic>? tradeCharacteristics;
  final Map<String, dynamic>? profitLossFilters;

  Map<String, dynamic> toJson() => _$MetricsFilterConfigDtoToJson(this);
}
