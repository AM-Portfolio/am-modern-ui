import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../internal/domain/entities/journal_entry.dart';

/// Mutable per-trade mini review state used by Log Day.
///
/// One row per linked trade. Values are written into a per-trade
/// [PostTradeReview] (via the DRAFT stub created by `from-trades`) so Insights
/// (mistakes, adherence, lessons) get real, per-trade data.
class TradeMiniReviewRow {
  TradeMiniReviewRow({
    required this.tradeId,
    required this.symbol,
    this.outcome,
    this.mistake,
    String lesson = '',
    String pnl = '',
    this.stubEntry,
    this.onOpenFullReview,
  })  : lessonController = TextEditingController(text: lesson),
        pnlController = TextEditingController(text: pnl);

  final String tradeId;
  String symbol;
  String? outcome;
  String? mistake;
  final TextEditingController lessonController;
  final TextEditingController pnlController;

  /// Per-trade journal stub (DRAFT) once known; used for "Open full review".
  JournalEntry? stubEntry;

  /// Optional deep link into the full trade journal workflow.
  VoidCallback? onOpenFullReview;

  bool get hasOutcome => outcome != null && outcome!.isNotEmpty;

  double? get actualPnl => double.tryParse(pnlController.text.trim());

  void dispose() {
    lessonController.dispose();
    pnlController.dispose();
  }
}

/// Compact outcome / mistake / P&L / lesson capture — one row per linked trade.
class JournalStructuredReviewSection extends StatelessWidget {
  const JournalStructuredReviewSection({
    super.key,
    required this.rows,
    required this.isEditMode,
    required this.onChanged,
  });

  final List<TradeMiniReviewRow> rows;
  final bool isEditMode;

  /// Called after a row's outcome / mistake changes (rows are mutated in place).
  final VoidCallback onChanged;

  static const outcomes = ['WIN', 'LOSS', 'BREAKEVEN', 'SCRATCH'];

  static const mistakes = [
    'NONE',
    'FOMO',
    'REVENGE',
    'EARLY_EXIT',
    'LATE_ENTRY',
    'OVERSIZED',
    'MOVED_STOP',
    'CHASING',
    'OVERTRADING',
    'OTHER',
  ];

  /// Builds a [PostTradeReview] from a mini row (merges with [existing]).
  static PostTradeReview buildReview({
    PostTradeReview? existing,
    required String? tradeOutcome,
    required String? mistakeCategory,
    required String lesson,
    double? actualPnl,
  }) {
    final base = existing ?? const PostTradeReview();
    return base.copyWith(
      tradeOutcome: tradeOutcome ?? base.tradeOutcome,
      mistakeCategory: mistakeCategory ?? base.mistakeCategory,
      lessonLearned: lesson.trim().isEmpty ? base.lessonLearned : lesson.trim(),
      actualPnl: actualPnl ?? base.actualPnl,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'One outcome per linked trade — feeds Insights mistakes & lessons.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.sm),
          _MiniReviewRowTile(
            key: ValueKey('mini-review-${rows[i].tradeId}'),
            row: rows[i],
            isEditMode: isEditMode,
            onChanged: onChanged,
          ),
        ],
      ],
    );
  }
}

class _MiniReviewRowTile extends StatelessWidget {
  const _MiniReviewRowTile({
    super.key,
    required this.row,
    required this.isEditMode,
    required this.onChanged,
  });

  final TradeMiniReviewRow row;
  final bool isEditMode;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;
    final needsOutcome = isEditMode && !row.hasOutcome;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.35),
        borderRadius: AppRadii.card,
        border: Border.all(
          color: needsOutcome
              ? colors.statusWarning.withValues(alpha: 0.6)
              : colors.border.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  row.symbol,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              if (row.onOpenFullReview != null)
                TextButton(
                  onPressed: row.onOpenFullReview,
                  style: TextButton.styleFrom(
                    foregroundColor: ModuleColors.trade,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                  child: const Text('Open full review'),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  key: ValueKey('outcome-${row.tradeId}-${row.outcome}'),
                  initialValue: row.outcome,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Outcome',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: JournalStructuredReviewSection.outcomes
                      .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                      .toList(),
                  onChanged: isEditMode
                      ? (v) {
                          row.outcome = v;
                          onChanged();
                        }
                      : null,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: DropdownButtonFormField<String>(
                  key: ValueKey('mistake-${row.tradeId}-${row.mistake}'),
                  initialValue: row.mistake ?? 'NONE',
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Mistake',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: JournalStructuredReviewSection.mistakes
                      .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                      .toList(),
                  onChanged: isEditMode
                      ? (v) {
                          row.mistake = v;
                          onChanged();
                        }
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 130,
                child: TextFormField(
                  controller: row.pnlController,
                  enabled: isEditMode,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[-\d.]')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'P&L (optional)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: TextFormField(
                  controller: row.lessonController,
                  enabled: isEditMode,
                  maxLines: 2,
                  minLines: 1,
                  decoration: const InputDecoration(
                    labelText: 'Lesson',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
