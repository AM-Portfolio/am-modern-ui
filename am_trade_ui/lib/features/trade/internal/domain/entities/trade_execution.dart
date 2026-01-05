import 'package:freezed_annotation/freezed_annotation.dart';
import 'instrument_info.dart';

part 'trade_execution.freezed.dart';

@freezed
abstract class TradeExecutionBasicInfo with _$TradeExecutionBasicInfo {
  const factory TradeExecutionBasicInfo({
    String? tradeId,
    String? orderId,
    DateTime? tradeDate,
    DateTime? orderExecutionTime,
    String? brokerType,
    String? tradeType,
  }) = _TradeExecutionBasicInfo;
}

@freezed
abstract class TradeExecutionInfo with _$TradeExecutionInfo {
  const factory TradeExecutionInfo({
    String? tradeType,
    String? auction,
    int? quantity,
    double? price,
  }) = _TradeExecutionInfo;
}

@freezed
abstract class TradeExecution with _$TradeExecution {
  const factory TradeExecution({
    TradeExecutionBasicInfo? basicInfo,
    InstrumentInfo? instrumentInfo,
    TradeExecutionInfo? executionInfo,
  }) = _TradeExecution;
}
