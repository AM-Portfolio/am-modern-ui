import '../../domain/entities/portfolio_metrics.dart';
import '../dtos/portfolio_metrics_dto.dart';

class PortfolioMetricsMapper {
  static PortfolioMetrics? fromDto(PortfolioMetricsDto? dto) {
    if (dto == null) return null;

    return PortfolioMetrics(
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
      monthlyReturns: dto.monthlyReturns,
      weeklyReturns: dto.weeklyReturns,
    );
  }

  static PortfolioMetricsDto fromEntity(PortfolioMetrics entity) {
    return PortfolioMetricsDto(
      totalTrades: entity.totalTrades,
      winningTrades: entity.winningTrades,
      losingTrades: entity.losingTrades,
      breakEvenTrades: entity.breakEvenTrades,
      openPositions: entity.openPositions,
      winRate: entity.winRate,
      lossRate: entity.lossRate,
      profitFactor: entity.profitFactor,
      expectancy: entity.expectancy,
      totalValue: entity.totalValue,
      totalProfit: entity.totalProfit,
      totalLoss: entity.totalLoss,
      netProfitLoss: entity.netProfitLoss,
      netProfitLossPercentage: entity.netProfitLossPercentage,
      maxDrawdown: entity.maxDrawdown,
      maxDrawdownPercentage: entity.maxDrawdownPercentage,
      sharpeRatio: entity.sharpeRatio,
      sortinoRatio: entity.sortinoRatio,
      monthlyReturns: entity.monthlyReturns,
      weeklyReturns: entity.weeklyReturns,
    );
  }
}
