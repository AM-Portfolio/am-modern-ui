import 'package:flutter/material.dart';

import '../calendar_types.dart';
import '../services/calendar_color_service.dart';
import 'calendar_day_cell.dart';
import 'month_header.dart';

/// Individual month calendar card component
class MonthCalendarCard extends StatelessWidget {
  const MonthCalendarCard({
    required this.year,
    required this.month,
    required this.monthData,
    super.key,
    this.showWeekdays = true,
    this.compactMode = false,
    this.onDayTap,
    this.colorService,
  });

  final int year;
  final int month;
  final CalendarMonthData? monthData;
  final bool showWeekdays;
  final bool compactMode;
  final Function(DateTime date, CalendarDayData dayData)? onDayTap;
  final CalendarColorService? colorService;

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(year, month);
    final lastDay = DateTime(year, month + 1, 0);
    final daysInMonth = lastDay.day;
    final firstWeekday = firstDay.weekday; // 1 = Monday, 7 = Sunday

    // Calculate month statistics
    final stats = _calculateMonthStats(monthData);

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    final service = colorService ?? CalendarColorService();
    final backgroundColor = service.getMonthBackgroundColor(stats);
    final borderColor = service.getMonthBorderColor(stats);

    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      color: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
        side: BorderSide(color: borderColor),
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 8 : 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Month header with stats
            MonthHeader(month: month, monthData: monthData, stats: stats),
            SizedBox(height: isMobile ? 6 : 10),

            // Weekday headers
            if (showWeekdays) ...[_buildWeekdayHeaders(context), const SizedBox(height: 4)],

            // Calendar grid
            _buildMonthGrid(context, month, daysInMonth, firstWeekday, monthData),
          ],
        ),
      ),
    );
  }

  /// Build weekday headers
  Widget _buildWeekdayHeaders(BuildContext context) => Row(
    children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
        .map(
          (day) => Expanded(
            child: Center(
              child: Text(
                day,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: compactMode ? 9 : 10,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        )
        .toList(),
  );

  /// Build month calendar grid
  Widget _buildMonthGrid(
    BuildContext context,
    int month,
    int daysInMonth,
    int firstWeekday,
    CalendarMonthData? monthData,
  ) {
    final totalCells = daysInMonth + (firstWeekday - 1);
    final rows = (totalCells / 7).ceil();

    return Column(
      children: List.generate(
        rows,
        (rowIndex) => Padding(
          padding: EdgeInsets.only(bottom: rowIndex < rows - 1 ? 2 : 0),
          child: Row(
            children: List.generate(7, (colIndex) {
              final cellIndex = rowIndex * 7 + colIndex;
              final dayNumber = cellIndex - (firstWeekday - 1) + 1;

              // Empty cell
              if (dayNumber < 1 || dayNumber > daysInMonth) {
                return const Expanded(child: SizedBox(height: 20));
              }

              final dayData = monthData?.getDayData(dayNumber);
              return Expanded(
                child: CalendarDayCell(
                  dayNumber: dayNumber,
                  dayData: dayData,
                  month: month,
                  compactMode: compactMode,
                  onTap: onDayTap,
                  colorService: colorService,
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  /// Calculate month statistics including trade days
  Map<String, dynamic> _calculateMonthStats(CalendarMonthData? monthData) {
    if (monthData == null) {
      return {'totalTrades': 0, 'winRate': 0.0, 'totalPnL': 0.0, 'tradeDays': 0};
    }

    var totalTrades = 0;
    var winningTrades = 0;
    var totalPnL = 0.0;
    var tradeDays = 0;

    for (final dayData in monthData.days.values) {
      if (dayData.hasTrades) {
        tradeDays++;
      }
      totalTrades += dayData.tradeCount;
      if (dayData.status == TradeDayStatus.win) {
        winningTrades += dayData.tradeCount;
      }
      totalPnL += dayData.pnl;
    }

    final winRate = totalTrades > 0 ? (winningTrades / totalTrades) * 100 : 0.0;

    return {'totalTrades': totalTrades, 'winRate': winRate, 'totalPnL': totalPnL, 'tradeDays': tradeDays};
  }
}
