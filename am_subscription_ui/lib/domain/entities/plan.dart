import 'package:freezed_annotation/freezed_annotation.dart';

part 'plan.freezed.dart';
part 'plan.g.dart';

@freezed
abstract class PlanEntitlements with _$PlanEntitlements {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory PlanEntitlements({
    @Default(false) bool liveMarketData,
    @Default(false) bool realtimeIndices,
    @Default(false) bool tradingviewCharts,
    @Default(false) bool basketTrading,
    @Default(false) bool customAiBots,
    @Default(false) bool predictiveAnalytics,
  }) = _PlanEntitlements;

  factory PlanEntitlements.fromJson(Map<String, dynamic> json) =>
      _$PlanEntitlementsFromJson(json);
}

@freezed
abstract class PlanLimits with _$PlanLimits {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory PlanLimits({
    @Default(0) int documentParses,
    @Default(0) int portfolios,
    @Default(0) int aiPortfolioSummaries,
    @Default(0) int apiCalls,
  }) = _PlanLimits;

  factory PlanLimits.fromJson(Map<String, dynamic> json) =>
      _$PlanLimitsFromJson(json);
}

@freezed
abstract class Plan with _$Plan {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory Plan({
    required String code,
    required String name,
    required String interval,
    required String description,
    required int amountInr,
    required List<String> features,
    required PlanLimits limits,
    required PlanEntitlements entitlements,
  }) = _Plan;

  factory Plan.fromJson(Map<String, dynamic> json) => _$PlanFromJson(json);
}
