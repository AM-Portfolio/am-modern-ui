import 'package:freezed_annotation/freezed_annotation.dart';

part 'portfolio_overview_data.freezed.dart';
part 'portfolio_overview_data.g.dart';

/// Complete portfolio overview data model
@freezed
abstract class PortfolioOverviewData with _$PortfolioOverviewData {
  const factory PortfolioOverviewData({
    required OverviewSummaryData summary,
    required List<OverviewMoversData> topGainers,
    required List<OverviewMoversData> topLosers,
    required List<AllocationItem> sectorAllocation,
    required List<AllocationItem> marketCapAllocation,
    DateTime? lastUpdated,
  }) = _PortfolioOverviewData;

  factory PortfolioOverviewData.fromJson(Map<String, dynamic> json) =>
      _$PortfolioOverviewDataFromJson(json);
}

/// Summary data for overview
@freezed
abstract class OverviewSummaryData with _$OverviewSummaryData {
  const factory OverviewSummaryData({
    required double totalValue,
    required double todayChange,
    required double todayChangePercent,
    required double totalGainLoss,
    required double totalGainLossPercent,
    required int totalHoldings,
    @Default(0) double investedAmount,
    @Default(0) double availableCash,
  }) = _OverviewSummaryData;

  factory OverviewSummaryData.fromJson(Map<String, dynamic> json) =>
      _$OverviewSummaryDataFromJson(json);
}

/// Movers data (top gainers/losers)
@freezed
abstract class OverviewMoversData with _$OverviewMoversData {
  const factory OverviewMoversData({
    required String symbol,
    required String name,
    required double currentPrice,
    required double changeAmount,
    required double changePercent,
    String? sector,
  }) = _OverviewMoversData;

  factory OverviewMoversData.fromJson(Map<String, dynamic> json) =>
      _$OverviewMoversDataFromJson(json);
}

/// Allocation item for sector/market cap
@freezed
abstract class AllocationItem with _$AllocationItem {
  const factory AllocationItem({
    required String label,
    required double value,
    required double percentage,
    @Default(0) int count,
    String? color,
  }) = _AllocationItem;

  factory AllocationItem.fromJson(Map<String, dynamic> json) =>
      _$AllocationItemFromJson(json);
}
