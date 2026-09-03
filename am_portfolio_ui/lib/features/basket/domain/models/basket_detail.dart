import 'package:freezed_annotation/freezed_annotation.dart';

part 'basket_detail.freezed.dart';
part 'basket_detail.g.dart';

@freezed
abstract class BasketDetail with _$BasketDetail {
  const factory BasketDetail({
    required String id,
    @Default('') String name,
    @Default('') String etfName,
    @Default('') String etfIsin,
    @Default('ACTIVE') String? status,
    @Default(0.0) double totalInvestedValue,
    @Default(0.0) double totalCurrentValue,
    @Default(0.0) double? investmentAmount,
    @Default(0.0) double totalPnL,
    @Default(0.0) double pnlPercent,
    @Default(0.0) double? coveragePercent,
    @Default(0.0) double? replicaScore,
    @Default(0.0) double? coverageAfterCreation,
    @Default(0) int totalItems,
    @Default(0) int heldCount,
    @Default(0) int missingCount,
    @Default(0) int underfundedCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    @Default([]) List<BasketLineDetail> lines,
  }) = _BasketDetail;

  factory BasketDetail.fromJson(Map<String, dynamic> json) =>
      _$BasketDetailFromJson(json);
}

@freezed
abstract class BasketLineDetail with _$BasketLineDetail {
  const factory BasketLineDetail({
    @Default('') String symbol,
    @Default('') String isin,
    String? sector,
    @Default('HELD') String status,
    @Default(0.0) double quantity,
    @Default(0.0) double avgPrice,
    @Default(0.0) double currentPrice,
    @Default(0.0) double pnl,
    double? etfWeight,
    double? rebalancedWeight,
    String? companyName,
    String? coversEtfSymbol,
  }) = _BasketLineDetail;

  factory BasketLineDetail.fromJson(Map<String, dynamic> json) =>
      _$BasketLineDetailFromJson(json);
}
