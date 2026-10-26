import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';

import '../../../internal/domain/entities/journal_entry.dart';
import '../utils/journal_calc_helper.dart';
import 'journal_form_surface.dart';
import 'journal_themed_dropdown.dart';
import 'journal_workflow_field_theme.dart';

class PostTradeReviewStep extends StatefulWidget {
  const PostTradeReviewStep({
    super.key,
    required this.entry,
    required this.onUpdate,
  });

  final JournalEntry entry;
  final ValueChanged<JournalEntry> onUpdate;

  @override
  State<PostTradeReviewStep> createState() => _PostTradeReviewStepState();
}

class _PostTradeReviewStepState extends State<PostTradeReviewStep> {
  static const _mistakes = [
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

  static const _emotions = [
    'CALM',
    'ANXIOUS',
    'GREEDY',
    'FEARFUL',
    'EUPHORIC',
    'FRUSTRATED',
    'NEUTRAL',
  ];

  late final TextEditingController _exit;
  late final TextEditingController _wentWell;
  late final TextEditingController _improve;
  late final TextEditingController _lesson;

  @override
  void initState() {
    super.initState();
    final review = widget.entry.postTradeReview ?? const PostTradeReview();
    _exit = TextEditingController(
      text: review.actualExitPrice?.toString() ?? '',
    );
    _wentWell = TextEditingController(text: review.whatWentWell ?? '');
    _improve = TextEditingController(text: review.whatCouldBeImproved ?? '');
    _lesson = TextEditingController(text: review.lessonLearned ?? '');
  }

  @override
  void didUpdateWidget(covariant PostTradeReviewStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entry.id != widget.entry.id ||
        oldWidget.entry.updatedAt != widget.entry.updatedAt) {
      final review = widget.entry.postTradeReview ?? const PostTradeReview();
      _exit.text = review.actualExitPrice?.toString() ?? '';
      _wentWell.text = review.whatWentWell ?? '';
      _improve.text = review.whatCouldBeImproved ?? '';
      _lesson.text = review.lessonLearned ?? '';
    }
  }

  @override
  void dispose() {
    _exit.dispose();
    _wentWell.dispose();
    _improve.dispose();
    _lesson.dispose();
    super.dispose();
  }

  void _updateReview(PostTradeReview review) {
    final plan = widget.entry.preTradePlan;
    final exec = widget.entry.tradeExecution;
    final risk = JournalCalcHelper.plannedRiskAmount(
      entry: plan?.plannedEntryPrice,
      stop: plan?.plannedStopLoss,
      quantity: plan?.plannedQuantity ?? exec?.quantity,
    );
    final pnl = JournalCalcHelper.actualPnl(
      entryPrice: exec?.actualEntryPrice ?? plan?.plannedEntryPrice,
      exitPrice: review.actualExitPrice,
      quantity: exec?.quantity ?? plan?.plannedQuantity,
      tradeDirection: widget.entry.tradeDirection,
    );
    final r = JournalCalcHelper.actualRMultiple(
      pnl: pnl,
      plannedRisk: risk ?? plan?.plannedRiskAmount,
    );

    widget.onUpdate(
      widget.entry.copyWith(
        postTradeReview: review.copyWith(
          actualPnl: pnl ?? review.actualPnl,
          actualRMultiple: r ?? review.actualRMultiple,
        ),
      ),
    );
  }

