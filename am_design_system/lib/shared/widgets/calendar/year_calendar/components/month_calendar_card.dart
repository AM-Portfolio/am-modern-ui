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
    final daysInMonth = DateUtils.getDaysInMonth(year, month);
    final firstWeekday = firstDay.weekday; // 1 = Monday, 7 = Sunday

    // Calculate month statistics
    final stats = _calculateMonthStats(monthData);

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    final service = colorService ?? CalendarColorService();
    final tint = service.getMonthBackgroundColor(stats);
    final hasActivity = (stats['totalTrades'] as int) > 0;

    // Flat surface + light tint — avoid Card elevation (looks muddy/faded).
    final surface = theme.colorScheme.surface;
    final backgroundColor = hasActivity
        ? Color.alphaBlend(tint, surface)
        : surface;
    final borderColor = hasActivity
        ? service.getMonthBorderColor(stats)
        : theme.colorScheme.outline.withValues(alpha: isDark ? 0.22 : 0.14);

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 0,
        vertical: isMobile ? 2 : 0,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(isMobile ? 12 : 12),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          isMobile ? 14 : 14,
          isMobile ? 12 : 14,
          isMobile ? 14 : 14,
          isMobile ? 12 : 14,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            MonthHeader(
              month: month,
              year: year,
              monthData: monthData,
              stats: stats,
            ),
            SizedBox(height: isMobile ? 10 : 12),
            if (showWeekdays) ...[
              _buildWeekdayHeaders(context),
              SizedBox(height: isMobile ? 6 : 6),
            ],
            _buildMonthGrid(
              context,
              month,
              daysInMonth,
              firstWeekday,
              monthData,
            ),
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
                  fontSize: compactMode ? 10 : 11,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.75),
                  letterSpacing: 0.4,
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
    const rows = 6; // Always 6 rows to maintain consistent card height

    return Column(
      children: List.generate(
        rows,
        (rowIndex) => Padding(
          padding: EdgeInsets.only(bottom: rowIndex < rows - 1 ? 2 : 0),
          child: Row(
            children: List.generate(7, (colIndex) {
              final cellIndex = rowIndex * 7 + colIndex;
              final dayNumber = cellIndex - (firstWeekday - 1) + 1;

              if (dayNumber < 1 || dayNumber > daysInMonth) {
                return Expanded(child: SizedBox(height: compactMode ? 24 : 28));
              }

              final dayData = monthData?.getDayData(dayNumber);
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(1.5),
                  child: CalendarDayCell(
                    dayNumber: dayNumber,
                    dayData: dayData,
                    month: month,
                    compactMode: compactMode,
                    onTap: onDayTap,
                    colorService: colorService,
                  ),
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
