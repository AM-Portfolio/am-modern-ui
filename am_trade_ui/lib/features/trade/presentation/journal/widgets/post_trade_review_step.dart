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

  Widget _gap() => const SizedBox(height: 14);

  Widget _row(Widget left, Widget right) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        const SizedBox(width: 14),
        Expanded(child: right),
      ],
    );
  }

  Widget _dropdown<T>({
    required String placeholder,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return JournalThemedDropdown<T>(
      hint: placeholder,
      value: value,
      items: items,
      onChanged: onChanged,
      height: 48,
      fontSize: 15,
    );
  }

  Widget _autoBox({
    required String placeholder,
    required String value,
    Color? valueColor,
  }) {
    final theme = Theme.of(context);
    return InputDecorator(
      decoration: journalWorkflowDecoration(context, hintText: placeholder),
      child: Text(
        value,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: valueColor,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String placeholder,
    required ValueChanged<String> onChanged,
    String? prefixText,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    final theme = Theme.of(context);
    return TextFormField(
      controller: controller,
      style: theme.textTheme.bodyLarge,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: journalWorkflowDecoration(
        context,
        hintText: placeholder,
        prefixText: prefixText,
        alignLabelWithHint: maxLines > 1,
      ),
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    final review = widget.entry.postTradeReview ?? const PostTradeReview();
    final colors = context.colors;
    final theme = Theme.of(context);

    return JournalFormSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _row(
            _field(
              controller: _exit,
              placeholder: 'Actual exit price',
              prefixText: '₹ ',
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              onChanged: (v) => _updateReview(
                review.copyWith(actualExitPrice: double.tryParse(v)),
              ),
            ),
            _autoBox(
              placeholder: 'P&L (auto)',
              value: review.actualPnl == null
                  ? '—'
                  : review.actualPnl!.toStringAsFixed(2),
              valueColor: review.actualPnl == null
                  ? null
                  : (review.actualPnl! >= 0
                      ? context.statusSuccess
                      : context.statusError),
            ),
          ),
          _gap(),
          _row(
            _autoBox(
              placeholder: 'R multiple (auto)',
              value: review.actualRMultiple == null
                  ? '—'
                  : '${review.actualRMultiple!.toStringAsFixed(2)} R',
            ),
            _dropdown<String>(
              placeholder: 'Followed stop loss?',
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
          _gap(),
          _row(
            _dropdown<String>(
              placeholder: 'Followed target?',
              value: review.followedTarget,
              items: const [
                DropdownMenuItem(value: 'Full', child: Text('Full')),
                DropdownMenuItem(value: 'Partial', child: Text('Partial')),
                DropdownMenuItem(value: 'None', child: Text('None')),
              ],
              onChanged: (v) =>
                  _updateReview(review.copyWith(followedTarget: v)),
            ),
            _dropdown<String>(
              placeholder: 'Mistake category',
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
          _gap(),
          _row(
            _dropdown<int>(
              placeholder: 'Execution score',
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
            _dropdown<String>(
              placeholder: 'Emotional state',
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
          _gap(),
          _row(
            _field(
              controller: _wentWell,
              placeholder: 'What went well?',
              maxLines: 3,
              onChanged: (v) =>
                  _updateReview(review.copyWith(whatWentWell: v)),
            ),
            _field(
              controller: _improve,
              placeholder: 'What could be improved?',
              maxLines: 3,
              onChanged: (v) =>
                  _updateReview(review.copyWith(whatCouldBeImproved: v)),
            ),
          ),
          _gap(),
          _field(
            controller: _lesson,
            placeholder: 'Lesson learned',
            maxLines: 3,
            onChanged: (v) =>
                _updateReview(review.copyWith(lessonLearned: v)),
          ),
          const SizedBox(height: 8),
          Text(
            'Saving the journal on this step marks it Completed.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
