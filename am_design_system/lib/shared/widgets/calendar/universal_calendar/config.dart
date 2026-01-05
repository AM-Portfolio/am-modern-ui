/// Universal calendar date selector configuration
library;

import 'package:flutter/material.dart';
import 'types.dart';

/// Configuration for calendar date selector components
class CalendarConfig {
  const CalendarConfig({
    required this.filterConfig,
    required this.displayConfig,
    required this.layoutConfig,
  });

  final FilterConfig filterConfig;
  final DisplayConfig displayConfig;
  final LayoutConfig layoutConfig;
}

/// Configuration for filter behavior
class FilterConfig {
  const FilterConfig({
    this.enabledModes = const [
      DateFilterMode.quick,
      DateFilterMode.period,
      DateFilterMode.custom,
    ],
    this.defaultMode = DateFilterMode.quick,
    this.enabledQuickRanges = QuickRangeType.values,
    this.enabledTimePeriods = TimePeriodType.values,
    this.allowCustomRange = true,
    this.minDate,
    this.maxDate,
  });

  final List<DateFilterMode> enabledModes;
  final DateFilterMode defaultMode;
  final List<QuickRangeType> enabledQuickRanges;
  final List<TimePeriodType> enabledTimePeriods;
  final bool allowCustomRange;
  final DateTime? minDate;
  final DateTime? maxDate;

  FilterConfig copyWith({
    List<DateFilterMode>? enabledModes,
    DateFilterMode? defaultMode,
    List<QuickRangeType>? enabledQuickRanges,
    List<TimePeriodType>? enabledTimePeriods,
    bool? allowCustomRange,
    DateTime? minDate,
    DateTime? maxDate,
  }) => FilterConfig(
    enabledModes: enabledModes ?? this.enabledModes,
    defaultMode: defaultMode ?? this.defaultMode,
    enabledQuickRanges: enabledQuickRanges ?? this.enabledQuickRanges,
    enabledTimePeriods: enabledTimePeriods ?? this.enabledTimePeriods,
    allowCustomRange: allowCustomRange ?? this.allowCustomRange,
    minDate: minDate ?? this.minDate,
    maxDate: maxDate ?? this.maxDate,
  );
}

/// Configuration for display appearance
class DisplayConfig {
  const DisplayConfig({
    this.compactMode = false,
    this.showIcons = true,
    this.showDescriptions = true,
    this.buttonStyle = CalendarButtonStyle.elevated,
    this.gridColumns = 2,
    this.itemHeight = 40.0,
    this.spacing = 8.0,
    this.padding = const EdgeInsets.all(12.0),
  });

  final bool compactMode;
  final bool showIcons;
  final bool showDescriptions;
  final CalendarButtonStyle buttonStyle;
  final int gridColumns;
  final double itemHeight;
  final double spacing;
  final EdgeInsets padding;

  DisplayConfig copyWith({
    bool? compactMode,
    bool? showIcons,
    bool? showDescriptions,
    CalendarButtonStyle? buttonStyle,
    int? gridColumns,
    double? itemHeight,
    double? spacing,
    EdgeInsets? padding,
  }) => DisplayConfig(
    compactMode: compactMode ?? this.compactMode,
    showIcons: showIcons ?? this.showIcons,
    showDescriptions: showDescriptions ?? this.showDescriptions,
    buttonStyle: buttonStyle ?? this.buttonStyle,
    gridColumns: gridColumns ?? this.gridColumns,
    itemHeight: itemHeight ?? this.itemHeight,
    spacing: spacing ?? this.spacing,
    padding: padding ?? this.padding,
  );
}

/// Configuration for layout behavior
class LayoutConfig {
  const LayoutConfig({
    this.templateType = CalendarTemplateType.adaptive,
    this.showHeader = true,
    this.headerTitle,
    this.showClearButton = true,
    this.collapsible = false,
    this.initiallyExpanded = true,
    this.cardElevation = 1.0,
    this.borderRadius = 12.0,
  });

  final CalendarTemplateType templateType;
  final bool showHeader;
  final String? headerTitle;
  final bool showClearButton;
  final bool collapsible;
  final bool initiallyExpanded;
  final double cardElevation;
  final double borderRadius;

  LayoutConfig copyWith({
    CalendarTemplateType? templateType,
    bool? showHeader,
    String? headerTitle,
    bool? showClearButton,
    bool? collapsible,
    bool? initiallyExpanded,
    double? cardElevation,
    double? borderRadius,
  }) => LayoutConfig(
    templateType: templateType ?? this.templateType,
    showHeader: showHeader ?? this.showHeader,
    headerTitle: headerTitle ?? this.headerTitle,
    showClearButton: showClearButton ?? this.showClearButton,
    collapsible: collapsible ?? this.collapsible,
    initiallyExpanded: initiallyExpanded ?? this.initiallyExpanded,
    cardElevation: cardElevation ?? this.cardElevation,
    borderRadius: borderRadius ?? this.borderRadius,
  );
}

/// Button style options
enum CalendarButtonStyle { elevated, outlined, filled, text, chip }
