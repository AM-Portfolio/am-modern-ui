import 'package:flutter/material.dart';

import '../calendar_types.dart';
import '../services/calendar_color_service.dart';

/// Individual calendar day cell component
class CalendarDayCell extends StatelessWidget {
  const CalendarDayCell({
    required this.dayNumber,
    required this.dayData,
    required this.month,
    super.key,
    this.compactMode = false,
    this.onTap,
    this.colorService,
  });

  final int dayNumber;
  final CalendarDayData? dayData;
  final int month;
  final bool compactMode;
  final Function(DateTime date, CalendarDayData dayData)? onTap;
  final CalendarColorService? colorService;

  @override
  Widget build(BuildContext context) {
    final hasData = dayData?.hasTrades ?? false;
    final service = colorService ?? CalendarColorService();

    final backgroundColor = hasData ? service.getDayColor(dayData!, opacity: 0.18) : Colors.transparent;
    final borderColor = hasData
        ? service.getBorderColor(dayData!)
        : Theme.of(context).colorScheme.outline.withOpacity(0.1);
    final textColor = hasData
        ? service.getTextColor(dayData!)
        : Theme.of(context).colorScheme.onSurface.withOpacity(0.6);

    final dayCell = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: hasData && onTap != null ? () => onTap!(dayData!.date, dayData!) : null,
        onLongPress: hasData
            ? () {
                // On mobile, show tooltip on long press by triggering it programmatically
                // This is handled by wrapping with Tooltip widget below
              }
            : null,
        borderRadius: BorderRadius.circular(4),
        hoverColor: hasData ? service.getDayColor(dayData!, opacity: 0.25) : Colors.grey.withOpacity(0.05),
        child: Container(
          height: compactMode ? 20 : 24,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: borderColor, width: hasData ? 1.5 : 0.5),
          ),
          child: Center(
            child: Text(
              '$dayNumber',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: compactMode ? 9 : 10,
                fontWeight: hasData ? FontWeight.bold : FontWeight.w500,
                color: textColor,
              ),
            ),
          ),
        ),
      ),
    );

    // Add tooltip with trade details on hover (web) and long-press (mobile)
    if (hasData && dayData != null) {
      // Determine win rate based on status
      final winRate = dayData!.status == TradeDayStatus.win
          ? 100.0
          : dayData!.status == TradeDayStatus.loss
          ? 0.0
          : 50.0; // breakeven

      return Tooltip(
        message:
            '${dayData!.date.day} ${_getMonthName(month)}\n'
            'Trades: ${dayData!.tradeCount}\n'
            'Win Rate: ${winRate.toStringAsFixed(0)}%\n'
            'P&L: ₹${dayData!.pnl >= 0 ? '+' : ''}${dayData!.pnl.toStringAsFixed(2)}',
        preferBelow: false,
        verticalOffset: 20,
        waitDuration: const Duration(milliseconds: 300), // Show faster on mobile
        showDuration: const Duration(seconds: 3), // Keep visible longer
        triggerMode: TooltipTriggerMode.longPress, // Explicit long-press for mobile
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 2))],
        ),
        textStyle: const TextStyle(fontSize: 11, color: Colors.white, height: 1.4),
        child: dayCell,
      );
    }

    return dayCell;
  }

  String _getMonthName(int month) {
    const monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return monthNames[month - 1];
  }
}
