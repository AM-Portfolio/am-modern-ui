import 'package:freezed_annotation/freezed_annotation.dart';

import '../../internal/domain/entities/trade_controller_entities.dart';

part 'calendar_view_models.freezed.dart';

/// Enum for calendar view types
enum CalendarViewType { yearly, monthly, daily }

/// Base calendar period data
abstract class CalendarPeriodData {
  DateTime get startDate;
  DateTime get endDate;
  int get totalTrades;
  double get totalPnL;
  int get winningTrades;
  int get losingTrades;

  double get winRate => totalTrades > 0 ? winningTrades / totalTrades * 100 : 0.0;
  bool get isProfitable => totalPnL > 0;
}

/// Yearly calendar data model
@freezed
abstract class YearlyCalendarData with _$YearlyCalendarData implements CalendarPeriodData {
  const factory YearlyCalendarData({
    required int year,
    required List<MonthSummary> months,
    required int totalTrades,
    required double totalPnL,
    required int winningTrades,
    required int losingTrades,
    required double avgMonthlyPnL,
    required int bestMonth,
    required int worstMonth,
  }) = _YearlyCalendarData;

  const YearlyCalendarData._();

  @override
  DateTime get startDate => DateTime(year);

  @override
  DateTime get endDate => DateTime(year, 12, 31);

  @override
  double get winRate => totalTrades > 0 ? winningTrades / totalTrades * 100 : 0.0;

  @override
  bool get isProfitable => totalPnL > 0;

  /// Get data for a specific month (1-12)
  MonthSummary? getMonthData(int month) {
    try {
      return months.firstWhere((m) => m.month == month);
    } catch (e) {
      return null;
    }
  }

  /// Get profitable months count
  int get profitableMonths => months.where((m) => m.isProfitable).length;

  /// Get months with trades
  int get activeMonths => months.where((m) => m.totalTrades > 0).length;
}

/// Monthly calendar data model
@freezed
abstract class MonthlyCalendarData with _$MonthlyCalendarData implements CalendarPeriodData {
  const factory MonthlyCalendarData({
    required int year,
    required int month,
    required List<DaySummary> days,
    required int totalTrades,
    required double totalPnL,
    required int winningTrades,
    required int losingTrades,
    required double avgDailyPnL,
    required int bestDay,
    required int worstDay,
    required int tradingDays,
  }) = _MonthlyCalendarData;

  const MonthlyCalendarData._();

  @override
  DateTime get startDate => DateTime(year, month);

  @override
  DateTime get endDate => DateTime(year, month + 1, 0); // Last day of month

  @override
  double get winRate => totalTrades > 0 ? winningTrades / totalTrades * 100 : 0.0;

  @override
  bool get isProfitable => totalPnL > 0;

  /// Get data for a specific day
  DaySummary? getDayData(int day) {
    try {
      return days.firstWhere((d) => d.day == day);
    } catch (e) {
      return null;
    }
  }

  /// Get profitable days count
  int get profitableDays => days.where((d) => d.isProfitable).length;

  /// Get days with trades
  int get activeDays => days.where((d) => d.totalTrades > 0).length;

  /// Get total days in month
  int get totalDaysInMonth => DateTime(year, month + 1, 0).day;
}

/// Daily calendar data model
@freezed
abstract class DailyCalendarData with _$DailyCalendarData implements CalendarPeriodData {
  const factory DailyCalendarData({
    required DateTime date,
    required List<TradeDetails> trades,
    required int totalTrades,
    required double totalPnL,
    required int winningTrades,
    required int losingTrades,
    required double totalVolume,
    required Duration avgHoldingTime,
    required Map<String, int> symbolDistribution,
  }) = _DailyCalendarData;

  const DailyCalendarData._();

  @override
  DateTime get startDate => date;

  @override
  DateTime get endDate => date;

  @override
  double get winRate => totalTrades > 0 ? winningTrades / totalTrades * 100 : 0.0;

  @override
  @override
  bool get isProfitable => totalPnL > 0;

  /// Get trades for specific symbol
  List<TradeDetails> getTradesForSymbol(String symbol) =>
      trades.where((t) => t.instrumentInfo.symbol == symbol).toList();

