import 'package:am_common/core/utils/logger.dart';
import 'package:am_design_system/am_design_system.dart';
import '../../internal/domain/entities/trade_calendar.dart';
import '../../internal/domain/entities/trade_controller_entities.dart';

/// Converter class for transforming TradeCalendar entities to universal calendar data
/// This converter bridges the gap between trade domain entities and the calendar widget
class TradeCalendarConverter {
  /// Private constructor to prevent instantiation
  TradeCalendarConverter._();

  /// Main conversion method from TradeCalendar to calendar data format
  /// Transforms trade entities with portfolio trades into calendar-compatible format
  static Map<String, List<CardData>> convertEntityToCalendarData({required TradeCalendar entity}) {
    AppLogger.methodEntry(
      'convertEntityToCalendarData',
      tag: 'TradeCalendarConverter',
      params: {'portfolioTradesCount': entity.portfolioTrades.length},
    );

    try {
      final result = <String, List<CardData>>{};

      // Process all trades from all portfolios
      for (final portfolioEntry in entity.portfolioTrades.entries) {
        final trades = portfolioEntry.value;

        // Group trades by date
        for (final trade in trades) {
          // Use entry timestamp as trade date
          final tradeDate = trade.entryInfo.timestamp;
          if (tradeDate == null) continue; // Skip if no entry date

          final dateKey = _formatDateKey(tradeDate);

          if (!result.containsKey(dateKey)) {
            result[dateKey] = [];
          }

          // Add this trade's data to the date's card data
          final existingCards = result[dateKey]!;
          final updatedCards = _addTradeToCardData(existingCards, trade, dateKey);
          result[dateKey] = updatedCards;
        }
      }

      AppLogger.info(
        'Successfully converted entity to calendar data: ${result.length} dates',
        tag: 'TradeCalendarConverter',
      );

      return result;
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to convert entity to calendar data: $error',
        tag: 'TradeCalendarConverter',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Add a trade to existing card data or create new card data
  static List<CardData> _addTradeToCardData(List<CardData> existingCards, TradeDetails trade, String dateKey) {
    // Check if we already have a trade card for this date
    final existingTradeCardIndex = existingCards.indexWhere((card) => card is TradeCardData);

    if (existingTradeCardIndex >= 0) {
      // Update existing trade card
      final existingCard = existingCards[existingTradeCardIndex] as TradeCardData;
      final updatedCard = _updateTradeCardData(existingCard, trade);

      final updatedCards = List<CardData>.from(existingCards);
      updatedCards[existingTradeCardIndex] = updatedCard;
      return updatedCards;
    } else {
      // Create new trade card
      final newCard = _createTradeCardData(dateKey, [trade]);
      return [...existingCards, newCard];
    }
  }

  /// Create trade card data for a specific date
  static TradeCardData _createTradeCardData(String dateKey, List<TradeDetails> trades) {
    final totalPnL = trades.fold<double>(0.0, (sum, trade) => sum + (trade.metrics?.profitLoss ?? 0.0));
    final winningTrades = trades.where((trade) => (trade.metrics?.profitLoss ?? 0.0) > 0).length;
    final losingTrades = trades.where((trade) => (trade.metrics?.profitLoss ?? 0.0) < 0).length;
    final totalVolume = trades.fold<double>(0.0, (sum, trade) => sum + (trade.entryInfo.quantity?.toDouble() ?? 0.0));

    return TradeCardData(
      dateKey: dateKey,
      pnl: totalPnL,
      tradeCount: trades.length,
      winCount: winningTrades,
      lossCount: losingTrades,
      totalVolume: totalVolume,
      winRate: trades.isNotEmpty ? winningTrades / trades.length : 0.0,
      trades: trades
          .map(
            (trade) => {
              'symbol': trade.instrumentInfo.symbol,
              'quantity': trade.entryInfo.quantity,
              'pnl': trade.metrics?.profitLoss,
              'executionDate': trade.entryInfo.timestamp?.toIso8601String(),
              'tradeId': trade.tradeId,
              'status': trade.status.name,
            },
          )
          .toList(),
      metadata: {
        'totalValue': trades.fold<double>(0.0, (sum, trade) => sum + (trade.entryInfo.totalValue ?? 0.0)),
        'avgPnL': trades.isNotEmpty ? totalPnL / trades.length : 0.0,
        'avgHoldingTime': trades.isNotEmpty
            ? trades.fold<int>(0, (sum, trade) => sum + (trade.metrics?.holdingTimeDays ?? 0)) / trades.length
            : 0,
      },
    );
  }

  /// Update existing trade card data with new trade
  static TradeCardData _updateTradeCardData(TradeCardData existingCard, TradeDetails newTrade) {
    final isProfitable = (newTrade.metrics?.profitLoss ?? 0.0) > 0;
    final isLoss = (newTrade.metrics?.profitLoss ?? 0.0) < 0;
    final updatedPnL = existingCard.pnl + (newTrade.metrics?.profitLoss ?? 0.0);
    final updatedTradeCount = existingCard.tradeCount + 1;
    final updatedWinCount = existingCard.winCount + (isProfitable ? 1 : 0);
    final updatedLossCount = existingCard.lossCount + (isLoss ? 1 : 0);
    final updatedTotalVolume = (existingCard.totalVolume ?? 0) + (newTrade.entryInfo.quantity?.toDouble() ?? 0.0);

    final newTradeData = {
      'symbol': newTrade.instrumentInfo.symbol,
      'quantity': newTrade.entryInfo.quantity,
      'pnl': newTrade.metrics?.profitLoss,
      'executionDate': newTrade.entryInfo.timestamp?.toIso8601String(),
      'tradeId': newTrade.tradeId,
      'status': newTrade.status.name,
    };

    return TradeCardData(
      dateKey: existingCard.dateKey,
      pnl: updatedPnL,
      tradeCount: updatedTradeCount,
      winCount: updatedWinCount,
      lossCount: updatedLossCount,
      totalVolume: updatedTotalVolume,
      winRate: updatedTradeCount > 0 ? updatedWinCount / updatedTradeCount : 0.0,
      trades: [...existingCard.trades, newTradeData],
      metadata: {
        ...?existingCard.metadata,
        'totalValue': (existingCard.metadata?['totalValue'] ?? 0.0) + newTrade.entryInfo.totalValue,
        'avgPnL': updatedTradeCount > 0 ? updatedPnL / updatedTradeCount : 0.0,
      },
    );
  }

  /// Formats date key for calendar data grouping
  static String _formatDateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
