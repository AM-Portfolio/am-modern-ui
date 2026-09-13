import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';

import '../../../internal/data/dtos/journal_entry_dto.dart';

/// Journal Entries header — discipline status counts only (no trading scoreboard).
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

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: MetricCard(
              title: 'Entries',
              value: '${s?.totalTrades ?? 0}',
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: MetricCard(
              title: 'Planned',
              value: '${s?.plannedCount ?? 0}',
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: MetricCard(
              title: 'Open',
              value: '${s?.openCount ?? 0}',
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: MetricCard(
              title: 'Completed',
              value: '${s?.completedCount ?? 0}',
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
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.textSecondary,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: valueColor ?? context.colors.textPrimary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