  /// Get unique symbols traded
  List<String> get uniqueSymbols => symbolDistribution.keys.toList();

  /// Get most traded symbol
  String? get mostTradedSymbol {
    if (symbolDistribution.isEmpty) return null;
    return symbolDistribution.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }
}

/// Month summary for yearly view
@freezed
abstract class MonthSummary with _$MonthSummary {
  const factory MonthSummary({
    required int month,
    required int year,
    required int totalTrades,
    required double totalPnL,
    required int winningTrades,
    required int losingTrades,
    required int tradingDays,
  }) = _MonthSummary;

  const MonthSummary._();

  double get winRate => totalTrades > 0 ? winningTrades / totalTrades * 100 : 0.0;
  bool get isProfitable => totalPnL > 0;
  DateTime get date => DateTime(year, month);

  String get monthName {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}

/// Day summary for monthly view
@freezed
abstract class DaySummary with _$DaySummary {
  const factory DaySummary({
    required int day,
    required int month,
    required int year,
    required int totalTrades,
    required double totalPnL,
    required int winningTrades,
    required int losingTrades,
  }) = _DaySummary;

  const DaySummary._();

  double get winRate => totalTrades > 0 ? winningTrades / totalTrades * 100 : 0.0;
  bool get isProfitable => totalPnL > 0;
  DateTime get date => DateTime(year, month, day);

  String get dayOfWeek {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final weekday = date.weekday;
    return days[weekday - 1];
  }
}

/// Calendar navigation state
@freezed
abstract class CalendarNavigationState with _$CalendarNavigationState {
  const factory CalendarNavigationState({
    required CalendarViewType viewType,
    required int year,
    int? month,
    int? day,
    @Default([]) List<CalendarBreadcrumb> breadcrumbs,
  }) = _CalendarNavigationState;

  const CalendarNavigationState._();

  /// Create initial state (yearly view, current year)
  factory CalendarNavigationState.initial() {
    final now = DateTime.now();
    return CalendarNavigationState(
      viewType: CalendarViewType.yearly,
      year: now.year,
      breadcrumbs: [CalendarBreadcrumb(label: '${now.year}', year: now.year)],
    );
  }

  /// Navigate to monthly view
  CalendarNavigationState toMonthly(int selectedMonth) => CalendarNavigationState(
    viewType: CalendarViewType.monthly,
    year: year,
    month: selectedMonth,
    breadcrumbs: [
      CalendarBreadcrumb(label: '$year', year: year),
      CalendarBreadcrumb(label: _getMonthName(selectedMonth), year: year, month: selectedMonth),
    ],
  );

  /// Navigate to daily view
  CalendarNavigationState toDaily(int selectedDay) {
    if (month == null) {
      throw StateError('Cannot navigate to daily view without month');
    }
    return CalendarNavigationState(
      viewType: CalendarViewType.daily,
      year: year,
      month: month,
      day: selectedDay,
      breadcrumbs: [
        CalendarBreadcrumb(label: '$year', year: year),
        CalendarBreadcrumb(label: _getMonthName(month!), year: year, month: month),
        CalendarBreadcrumb(label: '$selectedDay ${_getMonthName(month!)}', year: year, month: month, day: selectedDay),
      ],
    );
  }

  /// Navigate back to yearly view
  CalendarNavigationState toYearly() => CalendarNavigationState(
    viewType: CalendarViewType.yearly,
    year: year,
    breadcrumbs: [CalendarBreadcrumb(label: '$year', year: year)],
  );

  /// Navigate to different year
  CalendarNavigationState changeYear(int newYear) => CalendarNavigationState(
    viewType: CalendarViewType.yearly,
    year: newYear,
    breadcrumbs: [CalendarBreadcrumb(label: '$newYear', year: newYear)],
  );

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }
}

/// Breadcrumb for navigation
@freezed
abstract class CalendarBreadcrumb with _$CalendarBreadcrumb {
  const factory CalendarBreadcrumb({required String label, required int year, int? month, int? day}) =
      _CalendarBreadcrumb;
}
