import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../internal/data/dtos/journal_entry_dto.dart';

class JournalMetricsHeader extends StatelessWidget {
  const JournalMetricsHeader({super.key, this.summary});

  final JournalSummaryDto? summary;

  @override
  Widget build(BuildContext context) {
    final s = summary;
    final pnl = s?.totalPnl;
    final winRate = s?.winRate;
    final avgRr = s?.avgRR;
    final pnlFmt = NumberFormat.currency(symbol: '₹ ', decimalDigits: 0);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: MetricCard(
              title: 'Total Trades',
              value: '${s?.totalTrades ?? 0}',
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: MetricCard(
              title: 'Win Rate',
              value: winRate == null
                  ? '—'
                  : '${(winRate * (winRate <= 1 ? 100 : 1)).toStringAsFixed(0)}%',
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: MetricCard(
              title: 'Avg R:R',
              value: avgRr == null ? '—' : avgRr.toStringAsFixed(2),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: MetricCard(
              title: 'Net P&L',
              value: pnl == null ? '—' : pnlFmt.format(pnl),
              isPositive: pnl == null ? null : pnl >= 0,
            ),
          ),
        ],
      ),
    );
  }
}

class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.title,
    required this.value,
    this.isPositive,
  });

  final String title;
  final String value;
  final bool? isPositive;

  @override
  Widget build(BuildContext context) {
    Color? valueColor;
    if (isPositive != null) {
      valueColor = isPositive! ? context.statusSuccess : context.statusError;
    }

    return Card(
      elevation: 0,
      color: context.colors.cardSurface.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.textSecondary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: valueColor,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
