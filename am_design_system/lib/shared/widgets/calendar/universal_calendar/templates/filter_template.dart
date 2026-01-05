import 'package:flutter/material.dart';

import 'package:am_design_system/core/utils/common_logger.dart';
import '../config.dart';
import '../types.dart';

/// Filter template handles date selection logic and state management
class CalendarFilterTemplate extends StatefulWidget {
  const CalendarFilterTemplate({
    required this.config,
    required this.currentSelection,
    required this.onSelectionChanged,
    super.key,
  });

  final FilterConfig config;
  final DateSelection currentSelection;
  final Function(DateSelection) onSelectionChanged;

  @override
  State<CalendarFilterTemplate> createState() => _CalendarFilterTemplateState();
}

class _CalendarFilterTemplateState extends State<CalendarFilterTemplate> {
  /// Select a quick range filter
  void _selectQuickRange(QuickRangeType rangeType) {
    CommonLogger.info('Quick range selected: ${rangeType.label}', tag: 'CalendarFilterTemplate');
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: rangeType.days));

    final selection = DateSelection(
      startDate: startDate,
      endDate: endDate,
      description: rangeType.label,
      filterType: DateFilterMode.quick,
      metadata: {'rangeType': rangeType.name},
    );

    widget.onSelectionChanged(selection);
  }


  /// Select a time period filter
  void _selectTimePeriod(TimePeriodType periodType) {
    CommonLogger.info('Time period selected: ${periodType.label}', tag: 'CalendarFilterTemplate');
    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate;

    switch (periodType.code) {
      case 'current_week':
        final weekday = now.weekday;
        startDate = now.subtract(Duration(days: weekday - 1));
        endDate = startDate.add(const Duration(days: 6));
        break;
      case 'current_month':
        startDate = DateTime(now.year, now.month);
        endDate = DateTime(now.year, now.month + 1, 0);
        break;
      case 'current_quarter':
        final quarter = ((now.month - 1) ~/ 3) + 1;
        final quarterStart = (quarter - 1) * 3 + 1;
        startDate = DateTime(now.year, quarterStart);
        endDate = DateTime(now.year, quarterStart + 3, 0);
        break;
      case 'current_year':
        startDate = DateTime(now.year);
        endDate = DateTime(now.year, 12, 31);
        break;
      case 'previous_week':
        final weekday = now.weekday;
        final thisWeekStart = now.subtract(Duration(days: weekday - 1));
        startDate = thisWeekStart.subtract(const Duration(days: 7));
        endDate = thisWeekStart.subtract(const Duration(days: 1));
        break;
      case 'previous_month':
        if (now.month == 1) {
          startDate = DateTime(now.year - 1, 12);
          endDate = DateTime(now.year - 1, 12, 31);
        } else {
          startDate = DateTime(now.year, now.month - 1);
          endDate = DateTime(now.year, now.month, 0);
        }
        break;
      case 'previous_quarter':
        final currentQuarter = ((now.month - 1) ~/ 3) + 1;
        final prevQuarter = currentQuarter == 1 ? 4 : currentQuarter - 1;
        final year = currentQuarter == 1 ? now.year - 1 : now.year;
        final quarterStart = (prevQuarter - 1) * 3 + 1;
        startDate = DateTime(year, quarterStart);
        endDate = DateTime(year, quarterStart + 3, 0);
        break;
      case 'previous_year':
        startDate = DateTime(now.year - 1);
        endDate = DateTime(now.year - 1, 12, 31);
        break;
      default:
        return;
    }

    final selection = DateSelection(
      startDate: startDate,
      endDate: endDate,
      description: periodType.label,
      filterType: DateFilterMode.period,
      metadata: {'periodType': periodType.name},
    );

    widget.onSelectionChanged(selection);
  }



  /// Select custom date range
  Future<void> _selectCustomRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: widget.config.minDate ?? DateTime(2020),
      lastDate: widget.config.maxDate ?? DateTime.now(),
      initialDateRange: widget.currentSelection.hasDateRange
          ? DateTimeRange(
              start: widget.currentSelection.startDate!,
              end: widget.currentSelection.endDate!,
            )
          : null,
    );

    if (picked != null) {
      final selection = DateSelection(
        startDate: picked.start,
        endDate: picked.end,
        description: 'Custom Range',
        filterType: DateFilterMode.custom,
        metadata: {'pickedRange': true},
      );

      widget.onSelectionChanged(selection);
    }
  }

  /// Clear current selection
  void _clearSelection() {
    const selection = DateSelection(
      startDate: null,
      endDate: null,
      description: 'All Time',
      filterType: DateFilterMode.quick,
    );

    widget.onSelectionChanged(selection);
  }

  /// Check if quick range is selected
  bool _isQuickRangeSelected(QuickRangeType rangeType) {
    if (!widget.currentSelection.hasDateRange) return false;

    final now = DateTime.now();
    final expectedEnd = DateTime(now.year, now.month, now.day);
    final expectedStart = expectedEnd.subtract(Duration(days: rangeType.days));

    return widget.currentSelection.startDate!.isAtSameMomentAs(
          DateTime(expectedStart.year, expectedStart.month, expectedStart.day),
        ) &&
        widget.currentSelection.endDate!.isAtSameMomentAs(expectedEnd);
  }

  /// Check if time period is selected
  bool _isTimePeriodSelected(TimePeriodType periodType) {
    if (!widget.currentSelection.hasDateRange) return false;
    return widget.currentSelection.metadata?['periodType'] == periodType.name;
  }

  /// Get available quick ranges based on config
  List<QuickRangeType> get _availableQuickRanges =>
      widget.config.enabledQuickRanges;

  /// Get available time periods based on config
  List<TimePeriodType> get _availableTimePeriods =>
      widget.config.enabledTimePeriods;

  @override
  Widget build(BuildContext context) {
    CommonLogger.debug('Building CalendarFilterTemplate UI', tag: 'CalendarFilterTemplate');
    // Implement a simple scrollable row of chips for quick ranges
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            ..._availableQuickRanges.map((range) => Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: FilterChip(
                label: Text(range.label),
                selected: _isQuickRangeSelected(range),
                onSelected: (_) => _selectQuickRange(range),
              ),
            )),
            ..._availableTimePeriods.map((period) => Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: FilterChip(
                label: Text(period.label),
                selected: _isTimePeriodSelected(period),
                onSelected: (_) => _selectTimePeriod(period),
              ),
            )),
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ActionChip(
                avatar: const Icon(Icons.calendar_month, size: 16),
                label: const Text('Custom'),
                onPressed: () => _selectCustomRange(context),
              ),
            ),
          ],
        ),
      ),
    );
  }


  // Expose methods for display template to use
  void selectQuickRange(QuickRangeType rangeType) =>
      _selectQuickRange(rangeType);
  void selectTimePeriod(TimePeriodType periodType) =>
      _selectTimePeriod(periodType);
  Future<void> selectCustomRange(BuildContext context) =>
      _selectCustomRange(context);
  void clearSelection() => _clearSelection();
  bool isQuickRangeSelected(QuickRangeType rangeType) =>
      _isQuickRangeSelected(rangeType);
  bool isTimePeriodSelected(TimePeriodType periodType) =>
      _isTimePeriodSelected(periodType);
  List<QuickRangeType> get availableQuickRanges => _availableQuickRanges;
  List<TimePeriodType> get availableTimePeriods => _availableTimePeriods;
}
