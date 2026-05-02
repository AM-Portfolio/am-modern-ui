import 'package:freezed_annotation/freezed_annotation.dart';

part 'activity_item.freezed.dart';
part 'activity_item.g.dart';

@freezed
abstract class ActivityItem with _$ActivityItem {
  const factory ActivityItem({
    required String id,
    required String type, // HOLDING, PORTFOLIO_UPDATE, TRADE
    required String title,
    @Default('') String description,
    required DateTime timestamp,
    String? amount,
    @Default(true) bool isPositive,
    String? symbol,
    String? companyName,
    String? sector,
    double? quantity,
    double? currentPrice,
    double? currentValue,
    double? profitLoss,
    double? profitLossPercent,
    String? status, // WIN, LOSS, NEUTRAL
  }) = _ActivityItem;

  factory ActivityItem.fromJson(Map<String, dynamic> json) =>
      _$ActivityItemFromJson(json);
}
