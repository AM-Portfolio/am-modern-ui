import 'package:flutter/material.dart';

import '../calendar_types.dart';
import '../models/calendar_color_mode.dart';
import 'color_mode_selector.dart';
import 'year_summary_stats.dart';

/// Header component for year calendar with navigation and summary stats
class YearCalendarHeader extends StatelessWidget {
  const YearCalendarHeader({
    required this.year,
    required this.monthsData,
    super.key,
    this.onYearChanged,
    this.currentColorMode,
    this.onColorModeChanged,
  });

  final int year;
  final Map<int, CalendarMonthData> monthsData;
  final Function(int newYear)? onYearChanged;
  final CalendarColorMode? currentColorMode;
  final ValueChanged<CalendarColorMode>? onColorModeChanged;

  @override
  Widget build(BuildContext context) {
    final yearStats = _calculateYearStats();
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    if (isMobile) {
      return _buildMobileHeader(context, yearStats);
    }

    return _buildDesktopHeader(context, yearStats);
  }

  /// Build mobile header layout
  Widget _buildMobileHeader(BuildContext context, Map<String, dynamic> yearStats) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Year navigation
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildYearNavigation(context),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (onColorModeChanged != null && currentColorMode != null)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ColorModeSelector(
                    currentMode: currentColorMode!,
                    onModeChanged: onColorModeChanged!,
                    compact: true,
                  ),
                ),
              _buildCompactLegend(context),
            ],
          ),
        ],
      ),
      const SizedBox(height: 12),
      // Year summary stats - scrollable
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildSummaryCard(context, 'Trades', '${yearStats['totalTrades']}', Icons.swap_horiz, Colors.blue),
            const SizedBox(width: 8),
            _buildSummaryCard(
              context,
              'Win Rate',
              '${yearStats['winRate'].toStringAsFixed(1)}%',
              Icons.trending_up,
              yearStats['winRate'] >= 50 ? Colors.green : Colors.orange,
            ),
            const SizedBox(width: 8),
            _buildSummaryCard(
              context,
              'P&L',
              '\$${yearStats['totalPnL'] >= 0 ? '+' : ''}${yearStats['totalPnL'].toStringAsFixed(0)}',
              yearStats['totalPnL'] >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
              yearStats['totalPnL'] >= 0 ? Colors.green : Colors.red,
            ),
          ],
        ),
      ),
    ],
  );

  /// Build desktop/tablet header layout
  Widget _buildDesktopHeader(BuildContext context, Map<String, dynamic> yearStats) => LayoutBuilder(
    builder: (context, constraints) {
      final isNarrow = constraints.maxWidth < 900;

      if (isNarrow) {
        // Wrap layout for narrow screens
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [_buildYearNavigation(context), _buildLegend(context)],
            ),
            const SizedBox(height: 12),
            YearSummaryStats(yearStats: yearStats, showLegend: false),
          ],
        );
      }

      // Full width layout
      return Row(
        children: [
          // Year navigation on left
          _buildYearNavigation(context),
          const Spacer(),
          // Year summary stats centered in the middle
          YearSummaryStats(yearStats: yearStats, showLegend: false),
          const Spacer(),
          // Color mode selector (compact)
          if (onColorModeChanged != null && currentColorMode != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: ColorModeSelector(
                currentMode: currentColorMode!,
                onModeChanged: onColorModeChanged!,
                compact: true,
              ),
            ),
          // Legend on the complete right
          _buildLegend(context),
        ],
      );
    },
  );

  /// Build full legend for desktop
  Widget _buildLegend(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.3)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildLegendItem(context, 'Win', Colors.green),
        const SizedBox(width: 8),
        _buildLegendItem(context, 'Loss', Colors.red),
        const SizedBox(width: 8),
        _buildLegendItem(context, 'Breakeven', Colors.grey),
      ],
    ),
  );

  Widget _buildLegendItem(BuildContext context, String label, Color color) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          border: Border.all(color: color, width: 1.5),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: 4),
      Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11, fontWeight: FontWeight.w500)),
    ],
  );

  /// Build year navigation controls
  Widget _buildYearNavigation(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      IconButton(
        icon: const Icon(Icons.chevron_left),
        onPressed: onYearChanged != null ? () => onYearChanged!(year - 1) : null,
        tooltip: 'Previous Year',
        iconSize: 20,
      ),
      const SizedBox(width: 8),
      Text('$year', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
      const SizedBox(width: 8),
      IconButton(
        icon: const Icon(Icons.chevron_right),
        onPressed: onYearChanged != null ? () => onYearChanged!(year + 1) : null,
        tooltip: 'Next Year',
        iconSize: 20,
      ),
    ],
  );

  /// Build compact legend for mobile
  Widget _buildCompactLegend(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      _buildLegendDot(Colors.green),
      const SizedBox(width: 4),
      _buildLegendDot(Colors.red),
      const SizedBox(width: 4),
      _buildLegendDot(Colors.grey),
    ],
  );

  Widget _buildLegendDot(Color color) => Container(
    width: 8,
    height: 8,
    decoration: BoxDecoration(
      color: color.withOpacity(0.3),
      border: Border.all(color: color),
      shape: BoxShape.circle,
    ),
  );

  /// Build summary card
  Widget _buildSummaryCard(BuildContext context, String label, String value, IconData icon, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10, color: color.withOpacity(0.8)),
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ],
    ),
  );

  /// Calculate year-wide statistics
  Map<String, dynamic> _calculateYearStats() {
    var totalTrades = 0;
    var winningTrades = 0;
    var totalPnL = 0.0;

    for (final monthData in monthsData.values) {
      for (final dayData in monthData.days.values) {
        totalTrades += dayData.tradeCount;
        if (dayData.status == TradeDayStatus.win) {
          winningTrades += dayData.tradeCount;
        }
        totalPnL += dayData.pnl;
      }
    }

    final winRate = totalTrades > 0 ? (winningTrades / totalTrades) * 100 : 0.0;

    return {'totalTrades': totalTrades, 'winRate': winRate, 'totalPnL': totalPnL};
  }
}
