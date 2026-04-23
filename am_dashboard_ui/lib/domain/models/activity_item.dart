import 'package:freezed_annotation/freezed_annotation.dart';

part 'activity_item.freezed.dart';
part 'activity_item.g.dart';

@freezed
abstract class ActivityItem with _$ActivityItem {
  const factory ActivityItem({
    required String id,
    required String type, // TRADE, DEPOSIT, WITHDRAWAL, ALERT
    required String title,
    required String description,
    required DateTime timestamp,
    required String amount,
    @Default(true) bool isPositive,
  }) = _ActivityItem;

  factory ActivityItem.fromJson(Map<String, dynamic> json) =>
      _$ActivityItemFromJson(json);
}
