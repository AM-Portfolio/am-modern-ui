import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:am_design_system/am_design_system.dart';

/// Callback for date range selection with context
typedef DateRangeCallback =
    void Function(
      DateTime? startDate,
      DateTime? endDate,
      String selectionDescription,
    );

/// Trade Calendar Date Selector using Universal Calendar System
/// This widget is now a wrapper around the universal calendar system
/// providing trade-specific optimizations and backward compatibility
class TradeCalendarDateSelector extends StatefulWidget {
  const TradeCalendarDateSelector({
    required this.onDateRangeChanged,
    super.key,
    this.initialStartDate,
    this.initialEndDate,
    this.minDate,
    this.maxDate,
  });

  final DateRangeCallback onDateRangeChanged;
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;
  final DateTime? minDate;
  final DateTime? maxDate;

  @override
  State<TradeCalendarDateSelector> createState() =>
      _TradeCalendarDateSelectorState();
}

class _TradeCalendarDateSelectorState extends State<TradeCalendarDateSelector> {
  late DateSelection _currentSelection;

  @override
  void initState() {
    super.initState();

    // Convert initial dates to DateSelection
    if (widget.initialStartDate != null && widget.initialEndDate != null) {
      _currentSelection = DateSelection(
        startDate: widget.initialStartDate,
        endDate: widget.initialEndDate,
        description: _formatDateRange(
          widget.initialStartDate!,
          widget.initialEndDate!,
        ),
        filterType: DateFilterMode.custom,
      );
    } else {
      _currentSelection = const DateSelection(
        startDate: null,
        endDate: null,
        description: 'All Time',
        filterType: DateFilterMode.quick,
      );
    }
  }

  String _formatDateRange(DateTime start, DateTime end) =>
      '${_formatDate(start)} - ${_formatDate(end)}';

  String _formatDate(DateTime date) => '${date.month}/${date.day}/${date.year}';

  void _handleDateSelectionChanged(DateSelection selection) {
    setState(() {
      _currentSelection = selection;
    });

    // Call the original callback to maintain backward compatibility
    widget.onDateRangeChanged(
      selection.startDate,
      selection.endDate,
      selection.description,
    );
  }

  @override
  Widget build(BuildContext context) => TradeDateFilter(
    onDateSelectionChanged: _handleDateSelectionChanged,
    title: 'Trade Date Filter',
    initialSelection: _currentSelection,
  );
}

/// Enhanced Trade Calendar Date Selector with more options
class EnhancedTradeCalendarDateSelector extends StatelessWidget {
  const EnhancedTradeCalendarDateSelector({
    required this.onDateSelectionChanged,
    super.key,
    this.title,
    this.initialSelection,
    this.showAdvancedOptions = true,
    this.compactMode = false,
  });

  final Function(DateSelection) onDateSelectionChanged;
  final String? title;
  final DateSelection? initialSelection;
  final bool showAdvancedOptions;
  final bool compactMode;

  @override
  Widget build(BuildContext context) {
    if (compactMode) {
      return QuickDateFilter(
        onDateSelectionChanged: onDateSelectionChanged,
        initialSelection: initialSelection,
      );
    }

    return UniversalCalendarWidget(
      onDateSelectionChanged: onDateSelectionChanged,
      title: title ?? 'Trade Date Filter',
      initialSelection: initialSelection,
      context: 'trade',
    );
  }
}

/// Web-optimized Trade Calendar Date Selector
class WebTradeCalendarDateSelector extends StatelessWidget {
  const WebTradeCalendarDateSelector({
    required this.onDateSelectionChanged,
    super.key,
    this.title,
    this.initialSelection,
    this.fullFeatures = true,
  });

  final Function(DateSelection) onDateSelectionChanged;
  final String? title;
  final DateSelection? initialSelection;
  final bool fullFeatures;

  @override
  Widget build(BuildContext context) => WebDateFilter(
    onDateSelectionChanged: onDateSelectionChanged,
    title: title ?? 'Trade Date Filter',
    initialSelection: initialSelection,
    fullFeatures: fullFeatures,
  );
}
