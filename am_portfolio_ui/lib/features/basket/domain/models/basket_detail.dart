import 'package:freezed_annotation/freezed_annotation.dart';

part 'basket_detail.freezed.dart';
part 'basket_detail.g.dart';

@freezed
abstract class BasketDetail with _$BasketDetail {
  const factory BasketDetail({
    required String id,
    required String name,
    required String etfName,
    required String etfIsin,
    required String status,
    required double totalInvestedValue,
    required double totalCurrentValue,
    required double totalPnL,
    required double pnlPercent,
    required int totalItems,
    required int heldCount,
    required int missingCount,
    required int underfundedCount,
    required DateTime createdAt,
    @Default([]) List<BasketLineDetail> lines,
  }) = _BasketDetail;

  factory BasketDetail.fromJson(Map<String, dynamic> json) =>
      _$BasketDetailFromJson(json);
}

@freezed
abstract class BasketLineDetail with _$BasketLineDetail {
  const factory BasketLineDetail({
    required String symbol,
    required String isin,
    String? sector,
    required String status,
    required double quantity,
    required double avgPrice,
    required double currentPrice,
    required double pnl,
  }) = _BasketLineDetail;

  factory BasketLineDetail.fromJson(Map<String, dynamic> json) =>
      _$BasketLineDetailFromJson(json);
}
