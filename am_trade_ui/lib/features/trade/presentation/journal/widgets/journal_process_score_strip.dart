import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';

import '../../../internal/data/dtos/journal_entry_dto.dart';
import '../../../internal/domain/entities/journal_entry.dart';

/// Thin process metrics row for the journal hub (review rate, scores).
class JournalProcessScoreStrip extends StatelessWidget {
  const JournalProcessScoreStrip({
    super.key,
    required this.entries,
    this.summary,
    this.adherence,
    this.compact = false,
  });

  final List<JournalEntry> entries;
  final JournalSummaryDto? summary;
  final JournalAdherenceDto? adherence;
  final bool compact;

  static double? fillsReviewedPercent(List<JournalEntry> entries) {
    var linked = 0;
    var reviewed = 0;
    for (final e in entries) {
      final hasTradeLink = (e.tradeId != null && e.tradeId!.isNotEmpty) ||
          e.relatedTradeIds.isNotEmpty;
      if (!hasTradeLink) continue;
      linked++;
      final outcome = e.postTradeReview?.tradeOutcome?.trim();
      if (outcome != null && outcome.isNotEmpty) reviewed++;
    }
    if (linked == 0) return null;
    return (reviewed * 100.0) / linked;
  }

  static double? compositeProcessScore({
    JournalSummaryDto? summary,
    JournalAdherenceDto? adherence,
  }) {
    final scores = <double>[];
    final plan = adherence?.avgPlanAdherenceScore;
    final checklist = adherence?.avgChecklistCompletionPct;
    final exec = adherence?.avgExecutionScore;
    if (plan != null) scores.add(plan);
    if (checklist != null) scores.add(checklist);
    if (exec != null) scores.add(exec.toDouble());
    final win = summary?.winRate;
    if (win != null) {
      scores.add(win <= 1 ? win * 100 : win);
    }
    if (scores.isEmpty) return null;
    return scores.reduce((a, b) => a + b) / scores.length;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;
    final reviewPct = fillsReviewedPercent(entries);
    final process = compositeProcessScore(summary: summary, adherence: adherence);

    final padV = compact ? AppSpacing.xs : AppSpacing.sm;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        padV,
      ),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: compact ? AppSpacing.xs : AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: ModuleColors.trade.withValues(alpha: 0.06),
          borderRadius: AppRadii.card,
          border: Border.all(
            color: ModuleColors.trade.withValues(alpha: 0.22),
          ),
        ),
        child: Row(
          children: [
            _MetricChip(
              icon: Icons.fact_check_outlined,
              label: 'Fills reviewed',
              value: reviewPct == null
                  ? '—'
                  : '${reviewPct.round()}%',
              tooltip: 'Trade-linked entries with an outcome recorded',
            ),
            _divider(colors),
            _MetricChip(
              icon: Icons.speed_outlined,
              label: 'Process',
              value: process == null ? '—' : '${process.round()}',
              tooltip: 'Blend of adherence, checklist, execution, and win rate',
            ),
            if (!compact) ...[
              _divider(colors),
              Expanded(
                child: Text(
                  'Process score rewards consistency, not just P&L.',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _divider(dynamic colors) {
    return Container(
      width: 1,
      height: 28,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      color: colors.border.withValues(alpha: 0.35),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.tooltip,
  });

  final IconData icon;
  final String label;
  final String value;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;

    return Tooltip(
      message: tooltip,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: ModuleColors.trade),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                value,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
