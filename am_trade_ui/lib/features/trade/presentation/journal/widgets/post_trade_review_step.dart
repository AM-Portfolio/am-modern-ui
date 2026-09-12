import 'package:flutter/material.dart';

import '../../../internal/domain/entities/journal_entry.dart';
import '../utils/journal_calc_helper.dart';

class PostTradeReviewStep extends StatelessWidget {
  const PostTradeReviewStep({
    super.key,
    required this.entry,
    required this.onUpdate,
  });

  final JournalEntry entry;
  final ValueChanged<JournalEntry> onUpdate;

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

  void _updateReview(PostTradeReview review, {bool? markCompleted}) {
    final plan = entry.preTradePlan;
    final exec = entry.tradeExecution;
    final risk = JournalCalcHelper.plannedRiskAmount(
      entry: plan?.plannedEntryPrice,
      stop: plan?.plannedStopLoss,
      quantity: plan?.plannedQuantity ?? exec?.quantity,
    );
    final pnl = JournalCalcHelper.actualPnl(
      entryPrice: exec?.actualEntryPrice ?? plan?.plannedEntryPrice,
      exitPrice: review.actualExitPrice,
      quantity: exec?.quantity ?? plan?.plannedQuantity,
      tradeDirection: entry.tradeDirection,
    );
    final r = JournalCalcHelper.actualRMultiple(
      pnl: pnl,
      plannedRisk: risk ?? plan?.plannedRiskAmount,
    );

    onUpdate(
      entry.copyWith(
        journalStatus: markCompleted == true
            ? 'COMPLETED'
            : entry.journalStatus,
        postTradeReview: review.copyWith(
          actualPnl: pnl ?? review.actualPnl,
          actualRMultiple: r ?? review.actualRMultiple,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final review = entry.postTradeReview ?? const PostTradeReview();
    final completed = (entry.journalStatus ?? '').toUpperCase() == 'COMPLETED';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Post-Trade Review',
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Capture outcome, grade execution, and lock the lesson.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: review.actualExitPrice?.toString(),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Actual Exit Price',
                  border: OutlineInputBorder(),
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
                decoration: const InputDecoration(
                  labelText: 'P&L (auto)',
                  border: OutlineInputBorder(),
                ),
                child: Text(
                  review.actualPnl == null
                      ? '—'
                      : review.actualPnl!.toStringAsFixed(2),
                  style: TextStyle(
                    color: (review.actualPnl ?? 0) >= 0
                        ? Colors.green
                        : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'R Multiple (auto)',
                  border: OutlineInputBorder(),
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
              child: DropdownButtonFormField<String>(
                value: review.followedStopLoss,
                decoration: const InputDecoration(
                  labelText: 'Followed Stop Loss?',
                  border: OutlineInputBorder(),
                ),
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
              child: DropdownButtonFormField<String>(
                value: review.followedTarget,
                decoration: const InputDecoration(
                  labelText: 'Followed Target?',
                  border: OutlineInputBorder(),
                ),
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
          initialValue: review.whatWentWell,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'What went well?',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
          onChanged: (v) => _updateReview(review.copyWith(whatWentWell: v)),
        ),
        const SizedBox(height: 12),
        TextFormField(
          initialValue: review.whatCouldBeImproved,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'What could be improved?',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
          onChanged: (v) =>
              _updateReview(review.copyWith(whatCouldBeImproved: v)),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: review.mistakeCategory ?? 'NONE',
                decoration: const InputDecoration(
                  labelText: 'Mistake Category',
                  border: OutlineInputBorder(),
                ),
                items: _mistakes
                    .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                    .toList(),
                onChanged: (v) =>
                    _updateReview(review.copyWith(mistakeCategory: v)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<int>(
                value: review.executionScore ?? 7,
                decoration: const InputDecoration(
                  labelText: 'Execution Score',
                  border: OutlineInputBorder(),
                ),
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
              child: DropdownButtonFormField<String>(
                value: review.emotionalState ?? 'CALM',
                decoration: const InputDecoration(
                  labelText: 'Emotional State',
                  border: OutlineInputBorder(),
                ),
                items: _emotions
                    .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                    .toList(),
                onChanged: (v) =>
                    _updateReview(review.copyWith(emotionalState: v)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: review.lessonLearned,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Lesson Learned',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
          onChanged: (v) => _updateReview(review.copyWith(lessonLearned: v)),
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('Mark as Completed'),
          value: completed,
          onChanged: (v) => _updateReview(review, markCompleted: v),
        ),
      ],
    );
  }
}
