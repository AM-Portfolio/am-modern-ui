import 'package:flutter/material.dart';

import '../calendar_types.dart';
import '../services/calendar_color_service.dart';
import 'month_calendar_card.dart';

/// Responsive grid of month calendar cards
class MonthsGrid extends StatelessWidget {
  const MonthsGrid({
    required this.year,
    required this.monthsData,
    super.key,
    this.showWeekdays = true,
    this.compactMode = false,
    this.onDayTap,
    this.colorService,
  });

  final int year;
  final Map<int, CalendarMonthData> monthsData;
  final bool showWeekdays;
  final bool compactMode;
  final Function(DateTime date, CalendarDayData dayData)? onDayTap;
  final CalendarColorService? colorService;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      // Responsive months per row based on screen width
      final screenWidth = MediaQuery.of(context).size.width;
      int monthsPerRow;
      if (screenWidth < 600) {
        monthsPerRow = 1; // Mobile: 1 column
      } else if (screenWidth < 900) {
        monthsPerRow = 2; // Tablet: 2 columns
      } else if (screenWidth < 1200) {
        monthsPerRow = 3; // Small desktop: 3 columns
      } else {
        monthsPerRow = 4; // Large desktop: 4 columns
      }

      final rows = (12 / monthsPerRow).ceil();
      return Column(
        children: List.generate(rows, (rowIndex) {
          final startMonth = rowIndex * monthsPerRow + 1;

          return Padding(
            padding: EdgeInsets.only(bottom: rowIndex < rows - 1 ? 12 : 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(monthsPerRow, (colIndex) {
                final month = startMonth + colIndex;
                if (month > 12) return const Expanded(child: SizedBox());

                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: colIndex < monthsPerRow - 1 ? 10 : 0),
                    child: MonthCalendarCard(
                      year: year,
                      month: month,
                      monthData: monthsData[month],
                      showWeekdays: showWeekdays,
                      compactMode: compactMode,
                      onDayTap: onDayTap,
                      colorService: colorService,
                    ),
                  ),
                );
              }),
            ),
          );
        }),
      );
    },
  );
}
