import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';

import '../../../internal/domain/entities/journal_entry.dart';
import 'journal_form_surface.dart';
import 'journal_trade_header.dart';

/// Read-only summary for a completed structured trade journal.
class TradeJournalDetailView extends StatelessWidget {
  const TradeJournalDetailView({
    super.key,
    required this.entry,
    required this.onEdit,
    this.onDelete,
  });

  final JournalEntry entry;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;
    final plan = entry.preTradePlan;
    final exec = entry.tradeExecution;
    final review = entry.postTradeReview;
    final pnl = review?.actualPnl;
    final rMult = review?.actualRMultiple;

    return ColoredBox(
      color: colors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.xl,
              ),
              child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      JournalTradeHeader(entry: entry, compact: true),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Text(
                            'Trade journal',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          AppButton(
                            text: 'Edit journal',
                            icon: Icons.edit_outlined,
                            backgroundColor: ModuleColors.trade,
                            height: 40,
                            onPressed: onEdit,
                          ),
                          if (onDelete != null) ...[
                            const SizedBox(width: AppSpacing.sm),
                            OutlinedButton.icon(
                              onPressed: onDelete,
                              icon: const Icon(Icons.delete_outline, size: 18),
                              label: const Text('Delete'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: context.statusError,
                                side: BorderSide(
                                  color: context.statusError
                                      .withValues(alpha: 0.45),
                                ),
                                minimumSize: const Size(0, 40),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Wrap(
                        spacing: AppSpacing.md,
                        runSpacing: AppSpacing.sm,
                        children: [
                          _MetricChip(
                            label: 'P&L',
                            value: pnl == null
                                ? '—'
                                : pnl.toStringAsFixed(2),
                            valueColor: pnl == null
                                ? null
                                : (pnl >= 0
                                    ? context.statusSuccess
                                    : context.statusError),
                          ),
                          _MetricChip(
                            label: 'R Multiple',
                            value: rMult == null
                                ? '—'
                                : '${rMult.toStringAsFixed(2)} R',
                          ),
                          _MetricChip(
                            label: 'Execution',
                            value: review?.executionScore == null
                                ? '—'
                                : '${review!.executionScore}/10',
                          ),
                          _MetricChip(
                            label: 'Direction',
                            value: (entry.tradeDirection ?? '—').toUpperCase(),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      JournalFormSurface(
                        title: 'Plan',
                        subtitle: 'Pre-trade setup and risk',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _kv(context, 'Strategy', plan?.strategy),
                            _kv(context, 'Setup', plan?.setup ?? entry.setup),
                            _kv(
                              context,
                              'Entry / Stop / Target',
                              _prices(
                                plan?.plannedEntryPrice,
                                plan?.plannedStopLoss,
                                plan?.plannedTarget,
                              ),
                            ),
                            _kv(
                              context,
                              'Quantity',
                              plan?.plannedQuantity?.toString(),
                            ),
                            _kv(
                              context,
                              'Planned R:R',
                              plan?.plannedRRRatio?.toStringAsFixed(2),
                            ),
                            _kv(context, 'Market context', plan?.marketContext),
                            _kv(
                              context,
                              'Setup description',
                              plan?.setupDescription,
                            ),
                            _kv(
                              context,
                              'Entry rationale',
                              plan?.entryRationale,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      JournalFormSurface(
                        title: 'Execution',
                        subtitle: entry.tradeId == null
                            ? 'Manual snapshot'
                            : 'Linked: ${entry.tradeId}',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _kv(
                              context,
                              'Actual entry',
                              exec?.actualEntryPrice?.toStringAsFixed(2),
                            ),
                            _kv(
                              context,
                              'Quantity',
                              exec?.quantity?.toString(),
                            ),
                            _kv(context, 'Broker', exec?.broker),
                            _kv(context, 'Order type', exec?.orderType),
                            _kv(
                              context,
                              'Notes',
                              entry.content ?? exec?.notes,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      JournalFormSurface(
                        title: 'Review',
                        subtitle: 'Outcome and lesson',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _kv(
                              context,
                              'Exit price',
                              review?.actualExitPrice?.toStringAsFixed(2),
                            ),
                            _kv(
                              context,
                              'Followed stop',
                              review?.followedStopLoss,
                            ),
                            _kv(
                              context,
                              'Followed target',
                              review?.followedTarget,
                            ),
                            _kv(
                              context,
                              'Mistake',
                              _humanLabel(review?.mistakeCategory),
                            ),
                            _kv(
                              context,
                              'Emotion',
                              _humanLabel(review?.emotionalState),
                            ),
                            _kv(context, 'What went well', review?.whatWentWell),
                            _kv(
                              context,
                              'What to improve',
                              review?.whatCouldBeImproved,
                            ),
                            _kv(
                              context,
                              'Lesson learned',
                              review?.lessonLearned,
                            ),
                          ],
                        ),
                      ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String? _prices(double? a, double? b, double? c) {
    if (a == null && b == null && c == null) return null;
    String f(double? v) => v?.toStringAsFixed(2) ?? '—';
    return '${f(a)} / ${f(b)} / ${f(c)}';
  }

  static String? _humanLabel(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    return raw
        .split('_')
        .map(
          (w) => w.isEmpty
              ? w
              : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  static Widget _kv(BuildContext context, String label, String? value) {
    final colors = context.colors;
    final text = (value == null || value.trim().isEmpty) ? '—' : value.trim();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colors.cardSurface.withValues(alpha: 0.65),
        borderRadius: AppRadii.card,
        border: Border.all(color: colors.border.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colors.textSecondary,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: valueColor,
                ),
          ),
        ],
      ),
    );
  }
}
