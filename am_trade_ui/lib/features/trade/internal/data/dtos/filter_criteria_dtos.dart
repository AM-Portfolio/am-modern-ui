import 'package:json_annotation/json_annotation.dart';

import '../../domain/enums/derivative_types.dart';
import '../../domain/enums/index_types.dart';
import '../../domain/enums/market_segments.dart';
import '../../domain/enums/trade_directions.dart';
import '../../domain/enums/trade_statuses.dart';

part 'filter_criteria_dtos.g.dart';

/// DTO for date range filter criteria
@JsonSerializable()
class DateRangeFilterDto {
  const DateRangeFilterDto({required this.startDate, required this.endDate});

  factory DateRangeFilterDto.fromJson(Map<String, dynamic> json) => _$DateRangeFilterDtoFromJson(json);

  final String startDate;
  final String endDate;

  Map<String, dynamic> toJson() => _$DateRangeFilterDtoToJson(this);
}

/// DTO for instrument filter criteria
@JsonSerializable()
class InstrumentFilterCriteriaDto {
  const InstrumentFilterCriteriaDto({this.marketSegments, this.baseSymbols, this.indexTypes, this.derivativeTypes});

  factory InstrumentFilterCriteriaDto.fromJson(Map<String, dynamic> json) =>
      _$InstrumentFilterCriteriaDtoFromJson(json);

  final List<MarketSegments>? marketSegments;
  final List<String>? baseSymbols;
  final List<IndexTypes>? indexTypes;
  final List<DerivativeTypes>? derivativeTypes;

  Map<String, dynamic> toJson() => _$InstrumentFilterCriteriaDtoToJson(this);
}

/// DTO for trade characteristics filter
@JsonSerializable()
class TradeCharacteristicsFilterDto {
  const TradeCharacteristicsFilterDto({
    this.strategies,
    this.tags,
    this.directions,
    this.statuses,
    this.minHoldingTimeHours,
    this.maxHoldingTimeHours,
  });

  factory TradeCharacteristicsFilterDto.fromJson(Map<String, dynamic> json) =>
      _$TradeCharacteristicsFilterDtoFromJson(json);

  final List<String>? strategies;
  final List<String>? tags;
  final List<TradeDirections>? directions;
  final List<TradeStatuses>? statuses;
  final int? minHoldingTimeHours;
  final int? maxHoldingTimeHours;

  Map<String, dynamic> toJson() => _$TradeCharacteristicsFilterDtoToJson(this);
}

/// DTO for profit/loss filter criteria
@JsonSerializable()
class ProfitLossFilterDto {
  const ProfitLossFilterDto({this.minProfitLoss, this.maxProfitLoss, this.minPositionSize, this.maxPositionSize});

  factory ProfitLossFilterDto.fromJson(Map<String, dynamic> json) => _$ProfitLossFilterDtoFromJson(json);

  final double? minProfitLoss;
  final double? maxProfitLoss;
  final double? minPositionSize;
  final double? maxPositionSize;

  Map<String, dynamic> toJson() => _$ProfitLossFilterDtoToJson(this);
}
