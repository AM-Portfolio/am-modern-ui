import 'package:flutter/material.dart';

import 'calendar_types.dart';
import 'components/months_grid.dart';
import 'components/year_calendar_header.dart';
import 'controllers/calendar_data_controller.dart';
import 'models/calendar_color_mode.dart';
import 'services/calendar_color_service.dart';

/// Year-at-a-glance calendar widget showing all 12 months
/// Refactored into modular components for better maintainability
class YearCalendarWidget extends StatefulWidget {
  const YearCalendarWidget({
    required this.year,
    required this.monthsData,
    super.key,
    this.config = const YearCalendarConfig(),
    this.onYearChanged,
    this.controller,
    this.initialColorMode = CalendarColorMode.profitIntensity,
  });

  final int year;
  final Map<int, CalendarMonthData> monthsData; // month (1-12) -> data
  final YearCalendarConfig config;
  final Function(int newYear)? onYearChanged;
  final CalendarDataController? controller;
  final CalendarColorMode initialColorMode;

  @override
  State<YearCalendarWidget> createState() => _YearCalendarWidgetState();
}

class _YearCalendarWidgetState extends State<YearCalendarWidget> {
  late CalendarDataController _controller;
  late CalendarColorMode _colorMode;
  late CalendarColorService _colorService;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? CalendarDataController();
    _colorMode = widget.initialColorMode;
    _colorService = CalendarColorService(colorMode: _colorMode);
  }

  void _handleColorModeChanged(CalendarColorMode newMode) {
    setState(() {
      _colorMode = newMode;
      _colorService = CalendarColorService(colorMode: newMode);
    });
  }

  @override
  void dispose() {
    // Only dispose if we created the controller
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with year navigation and summary stats
        if (widget.config.showHeader)
          YearCalendarHeader(
            year: widget.year,
            monthsData: widget.monthsData,
            onYearChanged: widget.onYearChanged,
            currentColorMode: _colorMode,
            onColorModeChanged: _handleColorModeChanged,
          ),
        if (widget.config.showHeader) const SizedBox(height: 16),

        // Responsive grid of month calendars
        MonthsGrid(
          year: widget.year,
          monthsData: widget.monthsData,
          showWeekdays: widget.config.showWeekdays,
          compactMode: widget.config.compactMode,
          onDayTap: _handleDayTap,
          colorService: _colorService,
        ),
      ],
    ),
  );

  /// Handle day tap - use controller to load dashboard data
  void _handleDayTap(DateTime date, CalendarDayData dayData) {
    // Handle the tap through controller (loads holdings/analytics data)
    _controller.handleDayTap(date, dayData);

    // Also call the config callback if provided
    widget.config.onDayTap?.call(date, dayData);
  }
}
