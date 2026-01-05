import 'package:am_design_system/am_design_system.dart';
import '../../internal/domain/entities/trade_calendar.dart';
import '../../internal/domain/entities/trade_controller_entities.dart';

/// Converter to transform TradeCalendar entity to year calendar data
class YearCalendarConverter {
  /// Convert TradeCalendar entity to months data for year calendar
  static Map<int, CalendarMonthData> convertToMonthsData({
    required TradeCalendar entity,
    required String portfolioId,
    required int year,
  }) {
    final trades = entity.portfolioTrades[portfolioId] ?? [];

    // Filter trades for the specified year
    final yearTrades = trades.where((trade) {
      final tradeDate = trade.entryInfo.timestamp;
      return tradeDate != null && tradeDate.year == year;
    }).toList();

    // Group trades by month and day
    final monthsMap = <int, Map<int, List<TradeDetails>>>{};
    for (final trade in yearTrades) {
      final tradeDate = trade.entryInfo.timestamp;
      if (tradeDate != null) {
        final month = tradeDate.month;
        final day = tradeDate.day;

        monthsMap.putIfAbsent(month, () => {});
        monthsMap[month]!.putIfAbsent(day, () => []).add(trade);
      }
    }

    // Build calendar month data
    final months = <int, CalendarMonthData>{};

    for (var month = 1; month <= 12; month++) {
      final monthTrades = monthsMap[month] ?? {};

      // Build day data for this month
      final days = <int, CalendarDayData>{};
      for (final entry in monthTrades.entries) {
        final day = entry.key;
        final dayTrades = entry.value;

        var pnl = 0.0;
        for (final trade in dayTrades) {
          pnl += trade.metrics?.profitLoss ?? 0.0;
        }

        final status = _getDayStatus(pnl);

        days[day] = CalendarDayData(
          date: DateTime(year, month, day),
          status: status,
          pnl: pnl,
          tradeCount: dayTrades.length,
        );
      }

      months[month] = CalendarMonthData(year: year, month: month, days: days);
    }

    return months;
  }

  /// Get day status from P&L
  static TradeDayStatus _getDayStatus(double pnl) {
    if (pnl > 0) return TradeDayStatus.win;
    if (pnl < 0) return TradeDayStatus.loss;
    return TradeDayStatus.breakeven;
  }
}
