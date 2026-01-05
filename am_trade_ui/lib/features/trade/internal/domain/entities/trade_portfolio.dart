import 'package:freezed_annotation/freezed_annotation.dart';

import 'portfolio_metrics.dart';

part 'trade_portfolio.freezed.dart';

/// Domain entity for trade portfolio discovery
@freezed
abstract class TradePortfolio with _$TradePortfolio {
  const factory TradePortfolio({
    required String id,
    required String name,
    String? ownerId,
    double? totalValue,
    double? totalGainLoss,
    double? totalGainLossPercentage,
    @Default(0) int holdingsCount,
    String? description,
    DateTime? lastUpdated,

    // Trade metrics for overview
    @Default(0) int totalTrades,
    double? netProfitLoss,
    double? netProfitLossPercentage,
    double? winRate,
    @Default(0) int winningTrades,
    @Default(0) int losingTrades,
    @Default(0) int openPositions,
  }) = _TradePortfolio;
}

/// Domain entity for comprehensive portfolio summary with advanced metrics
@freezed
abstract class TradePortfolioSummary with _$TradePortfolioSummary {
  const factory TradePortfolioSummary({
    required String portfolioId,
    required String name,
    String? description,
    String? ownerId,
    @Default(true) bool active,
    String? currency,
    double? initialCapital,
    double? currentCapital,
    DateTime? createdDate,
    DateTime? lastUpdatedDate,
    PortfolioMetrics? metrics,
    @Default([]) List<String> tradeIds,
    List<String>? winningTradeIds,
    List<String>? losingTradeIds,
    Map<String, dynamic>? assetAllocations,
  }) = _TradePortfolioSummary;
}

/// Domain entity for trade portfolio list
@freezed
abstract class TradePortfolioList with _$TradePortfolioList {
  const factory TradePortfolioList({
    required String userId,
    required List<TradePortfolio> portfolios,
    @Default(0) int totalCount,
  }) = _TradePortfolioList;

  /// Create empty portfolio list
  factory TradePortfolioList.empty(String userId) => TradePortfolioList(userId: userId, portfolios: []);
}
