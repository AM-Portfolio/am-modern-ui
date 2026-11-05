import '../../domain/entities/trade_metrics.dart';
import '../dtos/trade_controller_dtos.dart';

class TradeMetricsMapper {
  static TradeMetrics? fromDto(TradeMetricsDto? dto) {
    if (dto == null) return null;

    return TradeMetrics(
      profitLoss: dto.profitLoss,
      profitLossPercentage: dto.profitLossPercentage,
      todayProfitLoss: dto.todayProfitLoss,
      todayProfitLossPercentage: dto.todayProfitLossPercentage,
      unrealizedBasis: dto.unrealizedBasis,
      returnOnEquity: dto.returnOnEquity,
      riskAmount: dto.riskAmount,
      rewardAmount: dto.rewardAmount,
      riskRewardRatio: dto.riskRewardRatio,
      holdingTimeDays: dto.holdingTimeDays ?? 0,
      holdingTimeHours: dto.holdingTimeHours ?? 0,
      holdingTimeMinutes: dto.holdingTimeMinutes ?? 0,
      maxAdverseExcursion: dto.maxAdverseExcursion,
      maxFavorableExcursion: dto.maxFavorableExcursion,
    );
  }

  static TradeMetricsDto fromEntity(TradeMetrics entity) {
    return TradeMetricsDto(
      profitLoss: entity.profitLoss,
      profitLossPercentage: entity.profitLossPercentage,
      todayProfitLoss: entity.todayProfitLoss,
      todayProfitLossPercentage: entity.todayProfitLossPercentage,
      unrealizedBasis: entity.unrealizedBasis,
      returnOnEquity: entity.returnOnEquity,
      riskAmount: entity.riskAmount,
      rewardAmount: entity.rewardAmount,
      riskRewardRatio: entity.riskRewardRatio,
      holdingTimeDays: entity.holdingTimeDays,
      holdingTimeHours: entity.holdingTimeHours,
      holdingTimeMinutes: entity.holdingTimeMinutes,
      maxAdverseExcursion: entity.maxAdverseExcursion,
      maxFavorableExcursion: entity.maxFavorableExcursion,
    );
  }
}
