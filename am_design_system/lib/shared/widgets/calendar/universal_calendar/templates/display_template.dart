
import 'package:flutter/material.dart';


import 'package:am_design_system/core/utils/common_logger.dart';
import '../../year_calendar/calendar_types.dart';
import '../../year_calendar/year_calendar_widget.dart';
import '../config.dart';
import '../types.dart';

/// Display template handles the visual presentation with year calendar
class CalendarDisplayTemplate extends StatelessWidget {
  const CalendarDisplayTemplate({
    required this.config,
    required this.filterConfig,
    required this.currentSelection,
    required this.onSelectionChanged,
    super.key,
    this.customContent,
    this.yearCalendarData,
    this.currentYear,
  });

  final DisplayConfig config;
  final FilterConfig filterConfig;
  final DateSelection currentSelection;
  final Function(DateSelection) onSelectionChanged;
  final Widget? customContent;
  final Map<int, CalendarMonthData>? yearCalendarData;
  final int? currentYear;

  @override
  Widget build(BuildContext context) {
    CommonLogger.debug(
      'CalendarDisplayTemplate building - hasCustomContent: ${customContent != null}, '
      'hasYearData: ${yearCalendarData != null}, year: $currentYear, '
      'monthsCount: ${yearCalendarData?.length ?? 0}',
      tag: 'CalendarDisplayTemplate',
    );

    // Priority 1: If year calendar data is provided, show year calendar FIRST
    if (yearCalendarData != null && currentYear != null) {
      CommonLogger.info(
        'Displaying year calendar for $currentYear with ${yearCalendarData!.length} months',
        tag: 'CalendarDisplayTemplate',
      );
      return _buildYearCalendar(context);
    }

    // Priority 2: If custom content provided, show it
    if (customContent != null) {
      CommonLogger.debug('Using custom content (filter template)', tag: 'CalendarDisplayTemplate');
      return customContent!;
    }

    // Priority 3: Show placeholder
    CommonLogger.warning('No calendar data available', tag: 'CalendarDisplayTemplate');
    return _buildPlaceholder(context);
  }

  /// Build year calendar view
  Widget _buildYearCalendar(BuildContext context) {
    CommonLogger.debug('Building year calendar widget', tag: 'CalendarDisplayTemplate');

    return YearCalendarWidget(
      year: currentYear!,
      monthsData: yearCalendarData!,
      config: YearCalendarConfig(
        compactMode: config.compactMode,
        onDayTap: (date, data) {
          CommonLogger.info(
            'Day tapped: ${date.year}-${date.month}-${date.day}, '
            'P&L: ${data.pnl}, trades: ${data.tradeCount}',
            tag: 'CalendarDisplayTemplate',
          );

          // When a day is tapped, update the selection to that specific date
          final selection = DateSelection(
            startDate: date,
            endDate: date,
            description: 'Selected: ${date.year}-${date.month}-${date.day}',
            filterType: DateFilterMode.custom,
            metadata: {'selectedDate': date.toIso8601String(), 'pnl': data.pnl, 'tradeCount': data.tradeCount},
          );
          onSelectionChanged(selection);
        },
      ),
      onYearChanged: (newYear) {
        CommonLogger.info('Year changed to: $newYear', tag: 'CalendarDisplayTemplate');

        // Notify parent about year change through selection callback
        final selection = DateSelection(
          startDate: DateTime(newYear),
          endDate: DateTime(newYear, 12, 31),
          description: 'Year: $newYear',
          filterType: DateFilterMode.custom,
          metadata: {'yearChange': true, 'year': newYear},
        );
        onSelectionChanged(selection);
      },
    );
  }

  /// Build placeholder when no calendar data
  Widget _buildPlaceholder(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_month, size: 64, color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            'No calendar data available',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
          ),
          const SizedBox(height: 8),
          Text(
            'Load trade data to see the calendar',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4)),
          ),
        ],
      ),
    ),
  );
}
