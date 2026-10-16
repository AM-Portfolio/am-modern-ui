import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../internal/data/dtos/journal_entry_dto.dart';
import '../../../internal/domain/entities/journal_entry.dart';
import '../../cubit/journal/journal_cubit.dart';
import 'trade_journal_workflow_page.dart';

/// Mon–Fri through the most recent weekday (skips Sat/Sun on the end anchor).
DateTimeRange defaultLastTradingWeekRange([DateTime? now]) {
  final anchor = now ?? DateTime.now();
  var end = DateTime(anchor.year, anchor.month, anchor.day);
  while (end.weekday > DateTime.friday) {
    end = end.subtract(const Duration(days: 1));
  }
  final start = end.subtract(Duration(days: end.weekday - DateTime.monday));
  return DateTimeRange(start: start, end: end);
}

class WeeklyReviewPage extends StatefulWidget {
  const WeeklyReviewPage({
    super.key,
    required this.journalCubit,
  });

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

  late DateTimeRange _weekRange;
  List<JournalEntry> _completed = const [];
  JournalReportCardDto? _report;
  var _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _weekRange = defaultLastTradingWeekRange();
    _loadWeek();
  }

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _loadWeek() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final start = _weekRange.start;
      final end = _weekRange.end;
      final report = await widget.journalCubit.loadReportCard(
        start: start,
        end: end,
      );
      final entries = await widget.journalCubit.fetchEntriesOnce(
        status: 'COMPLETED',
        start: start,
        end: end,
        portfolioId: widget.journalCubit.portfolioId,
        size: 50,
      );
      if (!mounted) return;
      setState(() {
        _report = report;
        _completed = entries.take(20).toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _saveWeeklyReview() async {
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
      relatedTradeIds:
          _completed.map((e) => e.tradeId).whereType<String>().toList(),
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
    final colors = context.colors;
    final fmt = DateFormat('d MMM yyyy');
    final weekLabel =
        '${fmt.format(_weekRange.start)} – ${fmt.format(_weekRange.end)}';

    if (_loading) {
      return Center(
        child: CircularProgressIndicator(color: ModuleColors.trade),
      );
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!),
            const SizedBox(height: 12),
            TextButton(onPressed: _loadWeek, child: const Text('Retry')),
          ],
        ),
      );
    }

    final summary = _report?.summary;
    final pnlFmt = NumberFormat.currency(symbol: '₹ ', decimalDigits: 0);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text(
          'Weekly Review',
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          weekLabel,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colors.textSecondary,
              ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Guided process review for your last trading week.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colors.textSecondary,
              ),
        ),
        if (_report != null) ...[
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Week report card',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _StatChip(
                label: 'Trades',
                value: '${summary?.totalTrades ?? 0}',
              ),
              _StatChip(
                label: 'Win rate',
                value: summary?.winRate == null
                    ? '—'
                    : '${summary!.winRate!.toStringAsFixed(0)}%',
              ),
              _StatChip(
                label: 'P&L',
                value: summary?.totalPnl == null
                    ? '—'
                    : pnlFmt.format(summary!.totalPnl),
              ),
              _StatChip(
                label: 'Plan adherence',
                value: _report!.adherence?.avgPlanAdherenceScore == null
                    ? '—'
                    : '${_report!.adherence!.avgPlanAdherenceScore!.toStringAsFixed(0)}%',
              ),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Process checklist',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.sm),
        ..._checklist.keys.map(
          (key) => CheckboxListTile(
            value: _checklist[key],
            onChanged: (v) => setState(() => _checklist[key] = v ?? false),
            title: Text(key),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _notes,
          maxLines: 5,
          decoration: const InputDecoration(
            labelText: 'Notes / lessons',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Completed this week (${_completed.length})',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (_completed.isEmpty)
          Text(
            'No completed journal entries this week.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.textSecondary,
                ),
          )
        else
          ..._completed.map(
            (e) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(e.title),
              subtitle: Text(
                DateFormat('dd MMM yyyy').format(e.entryDate),
              ),
              trailing: TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => TradeJournalWorkflowPage(
                        journalCubit: widget.journalCubit,
                        initialEntry: e,
                      ),
                    ),
                  );
                },
                child: const Text('Open full review'),
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.lg),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: _saveWeeklyReview,
            icon: const Icon(Icons.save_outlined),
            label: const Text('Save weekly review'),
          ),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colors.cardSurface,
        borderRadius: AppRadii.card,
        border: Border.all(color: colors.border.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colors.textSecondary,
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}
