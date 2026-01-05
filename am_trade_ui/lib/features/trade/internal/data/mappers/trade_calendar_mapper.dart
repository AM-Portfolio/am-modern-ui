import 'package:am_common/core/utils/logger.dart';
import '../../domain/entities/trade_calendar.dart';
import '../../domain/entities/trade_controller_entities.dart';
import '../dtos/trade_calendar_dto.dart';
import '../dtos/trade_controller_dtos.dart';

/// Mapper for converting trade calendar DTOs to entities
class TradeCalendarMapper {
  /// Convert TradeCalendarDto to TradeCalendar entity
  static TradeCalendar fromDto(TradeCalendarDto dto) {
    AppLogger.info('[Mapper] Converting DTO with ${dto.portfolioTrades.length} portfolios', tag: 'TradeCalendarMapper');

    final portfolioTrades = <String, List<TradeDetails>>{};

    for (final entry in dto.portfolioTrades.entries) {
      final portfolioId = entry.key;
      final tradeDetailDtos = entry.value;

      AppLogger.info(
        '[Mapper] Portfolio $portfolioId has ${tradeDetailDtos.length} trades',
        tag: 'TradeCalendarMapper',
      );

      portfolioTrades[portfolioId] = tradeDetailDtos.map(_mapTradeDetail).toList();
    }

    AppLogger.info(
      '[Mapper] Final entity has ${portfolioTrades.length} portfolios with portfolio IDs: ${portfolioTrades.keys.join(", ")}',
      tag: 'TradeCalendarMapper',
    );

    return TradeCalendar(portfolioTrades: portfolioTrades);
  }

  /// Convert TradeDetailsDto to TradeDetails entity
  static TradeDetails _mapTradeDetail(TradeDetailsDto dto) => TradeDetails(
    tradeId: dto.tradeId,
    portfolioId: dto.portfolioId,
    instrumentInfo: InstrumentInfo(
      symbol: dto.instrumentInfo.symbol,
      isin: dto.instrumentInfo.isin,
      rawSymbol: dto.instrumentInfo.rawSymbol,
      exchange: dto.instrumentInfo.exchange,
      segment: dto.instrumentInfo.segment,
      series: dto.instrumentInfo.series,
      description: dto.instrumentInfo.description,
    ),
    status: dto.status,
    tradePositionType: dto.tradePositionType,
    entryInfo: EntryExitInfo(
      timestamp: dto.entryInfo.timestamp != null ? DateTime.tryParse(dto.entryInfo.timestamp!) : null,
      price: dto.entryInfo.price,
      quantity: dto.entryInfo.quantity,
      totalValue: dto.entryInfo.totalValue,
      fees: dto.entryInfo.fees,
    ),
    exitInfo: dto.exitInfo != null
        ? EntryExitInfo(
            timestamp: dto.exitInfo!.timestamp != null ? DateTime.tryParse(dto.exitInfo!.timestamp!) : null,
            price: dto.exitInfo!.price,
            quantity: dto.exitInfo!.quantity,
            totalValue: dto.exitInfo!.totalValue,
            fees: dto.exitInfo!.fees,
          )
        : null,
    metrics: dto.metrics != null
        ? TradeMetrics(
            profitLoss: dto.metrics!.profitLoss,
            profitLossPercentage: dto.metrics!.profitLossPercentage,
            returnOnEquity: dto.metrics!.returnOnEquity,
            riskAmount: dto.metrics!.riskAmount,
            rewardAmount: dto.metrics!.rewardAmount,
            riskRewardRatio: dto.metrics!.riskRewardRatio,
            holdingTimeDays: dto.metrics!.holdingTimeDays,
            holdingTimeHours: dto.metrics!.holdingTimeHours,
            holdingTimeMinutes: dto.metrics!.holdingTimeMinutes,
            maxAdverseExcursion: dto.metrics!.maxAdverseExcursion,
            maxFavorableExcursion: dto.metrics!.maxFavorableExcursion,
          )
        : null,
    tradeExecutions: [], // Leave empty for calendar - executions not needed
  );
}
