import 'package:am_design_system/am_design_system.dart';
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
    final colors = context.colors;

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
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              text: 'Retry',
              type: AppButtonType.primary,
              backgroundColor: ModuleColors.trade,
              onPressed: _load,
              height: 36,
            ),
          ],
        ),
      );
    }

    final pnlFmt = NumberFormat.currency(symbol: '₹ ', decimalDigits: 0);
    final a = _adherence;

    return RefreshIndicator(
      color: ModuleColors.trade,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(
            'Journal Insights',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Discipline signals from your journal — not the full Metrics hub.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.textSecondary,
                ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              _statCard(
                'Plan adherence',
                a?.avgPlanAdherenceScore == null
                    ? '—'
                    : '${a!.avgPlanAdherenceScore!.toStringAsFixed(0)}%',
              ),
              _statCard(
                'Checklist completion',
                a?.avgChecklistCompletionPct == null
                    ? '—'
                    : '${a!.avgChecklistCompletionPct!.toStringAsFixed(0)}%',
              ),
              _statCard(
                'Avg execution score',
                a?.avgExecutionScore == null
                    ? '—'
                    : a!.avgExecutionScore!.toStringAsFixed(1),
              ),
              _statCard(
                'Sample size',
                '${a?.sampleSize ?? 0}',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Mistake cost',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (_mistakes.isEmpty)
            Text(
              'No mistake categories recorded yet.',
              style: TextStyle(color: colors.textSecondary),
            )
          else
            AppCard(
              padded: false,
              elevation: 0,
              backgroundColor: colors.cardSurface,
              margin: EdgeInsets.zero,
              child: SortableTable<MistakeAnalysisDto>(
                items: _mistakes,
                shrinkWrap: true,
                rowHeight: 48,
                initialSortColumnIndex: 1,
                initialSortDirection: SortDirection.descending,
                headerTextStyle: context.text.caption(compact: true).copyWith(
                      color: colors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                columns: [
                  SortableColumn<MistakeAnalysisDto>(
                    title: 'Category',
                    flex: 2,
                    sortBy: (m) => m.mistakeCategory ?? '',
                    builder: (m) => Text(
                      m.mistakeCategory ?? '—',
                      style: TextStyle(color: colors.textPrimary),
                    ),
                  ),
                  SortableColumn<MistakeAnalysisDto>(
                    title: 'Count',
                    sortBy: (m) => m.occurrenceCount,
                    textAlign: TextAlign.end,
                    builder: (m) => Text(
                      '${m.occurrenceCount}',
                      textAlign: TextAlign.end,
                      style: TextStyle(color: colors.textPrimary),
                    ),
                  ),
                  SortableColumn<MistakeAnalysisDto>(
                    title: 'P&L impact',
                    flex: 2,
                    sortBy: (m) => m.totalPnlImpact,
                    textAlign: TextAlign.end,
                    builder: (m) {
                      final impact = m.totalPnlImpact;
                      return Text(
                        impact == null ? '—' : pnlFmt.format(impact),
                        textAlign: TextAlign.end,
                        style: TextStyle(
                          color: impact == null
                              ? colors.textSecondary
                              : impact >= 0
                                  ? context.statusSuccess
                                  : context.statusError,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    },
                  ),
                  SortableColumn<MistakeAnalysisDto>(
                    title: '% of losses',
                    sortBy: (m) => m.percentageOfLosses,
                    textAlign: TextAlign.end,
                    builder: (m) => Text(
                      m.percentageOfLosses == null
                          ? '—'
                          : '${m.percentageOfLosses!.toStringAsFixed(0)}%',
                      textAlign: TextAlign.end,
                      style: TextStyle(color: colors.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Lessons learned',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (_lessons.isEmpty)
            Text(
              'No lessons yet — complete post-trade reviews.',
              style: TextStyle(color: colors.textSecondary),
            )
          else
            ..._lessons.map(
              (l) => AppCard(
                elevation: 0,
                backgroundColor: colors.cardSurface,
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    l.symbol ?? l.entryId ?? 'Lesson',
                    style: TextStyle(color: colors.textPrimary),
                  ),
                  subtitle: Text(
                    l.lessonLearned ?? '',
                    style: TextStyle(color: colors.textSecondary),
                  ),
                  trailing: l.executionScore == null
                      ? null
                      : Text(
                          '${l.executionScore}/10',
                          style: TextStyle(
                            color: ModuleColors.trade,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ),
          if (_report != null) ...[
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Weekly report card',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Window: ${_report!.from ?? '—'} → ${_report!.to ?? '—'}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.textSecondary,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              children: [
                _statCard(
                  'Report adherence',
                  _report!.adherence?.avgPlanAdherenceScore == null
                      ? '—'
                      : '${_report!.adherence!.avgPlanAdherenceScore!.toStringAsFixed(0)}%',
                ),
                _statCard(
                  'Top mistake',
                  (_report!.mistakes?.isNotEmpty ?? false)
                      ? (_report!.mistakes!.first.mistakeCategory ?? '—')
                      : '—',
                ),
                _statCard(
                  'Lessons logged',
                  '${_report!.topLessons?.length ?? 0}',
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _statCard(String title, String value) {
    return SizedBox(
      width: 180,
      child: AmStatCard(
        title: title,
        value: value,
        type: StatType.accent,
      ),
    );
  }
}