  Widget _dropdown<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return JournalThemedDropdown<T>(
      label: label,
      value: value,
      items: items,
      onChanged: onChanged,
      height: 48,
      fontSize: 14,
    );
  }

  @override
  Widget build(BuildContext context) {
    final review = widget.entry.postTradeReview ?? const PostTradeReview();
    final colors = context.colors;

    return JournalFormSurface(
      title: 'Post-Trade Review',
      subtitle: 'Capture outcome, grade execution, and lock the lesson.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _exit,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: journalWorkflowDecoration(
                    context,
                    label: 'Actual Exit Price',
                    prefixText: '₹ ',
                  ),
                  onChanged: (v) => _updateReview(
                    review.copyWith(actualExitPrice: double.tryParse(v)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InputDecorator(
                  decoration: journalWorkflowDecoration(
                    context,
                    label: 'P&L (auto)',
                  ),
                  child: Text(
                    review.actualPnl == null
                        ? '—'
                        : review.actualPnl!.toStringAsFixed(2),
                    style: TextStyle(
                      color: (review.actualPnl ?? 0) >= 0
                          ? context.statusSuccess
                          : context.statusError,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InputDecorator(
                  decoration: journalWorkflowDecoration(
                    context,
                    label: 'R Multiple (auto)',
                  ),
                  child: Text(
                    review.actualRMultiple == null
                        ? '—'
                        : '${review.actualRMultiple!.toStringAsFixed(2)} R',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _dropdown<String>(
                  label: 'Followed Stop Loss?',
                  value: review.followedStopLoss,
                  items: const [
                    DropdownMenuItem(value: 'Yes', child: Text('Yes')),
                    DropdownMenuItem(value: 'No', child: Text('No')),
                    DropdownMenuItem(value: 'Partial', child: Text('Partial')),
                  ],
                  onChanged: (v) =>
                      _updateReview(review.copyWith(followedStopLoss: v)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _dropdown<String>(
                  label: 'Followed Target?',
                  value: review.followedTarget,
                  items: const [
                    DropdownMenuItem(value: 'Full', child: Text('Full')),
                    DropdownMenuItem(value: 'Partial', child: Text('Partial')),
                    DropdownMenuItem(value: 'None', child: Text('None')),
                  ],
                  onChanged: (v) =>
                      _updateReview(review.copyWith(followedTarget: v)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _wentWell,
            maxLines: 3,
            decoration: journalWorkflowDecoration(
              context,
              label: 'What went well?',
              alignLabelWithHint: true,
            ),
            onChanged: (v) =>
                _updateReview(review.copyWith(whatWentWell: v)),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _improve,
            maxLines: 3,
            decoration: journalWorkflowDecoration(
              context,
              label: 'What could be improved?',
              alignLabelWithHint: true,
            ),
            onChanged: (v) =>
                _updateReview(review.copyWith(whatCouldBeImproved: v)),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _dropdown<String>(
                  label: 'Mistake Category',
                  value: review.mistakeCategory ?? 'NONE',
                  items: _mistakes
                      .map(
                        (m) => DropdownMenuItem(
                          value: m,
                          child: Text(humanizeEnum(m)),
                        ),
                      )
                      .toList(),
                  onChanged: (v) =>
                      _updateReview(review.copyWith(mistakeCategory: v)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _dropdown<int>(
                  label: 'Execution Score',
                  value: review.executionScore ?? 7,
                  items: List.generate(
                    10,
                    (i) => DropdownMenuItem(
                      value: i + 1,
                      child: Text('${i + 1} / 10'),
                    ),
                  ),
                  onChanged: (v) =>
                      _updateReview(review.copyWith(executionScore: v)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _dropdown<String>(
                  label: 'Emotional State',
                  value: review.emotionalState ?? 'CALM',
                  items: _emotions
                      .map(
                        (m) => DropdownMenuItem(
                          value: m,
                          child: Text(humanizeEnum(m)),
                        ),
                      )
                      .toList(),
                  onChanged: (v) =>
                      _updateReview(review.copyWith(emotionalState: v)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _lesson,
            maxLines: 3,
            decoration: journalWorkflowDecoration(
              context,
              label: 'Lesson Learned',
              alignLabelWithHint: true,
            ),
            onChanged: (v) =>
                _updateReview(review.copyWith(lessonLearned: v)),
          ),
          const SizedBox(height: 8),
          Text(
            'Saving the journal on this step marks it Completed.',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}
