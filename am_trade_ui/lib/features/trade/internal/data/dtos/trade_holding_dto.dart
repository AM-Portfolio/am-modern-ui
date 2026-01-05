import 'package:freezed_annotation/freezed_annotation.dart';

import 'trade_controller_dtos.dart';

part 'trade_holding_dto.freezed.dart';
part 'trade_holding_dto.g.dart';

/// TradeHoldingDto is an alias for TradeDetailsDto - single source of truth
typedef TradeHoldingDto = TradeDetailsDto;

@freezed
abstract class PageableDto with _$PageableDto {
  const factory PageableDto({
    @Default(0) int pageNumber,
    @Default(50) int pageSize,
    @Default(0) int offset,
    @Default(true) bool paged,
    @Default(false) bool unpaged,
  }) = _PageableDto;

  factory PageableDto.fromJson(Map<String, dynamic> json) => _$PageableDtoFromJson(json);
}

@freezed
abstract class TradeHoldingsDto with _$TradeHoldingsDto {
  const factory TradeHoldingsDto({
    @Default([]) List<TradeDetailsDto> content,
    PageableDto? pageable,
    @Default(0) int totalPages,
    @Default(true) bool last,
    @Default(0) int totalElements,
    @Default(true) bool first,
    @Default(50) int size,
    @Default(0) int number,
    @Default(0) int numberOfElements,
    @Default(false) bool empty,
  }) = _TradeHoldingsDto;

  factory TradeHoldingsDto.fromJson(Map<String, dynamic> json) => _$TradeHoldingsDtoFromJson(json);
}
