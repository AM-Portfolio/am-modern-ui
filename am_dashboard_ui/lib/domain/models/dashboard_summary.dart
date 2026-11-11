import 'package:freezed_annotation/freezed_annotation.dart';

part 'dashboard_summary.freezed.dart';
part 'dashboard_summary.g.dart';

@freezed
abstract class DashboardSummary with _$DashboardSummary {
  const factory DashboardSummary({
    required double totalValue,
    required double totalInvested,
    required double totalGainLoss,
    required double totalGainLossPercentage,
    required double dayChange,
    required double dayChangePercentage,
    required int totalPortfolios,
    @Default(0) int totalHoldings,
  }) = _DashboardSummary;

  factory DashboardSummary.fromJson(Map<String, dynamic> json) =>
      _$DashboardSummaryFromJson(json);
}
