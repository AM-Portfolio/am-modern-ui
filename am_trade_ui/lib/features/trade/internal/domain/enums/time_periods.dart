import 'package:json_annotation/json_annotation.dart';

/// Predefined time periods for quick date range selection
@JsonEnum(fieldRename: FieldRename.screamingSnake)
enum TimePeriods {
  today,
  yesterday,
  last7Days,
  last14Days,
  last30Days,
  thisWeek,
  lastWeek,
  thisMonth,
  lastMonth,
  thisQuarter,
  lastQuarter,
  thisYear,
  lastYear,
  last3Months,
  last6Months,
  last12Months,
  last2Years,
  last3Years,
  last5Years,
  custom,
}

/// Extension for TimePeriods enum
extension TimePeriodsExtension on TimePeriods {
  String get displayName {
    switch (this) {
      case TimePeriods.today:
        return 'Today';
      case TimePeriods.yesterday:
        return 'Yesterday';
      case TimePeriods.last7Days:
        return 'Last 7 Days';
      case TimePeriods.last14Days:
        return 'Last 14 Days';
      case TimePeriods.last30Days:
        return 'Last 30 Days';
      case TimePeriods.thisWeek:
        return 'This Week';
      case TimePeriods.lastWeek:
        return 'Last Week';
      case TimePeriods.thisMonth:
        return 'This Month';
      case TimePeriods.lastMonth:
        return 'Last Month';
      case TimePeriods.thisQuarter:
        return 'This Quarter';
      case TimePeriods.lastQuarter:
        return 'Last Quarter';
      case TimePeriods.thisYear:
        return 'This Year';
      case TimePeriods.lastYear:
        return 'Last Year';
      case TimePeriods.last3Months:
        return 'Last 3 Months';
      case TimePeriods.last6Months:
        return 'Last 6 Months';
      case TimePeriods.last12Months:
        return 'Last 12 Months';
      case TimePeriods.last2Years:
        return 'Last 2 Years';
      case TimePeriods.last3Years:
        return 'Last 3 Years';
      case TimePeriods.last5Years:
        return 'Last 5 Years';
      case TimePeriods.custom:
        return 'Custom';
    }
  }
}
