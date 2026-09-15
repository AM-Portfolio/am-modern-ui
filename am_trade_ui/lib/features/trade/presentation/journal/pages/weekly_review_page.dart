import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../internal/domain/entities/journal_entry.dart';
import '../../cubit/journal/journal_cubit.dart';
import '../../cubit/journal/journal_state.dart';
import 'trade_journal_workflow_page.dart';

class WeeklyReviewPage extends StatefulWidget {
  const WeeklyReviewPage({super.key, required this.journalCubit});

  final JournalCubit journalCubit;

  @override
  State<WeeklyReviewPage> createState() => _WeeklyReviewPageState();
}

class _WeeklyReviewPageState extends State<WeeklyReviewPage> {
  final _notes = TextEditingController();
  final _checklist = <String, bool>{
    'Reviewed all completed trades': false,
    'Identified top mistake this week': false,
    'Updated playbook / rules': false,
    'Set focus for next week': false,
  };

  @override
  void initState() {
    super.initState();
    widget.journalCubit.setFilters(status: 'COMPLETED', reload: true);
  }

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _saveWeeklyReview(List<JournalEntry> completed) async {
    final checked = _checklist.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();
    await widget.journalCubit.saveEntryFull(
      title:
          'Weekly review — ${DateFormat('dd MMM yyyy').format(DateTime.now())}',
      content: _notes.text,
      entryDate: DateTime.now(),
      entryType: 'WEEKLY_REVIEW',
      journalStatus: 'COMPLETED',
      relatedTradeIds: completed.map((e) => e.tradeId).whereType<String>().toList(),
      postTradeReview: PostTradeReview(
        lessonLearned: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        completedChecklistItems: checked,
        postChecklist: _checklist.keys.toList(),
      ),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Weekly review saved')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<JournalCubit, JournalState>(
      bloc: widget.journalCubit,
      builder: (context, state) {
        final entries = state.maybeWhen(
          loaded: (e, _, __, ___, ____, _____, ______) => e,
          orElse: () => <JournalEntry>[],
        );
        final completed = entries
            .where((e) => (e.journalStatus ?? '').toUpperCase() == 'COMPLETED')
            .take(20)
            .toList();

        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Weekly Review',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Guided process review of your recent completed journals.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),
            Text(
              'Process checklist',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            ..._checklist.keys.map(
              (k) => CheckboxListTile(
                value: _checklist[k],
                title: Text(k),
                onChanged: (v) => setState(() => _checklist[k] = v ?? false),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notes,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Week summary / focus for next week',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton(
                onPressed: () => _saveWeeklyReview(completed),
                child: const Text('Save weekly review'),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Recent completed entries',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (completed.isEmpty)
              const Text('No completed journals in the current filter.')
            else
              ...completed.map(
                (e) => ListTile(
                  title: Text(e.symbol ?? e.title),
                  subtitle: Text(
                    e.postTradeReview?.lessonLearned ??
                        e.setup ??
                        DateFormat('dd MMM').format(e.entryDate),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => TradeJournalWorkflowPage(
                          journalCubit: widget.journalCubit,
                          initialEntry: e,
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}
