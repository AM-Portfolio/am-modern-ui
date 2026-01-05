import 'package:flutter/material.dart';

import 'package:am_design_system/am_design_system.dart'
    as calendar_config;
import 'package:am_design_system/am_design_system.dart';

/// Configuration manager for trade calendar
/// Handles all configuration logic for trade-specific calendar display
class TradeCalendarConfig {
  /// Gets the appropriate calendar configuration for trade calendar display
  /// Loads configuration based on current environmen

  /// Gets calendar-specific configuration for trade calendar widget
  /// Returns configuration optimized for calendar date selection and display
  static calendar_config.CalendarConfig getCalendarConfig({
    bool compactMode = false,
    String? title,
  }) => calendar_config.CalendarConfig(
    filterConfig: calendar_config.FilterConfig(
      enabledQuickRanges: _tradeQuickRanges,
      enabledTimePeriods: _tradeTimePeriods,
    ),
    displayConfig: calendar_config.DisplayConfig(
      compactMode: compactMode,
      showDescriptions: !compactMode,
      gridColumns: compactMode ? 3 : 2,
      itemHeight: compactMode ? 32.0 : 40.0,
      padding: EdgeInsets.all(compactMode ? 8.0 : 12.0),
    ),
    layoutConfig: calendar_config.LayoutConfig(
      headerTitle: title ?? 'Trade Calendar',
    ),
  );

  /// Quick range options optimized for trading
  static List<QuickRangeType> get _tradeQuickRanges => [
    QuickRangeType.last7Days,
    QuickRangeType.last30Days,
    QuickRangeType.last90Days,
    QuickRangeType.last6Months,
    QuickRangeType.lastYear,
  ];

  /// Time period options optimized for trading
  static List<TimePeriodType> get _tradeTimePeriods => [
    TimePeriodType.thisWeek,
    TimePeriodType.thisMonth,
    TimePeriodType.thisQuarter,
    TimePeriodType.thisYear,
    TimePeriodType.lastWeek,
    TimePeriodType.lastMonth,
    TimePeriodType.lastQuarter,
    TimePeriodType.lastYear,
  ];
}
