import 'package:flutter/material.dart';

import 'calendar_legend.dart';

/// Year summary statistics component
class YearSummaryStats extends StatelessWidget {
  const YearSummaryStats({required this.yearStats, super.key, this.showLegend = true});

  final Map<String, dynamic> yearStats;
  final bool showLegend;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 12,
    runSpacing: 8,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      _buildSummaryCard(context, 'Total Trades', '${yearStats['totalTrades']}', Icons.swap_horiz, Colors.blue),
      _buildSummaryCard(
        context,
        'Win Rate',
        '${yearStats['winRate'].toStringAsFixed(1)}%',
        Icons.trending_up,
        yearStats['winRate'] >= 50 ? Colors.green : Colors.orange,
      ),
      _buildSummaryCard(
        context,
        'Total P&L',
        '\$${yearStats['totalPnL'] >= 0 ? '+' : ''}${yearStats['totalPnL'].toStringAsFixed(0)}',
        yearStats['totalPnL'] >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
        yearStats['totalPnL'] >= 0 ? Colors.green : Colors.red,
      ),
      // Legend (optional)
      if (showLegend) const CalendarLegend(),
    ],
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
}
