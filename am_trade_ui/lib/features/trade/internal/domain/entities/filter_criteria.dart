import 'package:freezed_annotation/freezed_annotation.dart';

import '../enums/derivative_types.dart';
import '../enums/index_types.dart';
import '../enums/market_segments.dart';
import '../enums/trade_directions.dart';
import '../enums/trade_statuses.dart';

part 'filter_criteria.freezed.dart';

/// Domain entity for date range filter
@freezed
abstract class DateRangeFilter with _$DateRangeFilter {
  const factory DateRangeFilter({required DateTime startDate, required DateTime endDate}) = _DateRangeFilter;
}

/// Domain entity for instrument filter criteria
@freezed
abstract class InstrumentFilterCriteria with _$InstrumentFilterCriteria {
  const factory InstrumentFilterCriteria({
    @Default([]) List<MarketSegments> marketSegments,
    @Default([]) List<String> baseSymbols,
    @Default([]) List<IndexTypes> indexTypes,
    @Default([]) List<DerivativeTypes> derivativeTypes,
  }) = _InstrumentFilterCriteria;
}

/// Domain entity for trade characteristics filter
@freezed
abstract class TradeCharacteristicsFilter with _$TradeCharacteristicsFilter {
  const factory TradeCharacteristicsFilter({
    @Default([]) List<String> strategies,
    @Default([]) List<String> tags,
    @Default([]) List<TradeDirections> directions,
    @Default([]) List<TradeStatuses> statuses,
    int? minHoldingTimeHours,
    int? maxHoldingTimeHours,
  }) = _TradeCharacteristicsFilter;
}

/// Domain entity for profit/loss filter
@freezed
abstract class ProfitLossFilter with _$ProfitLossFilter {
  const factory ProfitLossFilter({
    double? minProfitLoss,
    double? maxProfitLoss,
    double? minPositionSize,
    double? maxPositionSize,
  }) = _ProfitLossFilter;
}
