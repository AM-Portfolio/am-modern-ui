import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../internal/data/dtos/journal_entry_dto.dart';

class JournalMetricsHeader extends StatelessWidget {
  const JournalMetricsHeader({
    super.key,
    this.summary,
    this.onOpenAnalysis,
  });

  final JournalSummaryDto? summary;
  final VoidCallback? onOpenAnalysis;

  @override
  Widget build(BuildContext context) {
    final s = summary;
    final pnl = s?.totalPnl;
    final winRate = s?.winRate;
    final avgRr = s?.avgRR;
    final pnlFmt = NumberFormat.currency(symbol: '₹ ', decimalDigits: 0);

    StatType pnlType = StatType.neutral;
    if (pnl != null) {
      pnlType = pnl >= 0 ? StatType.positive : StatType.negative;
    }

    StatType winType = StatType.neutral;
    if (winRate != null) {
      final pct = winRate * (winRate <= 1 ? 100 : 1);
      winType = pct >= 50 ? StatType.positive : StatType.negative;
    }

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: AmStatCard(
              title: 'Total Trades',
              value: '${s?.totalTrades ?? 0}',
              type: StatType.neutral,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: AmStatCard(
              title: 'Win Rate',
              value: winRate == null
                  ? '—'
                  : '${(winRate * (winRate <= 1 ? 100 : 1)).toStringAsFixed(0)}%',
              type: winType,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: AmStatCard(
              title: 'Avg R:R',
              value: avgRr == null ? '—' : avgRr.toStringAsFixed(2),
              type: StatType.accent,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: AmStatCard(
              title: 'Net P&L',
              value: pnl == null ? '—' : pnlFmt.format(pnl),
              type: pnlType,
            ),
          ),
          if (onOpenAnalysis != null) ...[
            const SizedBox(width: AppSpacing.md),
            AppButton(
              text: 'Open Analysis',
              type: AppButtonType.text,
              onPressed: onOpenAnalysis,
              height: 40,
              textColor: ModuleColors.trade,
            ),
          ],
        ],
      ),
    );
  }
}
