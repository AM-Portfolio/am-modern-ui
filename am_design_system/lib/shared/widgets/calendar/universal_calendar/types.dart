/// Types and enums for universal calendar date selector system
library;

// Re-export year calendar types for use in factory without direct dependency
export '../year_calendar/calendar_types.dart' show CalendarMonthData;

/// Date selector template composition types
enum CalendarTemplateType {
  minimal, // Filter display only, no selectors
  compact, // Filter + compact date selectors
  full, // All components with full features
  dashboard, // Optimized for dashboard widgets
  adaptive, // Adapts based on screen size and config
}

/// Filter mode types for date selection
enum DateFilterMode {
  quick, // Quick predefined ranges (Last 7 days, etc.)
  period, // Time periods (This month, quarter, year)
  custom, // Custom date range picker
  advanced, // Combination of all modes
}

/// Date range types for quick selection
enum QuickRangeType {
  last7Days('Last 7 Days', 7),
  last30Days('Last 30 Days', 30),
  last90Days('Last 3 Months', 90),
  last6Months('Last 6 Months', 180),
  lastYear('Last Year', 365);

  const QuickRangeType(this.label, this.days);
  final String label;
  final int days;
}

/// Time period types for structured selection
enum TimePeriodType {
  thisWeek('This Week', 'current_week'),
  thisMonth('This Month', 'current_month'),
  thisQuarter('This Quarter', 'current_quarter'),
  thisYear('This Year', 'current_year'),
  lastWeek('Last Week', 'previous_week'),
  lastMonth('Last Month', 'previous_month'),
  lastQuarter('Last Quarter', 'previous_quarter'),
  lastYear('Last Year', 'previous_year');

  const TimePeriodType(this.label, this.code);
  final String label;
  final String code;
}

/// Date selection result with context
class DateSelection {
  const DateSelection({
    required this.startDate,
    required this.endDate,
    required this.description,
    required this.filterType,
    this.metadata,
  });

  final DateTime? startDate;
  final DateTime? endDate;
  final String description;
  final DateFilterMode filterType;
  final Map<String, dynamic>? metadata;

  DateSelection copyWith({
    DateTime? startDate,
    DateTime? endDate,
    String? description,
    DateFilterMode? filterType,
    Map<String, dynamic>? metadata,
  }) => DateSelection(
    startDate: startDate ?? this.startDate,
    endDate: endDate ?? this.endDate,
    description: description ?? this.description,
    filterType: filterType ?? this.filterType,
    metadata: metadata ?? this.metadata,
  );

  bool get hasDateRange => startDate != null && endDate != null;
  bool get isEmpty => !hasDateRange;

  @override
  String toString() => 'DateSelection($description, $startDate - $endDate)';
}
