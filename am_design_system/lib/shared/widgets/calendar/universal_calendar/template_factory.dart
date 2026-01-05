import 'package:flutter/material.dart';


import 'package:am_design_system/core/utils/common_logger.dart';
import '../year_calendar/calendar_types.dart';
import 'config.dart';
import 'templates/display_template.dart';
import 'templates/filter_template.dart';
import 'templates/layout_template.dart';
import 'types.dart';

/// Factory for creating calendar template components
/// Handles the creation of filter, display, and layout templates
class UniversalCalendarTemplateFactory {
  /// Create filter template for date selection logic
  static Widget createFilterTemplate({
    required CalendarConfig config,
    required DateSelection currentSelection,
    required Function(DateSelection) onSelectionChanged,
  }) => CalendarFilterTemplate(
    config: config.filterConfig,
    currentSelection: currentSelection,
    onSelectionChanged: onSelectionChanged,
  );

  /// Create display template for visual presentation
  static Widget createDisplayTemplate({
    required CalendarConfig config,
    required DateSelection currentSelection,
    required Function(DateSelection) onSelectionChanged,
    Widget? customContent,
    Map<int, CalendarMonthData>? yearCalendarData,
    int? currentYear,
  }) {
    CommonLogger.debug(
      'Creating display template - hasCustomContent: ${customContent != null}, '
      'hasYearData: ${yearCalendarData != null}, year: $currentYear',
      tag: 'TemplateFactory',
    );

    return CalendarDisplayTemplate(
      config: config.displayConfig,
      filterConfig: config.filterConfig,
      currentSelection: currentSelection,
      onSelectionChanged: onSelectionChanged,
      customContent: customContent,
      yearCalendarData: yearCalendarData,
      currentYear: currentYear,
    );
  }

  /// Create layout template for overall structure
  static Widget createLayoutTemplate({
    required BuildContext context,
    required CalendarConfig config,
    required DateSelection currentSelection,
    required Function(DateSelection) onSelectionChanged,
    Widget? customHeader,
    Widget? customFooter,
    Map<int, CalendarMonthData>? yearCalendarData,
    int? currentYear,
    bool showYearCalendar = false,
  }) {
    CommonLogger.debug(
      'Creating layout template - showYearCalendar: $showYearCalendar, '
      'hasYearData: ${yearCalendarData != null}, year: $currentYear',
      tag: 'TemplateFactory',
    );

    // If showing year calendar, return it directly without layout wrapper
    if (showYearCalendar && yearCalendarData != null && currentYear != null) {
      CommonLogger.info('Returning year calendar view directly (no layout wrapper)', tag: 'TemplateFactory');
      return createDisplayTemplate(
        config: config,
        currentSelection: currentSelection,
        onSelectionChanged: onSelectionChanged,
        yearCalendarData: yearCalendarData,
        currentYear: currentYear,
      );
    }

    // Create display template based on configuration
    final Widget displayTemplate;

    CommonLogger.info('Using filter template view with layout wrapper', tag: 'TemplateFactory');
    // Create filter template for traditional date selection
    final filterTemplate = createFilterTemplate(
      config: config,
      currentSelection: currentSelection,
      onSelectionChanged: onSelectionChanged,
    );

    displayTemplate = createDisplayTemplate(
      config: config,
      currentSelection: currentSelection,
      onSelectionChanged: onSelectionChanged,
      customContent: filterTemplate,
    );

    return CalendarLayoutTemplate(
      config: config.layoutConfig,
      currentSelection: currentSelection,
      onSelectionChanged: onSelectionChanged,
      customHeader: customHeader,
      customFooter: customFooter,
      child: displayTemplate,
    );
  }

  /// Create complete calendar widget with all templates composed
  static Widget createCalendarWidget({
    required BuildContext context,
    required CalendarConfig config,
    required Function(DateSelection) onSelectionChanged,
    DateSelection? initialSelection,
    Widget? customHeader,
    Widget? customFooter,
    Map<int, CalendarMonthData>? yearCalendarData,
    int? currentYear,
    bool showYearCalendar = false,
  }) {
    CommonLogger.debug('Creating calendar widget - showYearCalendar: $showYearCalendar', tag: 'TemplateFactory');

    final currentSelection =
        initialSelection ??
        const DateSelection(startDate: null, endDate: null, description: 'All Time', filterType: DateFilterMode.quick);

    return createLayoutTemplate(
      context: context,
      config: config,
      currentSelection: currentSelection,
      onSelectionChanged: onSelectionChanged,
      customHeader: customHeader,
      customFooter: customFooter,
      yearCalendarData: yearCalendarData,
      currentYear: currentYear,
      showYearCalendar: showYearCalendar,
    );
  }

  /// Helper method to get template type based on screen size and config
  static CalendarTemplateType getAdaptiveTemplateType(BuildContext context, CalendarConfig config) {
    final screenWidth = MediaQuery.of(context).size.width;

    // If explicitly set, use that
    if (config.layoutConfig.templateType != CalendarTemplateType.adaptive) {
      return config.layoutConfig.templateType;
    }

    // Adaptive logic
    if (screenWidth < 600) {
      return config.displayConfig.compactMode ? CalendarTemplateType.minimal : CalendarTemplateType.compact;
    } else if (screenWidth < 900) {
      return CalendarTemplateType.compact;
    } else {
      return CalendarTemplateType.full;
    }
  }
}
