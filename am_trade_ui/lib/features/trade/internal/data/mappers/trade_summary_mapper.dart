import '../../domain/entities/trade_summary.dart';
import '../dtos/portfolio_metrics_dto.dart';
import '../dtos/trade_portfolio_summary_dto.dart';
import '../dtos/trade_summary_dto.dart';

/// Mapper for trade summary between DTO and domain entity
class TradeSummaryMapper {
  /// Convert PortfolioMetricsDto to TradeMetrics domain entity
  static TradeMetrics fromMetricsDto(PortfolioMetricsDto? dto) {
    if (dto == null) return TradeMetrics.empty();

    return TradeMetrics(
      totalTrades: dto.totalTrades,
      winningTrades: dto.winningTrades,
      losingTrades: dto.losingTrades,
      breakEvenTrades: dto.breakEvenTrades,
      openPositions: dto.openPositions,
      winRate: dto.winRate,
      lossRate: dto.lossRate,
      profitFactor: dto.profitFactor,
      expectancy: dto.expectancy,
      totalValue: dto.totalValue,
      totalProfit: dto.totalProfit,
      totalLoss: dto.totalLoss,
      netProfitLoss: dto.netProfitLoss,
      netProfitLossPercentage: dto.netProfitLossPercentage,
      maxDrawdown: dto.maxDrawdown,
      maxDrawdownPercentage: dto.maxDrawdownPercentage,
      sharpeRatio: dto.sharpeRatio,
      sortinoRatio: dto.sortinoRatio,
    );
  }

  /// Convert TradeAssetAllocationDto to TradeAssetAllocation domain entity
  /// (To be implemented when asset allocation data becomes available)
  static List<TradeAssetAllocation>? fromAssetAllocationsDto(Map<String, dynamic>? dto) {
    // This will be implemented when the API provides proper asset allocation structure
    return null;
  }

  /// Convert TradeTopMoverDto to TradeTopMover domain entity
  static TradeTopMover fromTopMoverDto(TradeTopMoverDto dto) => TradeTopMover(
    symbol: dto.symbol,
    name: dto.name,
    change: dto.change,
    changePercentage: dto.changePercentage,
    currentPrice: dto.currentPrice,
  );

  /// Convert TradePortfolioSummaryDto to TradeSummary domain entity
  static TradeSummary fromPortfolioSummaryDto(TradePortfolioSummaryDto dto) => TradeSummary(
    portfolioId: dto.portfolioId,
    name: dto.name,
    ownerId: dto.ownerId ?? '',
    description: dto.description,
    active: dto.active,
    currency: dto.currency,
    initialCapital: dto.initialCapital,
    currentCapital: dto.currentCapital,
    createdDate: dto.createdDate != null ? DateTime.tryParse(dto.createdDate!) : null,
    lastUpdatedDate: dto.lastUpdatedDate != null ? DateTime.tryParse(dto.lastUpdatedDate!) : null,
    metrics: fromMetricsDto(dto.metrics),
    tradeIds: dto.tradeIds,
    winningTradeIds: dto.winningTradeIds,
    losingTradeIds: dto.losingTradeIds,
    assetAllocations: fromAssetAllocationsDto(dto.assetAllocations),
    // Top movers will be calculated later in development
    topGainers: [],
    topLosers: [],
  );

  /// Convert TradeSummaryDto to TradeSummary domain entity
  /// (Legacy method - keeping for backward compatibility if needed)
  @Deprecated('Use fromPortfolioSummaryDto instead')
  static TradeSummary fromDto(TradeSummaryDto dto, String userId, String portfolioId, [String? portfolioName]) =>
      TradeSummary(
        portfolioId: portfolioId,
        name: portfolioName ?? portfolioId,
        ownerId: userId,
        // Map old fields to new structure (this is a simplified mapping)
        // This method should be updated or removed based on actual usage
      );

  /// Convert TradeSummary domain entity to TradePortfolioSummaryDto
  static TradePortfolioSummaryDto toDto(TradeSummary entity) => TradePortfolioSummaryDto(
    portfolioId: entity.portfolioId,
    name: entity.name,
    description: entity.description,
    ownerId: entity.ownerId,
    active: entity.active,
    currency: entity.currency,
    initialCapital: entity.initialCapital,
    currentCapital: entity.currentCapital,
    createdDate: entity.createdDate?.toIso8601String(),
    lastUpdatedDate: entity.lastUpdatedDate?.toIso8601String(),
    metrics: PortfolioMetricsDto(
      totalTrades: entity.metrics.totalTrades,
      winningTrades: entity.metrics.winningTrades,
      losingTrades: entity.metrics.losingTrades,
      breakEvenTrades: entity.metrics.breakEvenTrades,
      openPositions: entity.metrics.openPositions,
      winRate: entity.metrics.winRate,
      lossRate: entity.metrics.lossRate,
      profitFactor: entity.metrics.profitFactor,
      expectancy: entity.metrics.expectancy,
      totalValue: entity.metrics.totalValue,
      totalProfit: entity.metrics.totalProfit,
      totalLoss: entity.metrics.totalLoss,
      netProfitLoss: entity.metrics.netProfitLoss,
      netProfitLossPercentage: entity.metrics.netProfitLossPercentage,
      maxDrawdown: entity.metrics.maxDrawdown,
      maxDrawdownPercentage: entity.metrics.maxDrawdownPercentage,
      sharpeRatio: entity.metrics.sharpeRatio,
      sortinoRatio: entity.metrics.sortinoRatio,
    ),
    tradeIds: entity.tradeIds,
    winningTradeIds: entity.winningTradeIds,
    losingTradeIds: entity.losingTradeIds,
  );
}
