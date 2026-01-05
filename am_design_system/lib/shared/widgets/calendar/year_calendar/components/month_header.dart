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
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 900;

    // Mobile: Ultra compact design with inline stats
    if (isMobile && stats['totalTrades'] > 0) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month name with primary stat inline
          Row(
            children: [
              Text(
                monthData?.monthName ?? _getMonthName(month),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(width: 8),
              // Compact P&L indicator
              Container(
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
                      size: 10,
                      color: stats['totalPnL'] >= 0 ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '\$${stats['totalPnL'] >= 0 ? '+' : ''}${stats['totalPnL'].toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: stats['totalPnL'] >= 0 ? Colors.green.shade700 : Colors.red.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Compact stats row
          Row(
            children: [
              _buildCompactStat(context, Icons.calendar_today, '${stats['tradeDays']}d', Colors.purple),
              const SizedBox(width: 6),
              _buildCompactStat(context, Icons.swap_horiz, '${stats['totalTrades']}', Colors.blue),
              const SizedBox(width: 6),
              _buildCompactStat(
                context,
                Icons.percent,
                '${stats['winRate'].toStringAsFixed(0)}%',
                stats['winRate'] >= 50 ? Colors.green : Colors.orange,
              ),
            ],
          ),
        ],
      );
    }

    // Tablet: Balanced compact design
    if (isTablet && stats['totalTrades'] > 0) {
      return Row(
        children: [
          Text(
            monthData?.monthName ?? _getMonthName(month),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const Spacer(),
          // All stats in single row
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildIconStat(context, Icons.calendar_today, '${stats['tradeDays']}d', Colors.purple),
              const SizedBox(width: 8),
              _buildIconStat(context, Icons.swap_horiz, '${stats['totalTrades']}', Colors.blue),
              const SizedBox(width: 8),
              _buildIconStat(
                context,
                Icons.percent,
                '${stats['winRate'].toStringAsFixed(1)}%',
                stats['winRate'] >= 50 ? Colors.green : Colors.orange,
              ),
              const SizedBox(width: 8),
              _buildIconStat(
                context,
                stats['totalPnL'] >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                '\$${stats['totalPnL'] >= 0 ? '+' : ''}${stats['totalPnL'].toStringAsFixed(0)}',
                stats['totalPnL'] >= 0 ? Colors.green : Colors.red,
              ),
            ],
          ),
        ],
      );
    }

    // Desktop: Icon-based stats design - all in one row
    return Row(
      children: [
        // Month name
        Text(
          monthData?.monthName ?? _getMonthName(month),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 16),
          overflow: TextOverflow.ellipsis,
        ),
        const Spacer(),
        if (stats['totalTrades'] > 0)
          // All stats in single horizontal row
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildIconStat(context, Icons.calendar_today, '${stats['tradeDays']} days', Colors.purple),
              const SizedBox(width: 10),
              _buildIconStat(context, Icons.swap_horiz, '${stats['totalTrades']} trades', Colors.blue),
              const SizedBox(width: 10),
              _buildIconStat(
                context,
                Icons.percent,
                '${stats['winRate'].toStringAsFixed(1)}%',
                stats['winRate'] >= 50 ? Colors.green : Colors.orange,
              ),
              const SizedBox(width: 10),
              _buildIconStat(
                context,
                stats['totalPnL'] >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                '\$${stats['totalPnL'] >= 0 ? '+' : ''}${stats['totalPnL'].toStringAsFixed(0)}',
                stats['totalPnL'] >= 0 ? Colors.green : Colors.red,
              ),
            ],
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
        style: TextStyle(fontSize: 11, color: color.withOpacity(0.9), fontWeight: FontWeight.w600),
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
