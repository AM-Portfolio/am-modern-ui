import 'package:freezed_annotation/freezed_annotation.dart';
import 'plan.dart';

part 'subscription.freezed.dart';
part 'subscription.g.dart';

@freezed
abstract class UsageSnapshot with _$UsageSnapshot {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory UsageSnapshot({
    required String metricCode,
    required int used,
    required int limit,
    required int remaining,
  }) = _UsageSnapshot;

  factory UsageSnapshot.fromJson(Map<String, dynamic> json) =>
      _$UsageSnapshotFromJson(json);
}

@freezed
abstract class Subscription with _$Subscription {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory Subscription({
    required String id,
    required String userId,
    String? tenantId,
    required String planCode,
    required String planName,
    required String state,
    required String billingInterval,
    DateTime? currentPeriodStart,
    DateTime? currentPeriodEnd,
    required PlanLimits limits,
    required PlanEntitlements entitlements,
    required List<UsageSnapshot> usage,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Subscription;

  factory Subscription.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionFromJson(json);
}
