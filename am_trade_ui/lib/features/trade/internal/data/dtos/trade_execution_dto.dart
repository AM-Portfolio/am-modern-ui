import 'package:freezed_annotation/freezed_annotation.dart';
import 'trade_controller_dtos.dart';

part 'trade_execution_dto.freezed.dart';
part 'trade_execution_dto.g.dart';

@freezed
abstract class TradeExecutionBasicInfoDto with _$TradeExecutionBasicInfoDto {
  const factory TradeExecutionBasicInfoDto({
    String? tradeId,
    String? orderId,
    String? tradeDate,
    String? orderExecutionTime,
    String? brokerType,
    String? tradeType,
  }) = _TradeExecutionBasicInfoDto;

  factory TradeExecutionBasicInfoDto.fromJson(Map<String, dynamic> json) =>
      _$TradeExecutionBasicInfoDtoFromJson(json);
}

@freezed
abstract class TradeExecutionInfoDto with _$TradeExecutionInfoDto {
  const factory TradeExecutionInfoDto({
    String? tradeType,
    String? auction,
    int? quantity,
    double? price,
  }) = _TradeExecutionInfoDto;

  factory TradeExecutionInfoDto.fromJson(Map<String, dynamic> json) =>
      _$TradeExecutionInfoDtoFromJson(json);
}

@freezed
abstract class TradeExecutionDto with _$TradeExecutionDto {
  const factory TradeExecutionDto({
    TradeExecutionBasicInfoDto? basicInfo,
    InstrumentInfoDto? instrumentInfo,
    TradeExecutionInfoDto? executionInfo,
  }) = _TradeExecutionDto;

  factory TradeExecutionDto.fromJson(Map<String, dynamic> json) =>
      _$TradeExecutionDtoFromJson(json);
}
