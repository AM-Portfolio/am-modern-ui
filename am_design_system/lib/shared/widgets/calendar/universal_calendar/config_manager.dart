import 'package:flutter/material.dart';
import 'config.dart';
import 'types.dart';

/// Universal calendar configuration manager
/// Provides pre-configured setups for different use cases
class UniversalCalendarConfigManager {
  /// Basic configuration for simple date filtering
  static CalendarConfig getBasicConfig({
    String? title,
    bool compactMode = false,
  }) => CalendarConfig(
    filterConfig: const FilterConfig(
      enabledModes: [DateFilterMode.quick, DateFilterMode.period],
    ),
    displayConfig: DisplayConfig(
      compactMode: compactMode,
      gridColumns: compactMode ? 1 : 2,
      itemHeight: compactMode ? 32.0 : 40.0,
    ),
    layoutConfig: LayoutConfig(headerTitle: title, showHeader: title != null),
  );

  /// Compact configuration for dashboard widgets
  static CalendarConfig getCompactConfig({String? title}) => CalendarConfig(
    filterConfig: const FilterConfig(
      enabledModes: [DateFilterMode.quick],
      enabledQuickRanges: [
        QuickRangeType.last7Days,
        QuickRangeType.last30Days,
        QuickRangeType.last90Days,
        QuickRangeType.lastYear,
      ],
    ),
    displayConfig: const DisplayConfig(
      compactMode: true,
      gridColumns: 1,
      itemHeight: 32.0,
      buttonStyle: CalendarButtonStyle.chip,
      padding: EdgeInsets.all(8.0),
    ),
    layoutConfig: LayoutConfig(
      templateType: CalendarTemplateType.compact,
      headerTitle: title,
      showHeader: false,
      cardElevation: 0.0,
    ),
  );

  /// Full configuration with all features
  static CalendarConfig getFullConfig({
    String? title,
    DateTime? minDate,
    DateTime? maxDate,
  }) => CalendarConfig(
    filterConfig: FilterConfig(
      enabledModes: DateFilterMode.values,
      minDate: minDate,
      maxDate: maxDate,
    ),
    displayConfig: const DisplayConfig(
      buttonStyle: CalendarButtonStyle.outlined,
    ),
    layoutConfig: LayoutConfig(
      templateType: CalendarTemplateType.full,
      headerTitle: title ?? 'Date Filter',
    ),
  );

  /// Minimal configuration for embedded use
  static CalendarConfig getMinimalConfig() => const CalendarConfig(
    filterConfig: FilterConfig(
      enabledModes: [DateFilterMode.quick],
      enabledQuickRanges: [
        QuickRangeType.last7Days,
        QuickRangeType.last30Days,
        QuickRangeType.last90Days,
      ],
    ),
    displayConfig: DisplayConfig(
      compactMode: true,
      showIcons: false,
      showDescriptions: false,
      gridColumns: 3,
      itemHeight: 32.0,
      buttonStyle: CalendarButtonStyle.text,
      padding: EdgeInsets.all(4.0),
    ),
    layoutConfig: LayoutConfig(
      templateType: CalendarTemplateType.minimal,
      showHeader: false,
      showClearButton: false,
      cardElevation: 0.0,
    ),
  );

  /// Trade-specific configuration optimized for trading analytics
  static CalendarConfig getTradeConfig({String? title}) => CalendarConfig(
    filterConfig: const FilterConfig(
      enabledTimePeriods: [
        TimePeriodType.thisWeek,
        TimePeriodType.thisMonth,
        TimePeriodType.thisQuarter,
        TimePeriodType.thisYear,
        TimePeriodType.lastMonth,
        TimePeriodType.lastQuarter,
        TimePeriodType.lastYear,
      ],
    ),
    displayConfig: const DisplayConfig(
      itemHeight: 36.0,
      buttonStyle: CalendarButtonStyle.outlined,
    ),
    layoutConfig: LayoutConfig(headerTitle: title ?? 'Trade Date Filter'),
  );

  /// Web-optimized configuration
  static CalendarConfig getWebConfig({
    String? title,
    bool fullFeatures = true,
  }) => CalendarConfig(
    filterConfig: FilterConfig(
      enabledModes: fullFeatures
          ? [DateFilterMode.quick, DateFilterMode.period, DateFilterMode.custom]
          : [DateFilterMode.quick, DateFilterMode.period],
    ),
    displayConfig: const DisplayConfig(
      gridColumns: 3, // More columns for web
      itemHeight: 36.0,
      buttonStyle: CalendarButtonStyle.outlined,
      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
    ),
    layoutConfig: LayoutConfig(
      headerTitle: title,
      showHeader: title != null,
      borderRadius: 8.0,
    ),
  );

  /// Get default title based on context
  static String getDefaultTitle(String context) {
    switch (context.toLowerCase()) {
      case 'trade':
      case 'trading':
        return 'Trade Date Filter';
      case 'portfolio':
        return 'Portfolio Date Range';
      case 'analytics':
        return 'Analytics Period';
      case 'report':
        return 'Report Date Range';
      default:
        return 'Date Filter';
    }
  }
}
