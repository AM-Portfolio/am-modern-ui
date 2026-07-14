import 'package:flutter/material.dart';

import '../calendar_types.dart';

/// Month header with name and statistics badges
class MonthHeader extends StatelessWidget {
  const MonthHeader({required this.month, required this.monthData, required this.stats, super.key});

  final int month;
  final CalendarMonthData? monthData;
  final Map<String, dynamic> stats;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final hasStats = stats['totalTrades'] > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // Centered Month Name
            Center(
              child: Text(
                monthData?.monthName ?? _getMonthName(month),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Right-aligned stats badge
            Align(
              alignment: Alignment.centerRight,
              child: Visibility(
                visible: hasStats,
                maintainSize: true,
                maintainAnimation: true,
                maintainState: true,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: (stats['totalPnL'] >= 0 ? Colors.green : Colors.red).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: (stats['totalPnL'] >= 0 ? Colors.green : Colors.red).withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        stats['totalPnL'] >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                        size: 12,
                        color: stats['totalPnL'] >= 0 ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '₹${stats['totalPnL'] >= 0 ? '+' : ''}${stats['totalPnL'].toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: stats['totalPnL'] >= 0 
                              ? (isDark ? Colors.greenAccent : Colors.green.shade800) 
                              : (isDark ? Colors.redAccent : Colors.red.shade800),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Visibility(
          visible: hasStats,
          maintainSize: true,
          maintainAnimation: true,
          maintainState: true,
          child: Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              _buildIconStat(context, Icons.calendar_today, '${stats['tradeDays']} days', isDark ? Colors.purpleAccent : Colors.purple.shade700),
              _buildIconStat(context, Icons.swap_horiz, '${stats['totalTrades']} trades', isDark ? Colors.lightBlueAccent : Colors.blue.shade700),
              _buildIconStat(
                context,
                Icons.percent,
                '${stats['winRate'].toStringAsFixed(1)}%',
                stats['winRate'] >= 50 ? (isDark ? Colors.greenAccent : Colors.green.shade700) : (isDark ? Colors.orangeAccent : Colors.orange.shade800),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build compact stat indicator for mobile
  Widget _buildCompactStat(BuildContext context, IconData icon, String label, Color color) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 10, color: color.withOpacity(0.7)),
      const SizedBox(width: 2),
      Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.8),
          fontWeight: FontWeight.w500,
        ),
      ),
    ],
  );

  /// Build icon-based stat (no background badge)
  Widget _buildIconStat(BuildContext context, IconData icon, String label, Color color) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 12, color: color),
      const SizedBox(width: 4),
      Text(
        label,
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
      ),
    ],
  );

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
