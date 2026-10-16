import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../internal/data/dtos/journal_entry_dto.dart';
import '../../cubit/journal/journal_cubit.dart';
import '../models/journal_folder_filter.dart';

class JournalInsightsPage extends StatefulWidget {
  const JournalInsightsPage({
    super.key,
    required this.journalCubit,
    this.startDate,
    this.endDate,
    this.onReviewTrades,
    this.unreviewedCount,
  });

  final JournalCubit journalCubit;
  final DateTime? startDate;
  final DateTime? endDate;
  /// Switch hub to Entries / Log Day when Insights has no structured reviews yet.
  final VoidCallback? onReviewTrades;

  /// Optional override for the empty-state CTA. When null the page derives it
  /// from the cubit's loaded entries (trade-like entries without an outcome).
  final int? unreviewedCount;

  @override
  State<JournalInsightsPage> createState() => JournalInsightsPageState();
}

class JournalInsightsPageState extends State<JournalInsightsPage> {
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

  @override
  void didUpdateWidget(covariant JournalInsightsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.startDate != widget.startDate ||
        oldWidget.endDate != widget.endDate) {
      _load();
    }
  }

  /// Re-fetch mistakes / lessons / adherence / report card (e.g. after Log Day save).
  Future<void> reload() => _load();

  /// Trade-like entries in range that still lack a post-trade outcome.
  int get _unreviewedCount {
    final override = widget.unreviewedCount;
    if (override != null) return override;
    final entries = widget.journalCubit.currentEntries;
    final start = widget.startDate;
    final end = widget.endDate;
    var n = 0;
    for (final e in entries) {
      if (!JournalFolderFilter.isTradeLikeEntry(e)) continue;
      if (start != null && e.entryDate.isBefore(start)) continue;
      if (end != null && e.entryDate.isAfter(end.add(const Duration(days: 1)))) {
        continue;
      }
      final outcome = e.postTradeReview?.tradeOutcome;
      if (outcome == null || outcome.trim().isEmpty) n++;
    }
    return n;
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final start = widget.startDate;
      final end = widget.endDate;
      final mistakes = await widget.journalCubit.loadMistakesSummary(
        start: start,
        end: end,
      );
      final lessons = await widget.journalCubit.loadLessons(
        start: start,
        end: end,
        limit: 20,
      );
      final adherence = await widget.journalCubit.loadAdherence(
        start: start,
        end: end,
      );
      final report = await widget.journalCubit.loadReportCard(
        start: start,
        end: end,
      );
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
    final emptyInsights = (a?.sampleSize ?? 0) == 0 &&
        _mistakes.isEmpty &&
        _lessons.isEmpty;
    final unreviewed = emptyInsights ? _unreviewedCount : 0;

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
          if (emptyInsights) ...[
            const SizedBox(height: AppSpacing.lg),
            AppCard(
              elevation: 0,
              backgroundColor: colors.cardSurface,
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      unreviewed > 0
                          ? 'Review $unreviewed unreviewed trade${unreviewed == 1 ? '' : 's'} to unlock Insights'
                          : 'Review today’s fills to unlock Insights',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Log Day → attach today’s fills → set outcome + mistake. '
                      'Those PostTradeReview fields power mistakes, adherence, and lessons here.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colors.textSecondary,
                          ),
                    ),
                    if (widget.onReviewTrades != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      AppButton(
                        text: 'Review trade',
                        type: AppButtonType.primary,
                        backgroundColor: ModuleColors.trade,
                        onPressed: widget.onReviewTrades,
                        height: 36,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          _InsightMetricsRow(
            cards: [
              (
                'Plan adherence',
                a?.avgPlanAdherenceScore == null
                    ? '—'
                    : '${a!.avgPlanAdherenceScore!.toStringAsFixed(0)}%',
              ),
              (
                'Checklist completion',
                a?.avgChecklistCompletionPct == null
                    ? '—'
                    : '${a!.avgChecklistCompletionPct!.toStringAsFixed(0)}%',
              ),
              (
                'Avg execution score',
                a?.avgExecutionScore == null
                    ? '—'
                    : a!.avgExecutionScore!.toStringAsFixed(1),
              ),
              (
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
              'Report card',
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
              'Hub range: ${_report!.from ?? '—'} → ${_report!.to ?? '—'}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.textSecondary,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            _InsightMetricsRow(
              cards: [
                (
                  'Report adherence',
                  _report!.adherence?.avgPlanAdherenceScore == null
                      ? '—'
                      : '${_report!.adherence!.avgPlanAdherenceScore!.toStringAsFixed(0)}%',
                ),
                (
                  'Top mistake',
                  (_report!.mistakes?.isNotEmpty ?? false)
                      ? (_report!.mistakes!.first.mistakeCategory ?? '—')
                      : '—',
                ),
                (
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
}

/// Equal-width metric strip — avoids [AmStatCard] overflow artifacts in Wrap.
class _InsightMetricsRow extends StatelessWidget {
  const _InsightMetricsRow({required this.cards});

  final List<(String title, String value)> cards;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = AppSpacing.md;
        final wide = constraints.maxWidth >= 720;
        if (wide) {
          return Row(
            children: [
              for (var i = 0; i < cards.length; i++) ...[
                if (i > 0) SizedBox(width: gap),
                Expanded(
                  child: _InsightMetricCard(
                    title: cards[i].$1,
                    value: cards[i].$2,
                  ),
                ),
              ],
            ],
          );
        }
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final c in cards)
              SizedBox(
                width: (constraints.maxWidth - gap) / 2,
                child: _InsightMetricCard(title: c.$1, value: c.$2),
              ),
          ],
        );
      },
    );
  }
}

class _InsightMetricCard extends StatelessWidget {
  const _InsightMetricCard({
    required this.title,
    required this.value,
  });

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: colors.cardSurface,
        borderRadius: AppRadii.card,
        border: Border.all(color: colors.border.withValues(alpha: 0.3)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 22,
              color: value == '—'
                  ? colors.textSecondary
                  : ModuleColors.trade,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}
