import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../internal/data/dtos/journal_entry_dto.dart';
import '../../cubit/journal/journal_cubit.dart';

class JournalInsightsPage extends StatefulWidget {
  const JournalInsightsPage({super.key, required this.journalCubit});

  final JournalCubit journalCubit;

  @override
  State<JournalInsightsPage> createState() => _JournalInsightsPageState();
}

class _JournalInsightsPageState extends State<JournalInsightsPage> {
  List<MistakeAnalysisDto> _mistakes = [];
  List<LessonLearnedDto> _lessons = [];
  JournalAdherenceDto? _adherence;
  JournalReportCardDto? _report;
  var _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final mistakes = await widget.journalCubit.loadMistakesSummary();
      final lessons = await widget.journalCubit.loadLessons(limit: 20);
      final adherence = await widget.journalCubit.loadAdherence();
      final report = await widget.journalCubit.loadReportCard();
      if (!mounted) return;
      setState(() {
        _mistakes = mistakes;
        _lessons = lessons;
        _adherence = adherence;
        _report = report;
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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!),
            const SizedBox(height: 12),
            FilledButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }

    final pnlFmt = NumberFormat.currency(symbol: '₹ ', decimalDigits: 0);
    final a = _adherence;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Journal Insights',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Discipline signals from your journal — not the full Metrics hub.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _statCard(
                context,
                'Plan adherence',
                a?.avgPlanAdherenceScore == null
                    ? '—'
                    : '${a!.avgPlanAdherenceScore!.toStringAsFixed(0)}%',
              ),
              _statCard(
                context,
                'Checklist completion',
                a?.avgChecklistCompletionPct == null
                    ? '—'
                    : '${a!.avgChecklistCompletionPct!.toStringAsFixed(0)}%',
              ),
              _statCard(
                context,
                'Avg execution score',
                a?.avgExecutionScore == null
                    ? '—'
                    : a!.avgExecutionScore!.toStringAsFixed(1),
              ),
              _statCard(
                context,
                'Sample size',
                '${a?.sampleSize ?? 0}',
              ),
            ],
          ),
          const SizedBox(height: 32),
          Text(
            'Mistake cost',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (_mistakes.isEmpty)
            const Text('No mistake categories recorded yet.')
          else
            DataTable(
              columns: const [
                DataColumn(label: Text('Category')),
                DataColumn(label: Text('Count')),
                DataColumn(label: Text('P&L impact')),
                DataColumn(label: Text('% of losses')),
              ],
              rows: _mistakes
                  .map(
                    (m) => DataRow(
                      cells: [
                        DataCell(Text(m.mistakeCategory ?? '—')),
                        DataCell(Text('${m.occurrenceCount}')),
                        DataCell(
                          Text(
                            m.totalPnlImpact == null
                                ? '—'
                                : pnlFmt.format(m.totalPnlImpact),
                          ),
                        ),
                        DataCell(
                          Text(
                            m.percentageOfLosses == null
                                ? '—'
                                : '${m.percentageOfLosses!.toStringAsFixed(0)}%',
                          ),
                        ),
                      ],
                    ),
                  )
                  .toList(),
            ),
          const SizedBox(height: 32),
          Text(
            'Lessons learned',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (_lessons.isEmpty)
            const Text('No lessons yet — complete post-trade reviews.')
          else
            ..._lessons.map(
              (l) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(l.symbol ?? l.entryId ?? 'Lesson'),
                  subtitle: Text(l.lessonLearned ?? ''),
                  trailing: l.executionScore == null
                      ? null
                      : Text('${l.executionScore}/10'),
                ),
              ),
            ),
          if (_report?.summary != null) ...[
            const SizedBox(height: 24),
            Text(
              'Report card window: ${_report!.from ?? '—'} → ${_report!.to ?? '—'}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }

  Widget _statCard(BuildContext context, String title, String value) {
    return SizedBox(
      width: 180,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 8),
              Text(
                value,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
