import 'package:freezed_annotation/freezed_annotation.dart';

part 'trade_summary.freezed.dart';
part 'trade_summary.g.dart';

/// Domain entity for trade performance metrics
@freezed
abstract class TradeMetrics with _$TradeMetrics {
  const factory TradeMetrics({
    // Trade Statistics
    @Default(0) int totalTrades,
    @Default(0) int winningTrades,
    @Default(0) int losingTrades,
    @Default(0) int breakEvenTrades,
    @Default(0) int openPositions,

    // Performance Ratios
    double? winRate,
    double? lossRate,
    double? profitFactor,
    double? expectancy,

    // Financial Metrics (Currently available)
    double? totalValue,
    double? totalProfit,
    double? totalLoss,
    double? netProfitLoss,
    double? netProfitLossPercentage,

    // Risk Metrics (To be calculated later)
    double? maxDrawdown,
    double? maxDrawdownPercentage,
    double? sharpeRatio,
    double? sortinoRatio,

    // Returns (To be calculated later)
    Map<String, double>? monthlyReturns,
    Map<String, double>? weeklyReturns,
  }) = _TradeMetrics;

  factory TradeMetrics.fromJson(Map<String, dynamic> json) => _$TradeMetricsFromJson(json);

  /// Create empty metrics
  factory TradeMetrics.empty() => const TradeMetrics();
}

/// Domain entity for asset allocation in trade portfolio
@freezed
abstract class TradeAssetAllocation with _$TradeAssetAllocation {
  const factory TradeAssetAllocation({
    required String assetType,
    required double value,
    required double percentage,
    @Default(0) int count,
  }) = _TradeAssetAllocation;

  factory TradeAssetAllocation.fromJson(Map<String, dynamic> json) => _$TradeAssetAllocationFromJson(json);
}

/// Domain entity for top movers in trade (To be calculated later)
@freezed
abstract class TradeTopMover with _$TradeTopMover {
  const factory TradeTopMover({
    required String symbol,
    required String name,
    required double change,
    required double changePercentage,
    required double currentPrice,
  }) = _TradeTopMover;

  factory TradeTopMover.fromJson(Map<String, dynamic> json) => _$TradeTopMoverFromJson(json);
}

/// Domain entity for trade portfolio summary
/// Represents the complete portfolio information with trade metrics
@freezed
abstract class TradeSummary with _$TradeSummary {
  const factory TradeSummary({
    // Portfolio Identity
    required String portfolioId,
    required String name,
    required String ownerId,
    String? description,

    // Portfolio Configuration
    @Default(true) bool active,
    String? currency,
    double? initialCapital,
    double? currentCapital,

    // Timestamps
    DateTime? createdDate,
    DateTime? lastUpdatedDate,

    // Trade Metrics (nested object from API)
    @Default(TradeMetrics()) TradeMetrics metrics,

    // Trade References
    @Default([]) List<String> tradeIds,
    List<String>? winningTradeIds,
    List<String>? losingTradeIds,

    // Allocations (To be calculated later)
    List<TradeAssetAllocation>? assetAllocations,

    // Top Movers (To be calculated later)
    @Default([]) List<TradeTopMover> topGainers,
    @Default([]) List<TradeTopMover> topLosers,
  }) = _TradeSummary;

  factory TradeSummary.fromJson(Map<String, dynamic> json) => _$TradeSummaryFromJson(json);

  /// Create empty summary
  factory TradeSummary.empty(String portfolioId, String ownerId) =>
      TradeSummary(portfolioId: portfolioId, name: portfolioId, ownerId: ownerId);
}
