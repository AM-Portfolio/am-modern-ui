/// Simple calendar types for year-at-a-glance view
library;

import 'package:flutter/material.dart';

/// Trade day status for color coding
enum TradeDayStatus {
  win, // Profitable day (green)
  loss, // Loss day (red)
  breakeven, // No profit/loss (gray)
  noTrades, // No trades on this day
}

/// Data for a single day
class CalendarDayData {
  const CalendarDayData({required this.date, required this.status, this.pnl = 0.0, this.tradeCount = 0});

  final DateTime date;
  final TradeDayStatus status;
  final double pnl;
  final int tradeCount;

  /// Get color for this day
  Color getColor({double opacity = 1.0}) {
    switch (status) {
      case TradeDayStatus.win:
        return Colors.green.withOpacity(opacity);
      case TradeDayStatus.loss:
        return Colors.red.withOpacity(opacity);
      case TradeDayStatus.breakeven:
        return Colors.grey.withOpacity(opacity);
      case TradeDayStatus.noTrades:
        return Colors.transparent;
    }
  }

  bool get hasTrades => tradeCount > 0;
}

/// Data for a month
class CalendarMonthData {
  const CalendarMonthData({required this.year, required this.month, required this.days});

  final int year;
  final int month; // 1-12
  final Map<int, CalendarDayData> days; // day number (1-31) -> data

  String get monthName {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  CalendarDayData? getDayData(int day) => days[day];
}

/// Configuration for year calendar
class YearCalendarConfig {
  const YearCalendarConfig({
    this.showHeader = true,
    this.compactMode = false,
    this.monthsPerRow = 4, // 4 columns = 3 rows
    this.showWeekdays = true,
    this.onDayTap,
  });

  final bool showHeader;
  final bool compactMode;
  final int monthsPerRow;
  final bool showWeekdays;
  final Function(DateTime date, CalendarDayData data)? onDayTap;
}
