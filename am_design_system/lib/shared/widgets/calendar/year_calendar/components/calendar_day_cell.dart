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

    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Restore a slightly more intense background fill so the active dates stand out clearly,
    // using the base color with 0.15 opacity.
    final backgroundColor = hasData ? service.getDayColor(dayData!, opacity: 0.15, isDark: isDark) : Colors.transparent;
    final borderColor = hasData
        ? service.getBorderColor(dayData!, isDark: isDark)
        : Theme.of(context).colorScheme.outline.withOpacity(0.1);
    final textColor = hasData
        ? service.getTextColor(dayData!, isDark: isDark)
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
        hoverColor: hasData ? service.getDayColor(dayData!, opacity: 0.25, isDark: isDark) : Colors.grey.withOpacity(0.05),
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
        richMessage: TextSpan(
          children: [
            TextSpan(
              text: '${dayData!.date.day} ${_getMonthName(month)}\n',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
            ),
            TextSpan(
              text: 'Trades: ',
              style: TextStyle(color: Colors.white.withOpacity(0.7)),
            ),
            TextSpan(
              text: '${dayData!.tradeCount}\n',
              style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
            ),
            TextSpan(
              text: 'Win Rate: ',
              style: TextStyle(color: Colors.white.withOpacity(0.7)),
            ),
            TextSpan(
              text: '${winRate.toStringAsFixed(0)}%\n',
              style: TextStyle(
                fontWeight: FontWeight.w600, 
                color: winRate >= 50 ? Colors.greenAccent : Colors.orangeAccent,
              ),
            ),
            TextSpan(
              text: 'P&L: ',
              style: TextStyle(color: Colors.white.withOpacity(0.7)),
            ),
            TextSpan(
              text: '₹${dayData!.pnl >= 0 ? '+' : ''}${dayData!.pnl.toStringAsFixed(2)}',
              style: TextStyle(
                fontWeight: FontWeight.w600, 
                color: dayData!.pnl >= 0 ? Colors.greenAccent : Colors.redAccent,
              ),
            ),
          ],
        ),
        preferBelow: false,
        verticalOffset: 20,
        waitDuration: const Duration(milliseconds: 300), // Show faster on mobile
        showDuration: const Duration(seconds: 3), // Keep visible longer
        triggerMode: TooltipTriggerMode.longPress, // Explicit long-press for mobile
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A24),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
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
