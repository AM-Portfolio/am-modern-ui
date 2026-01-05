import '../../domain/entities/trade_portfolio.dart';
import '../dtos/trade_portfolio_dto.dart';
import '../dtos/trade_portfolio_summary_dto.dart';
import 'portfolio_metrics_mapper.dart';

/// Mapper for trade portfolio between DTO and domain entity
class TradePortfolioMapper {
  /// Convert TradePortfolioDto to TradePortfolio domain entity
  static TradePortfolio fromDto(TradePortfolioDto dto) => TradePortfolio(
    id: dto.portfolioId,
    name: dto.name,
    ownerId: dto.ownerId,
    totalValue: dto.totalValue,
    totalGainLoss: dto.totalGainLoss,
    totalGainLossPercentage: dto.totalGainLossPercentage,
    holdingsCount: dto.holdingsCount ?? 0,
    description: dto.description,
    lastUpdated: dto.lastUpdated != null ? DateTime.tryParse(dto.lastUpdated!) : null,
    // Trade metrics
    totalTrades: dto.totalTrades ?? 0,
    netProfitLoss: dto.netProfitLoss,
    netProfitLossPercentage: dto.netProfitLossPercentage,
    winRate: dto.winRate,
    winningTrades: dto.winningTrades ?? 0,
    losingTrades: dto.losingTrades ?? 0,
    openPositions: dto.openPositions ?? 0,
  );

  /// Convert TradePortfolioListDto to TradePortfolioList domain entity
  static TradePortfolioList fromListDto(TradePortfolioListDto dto, String userId) => TradePortfolioList(
    userId: userId,
    portfolios: dto.portfolios.map(fromDto).toList(),
    totalCount: dto.totalCount ?? dto.portfolios.length,
  );

  /// Convert array response to TradePortfolioList (API returns array directly)
  static TradePortfolioList fromArrayDto(List<TradePortfolioDto> dtos, String userId) =>
      TradePortfolioList(userId: userId, portfolios: dtos.map(fromDto).toList(), totalCount: dtos.length);

  /// Convert TradePortfolioSummaryDto to TradePortfolioSummary entity
  static TradePortfolioSummary fromSummaryDto(TradePortfolioSummaryDto dto) => TradePortfolioSummary(
    portfolioId: dto.portfolioId,
    name: dto.name,
    description: dto.description,
    ownerId: dto.ownerId,
    active: dto.active,
    currency: dto.currency,
    initialCapital: dto.initialCapital,
    currentCapital: dto.currentCapital,
    createdDate: dto.createdDate != null ? DateTime.tryParse(dto.createdDate!) : null,
    lastUpdatedDate: dto.lastUpdatedDate != null ? DateTime.tryParse(dto.lastUpdatedDate!) : null,
    metrics: PortfolioMetricsMapper.fromDto(dto.metrics),
    tradeIds: dto.tradeIds,
    winningTradeIds: dto.winningTradeIds,
    losingTradeIds: dto.losingTradeIds,
    assetAllocations: dto.assetAllocations,
  );
}
