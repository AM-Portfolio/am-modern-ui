import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../internal/data/dtos/journal_entry_dto.dart';
import '../../cubit/journal/journal_cubit.dart';
import '../models/journal_folder_filter.dart';
import '../widgets/journal_form_surface.dart';
import '../widgets/journal_workflow_field_theme.dart';

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
    final theme = Theme.of(context);

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
    final topMistake = (_report?.mistakes?.isNotEmpty ?? false)
        ? (_report!.mistakes!.first.mistakeCategory ??
            (_mistakes.isNotEmpty ? _mistakes.first.mistakeCategory : null))
        : (_mistakes.isNotEmpty ? _mistakes.first.mistakeCategory : null);
    final rangeLabel = _report == null
        ? null
        : '${_report!.from ?? '—'} → ${_report!.to ?? '—'}';

    return RefreshIndicator(
      color: ModuleColors.trade,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Insights',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'How well you followed the plan — from post-trade reviews.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                    if (rangeLabel != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        rangeLabel,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colors.textTertiary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Refresh',
                onPressed: _load,
                icon: Icon(
                  Icons.refresh_rounded,
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
          if (emptyInsights) ...[
            const SizedBox(height: AppSpacing.lg),
            JournalFormSurface(
              title: unreviewed > 0
                  ? 'Review $unreviewed trade${unreviewed == 1 ? '' : 's'} to unlock'
                  : 'No reviewed trades yet',
              subtitle:
                  'Log Day or Trade journal → set outcome + mistake. Those fields power this page.',
              leading: Icon(
                Icons.insights_outlined,
                size: 18,
                color: ModuleColors.trade,
              ),
              trailing: widget.onReviewTrades == null
                  ? null
                  : AppButton(
                      text: 'Review trade',
                      type: AppButtonType.primary,
                      backgroundColor: ModuleColors.trade,
                      onPressed: widget.onReviewTrades,
                      height: 36,
                    ),
              child: const SizedBox.shrink(),
            ),
          ] else ...[
            const SizedBox(height: AppSpacing.lg),
            _InsightMetricsRow(
              cards: [
                _InsightMetric(
                  title: 'Plan adherence',
                  value: a?.avgPlanAdherenceScore == null
                      ? '—'
                      : '${a!.avgPlanAdherenceScore!.toStringAsFixed(0)}%',
                  icon: Icons.track_changes_outlined,
                ),
                _InsightMetric(
                  title: 'Checklist',
                  value: a?.avgChecklistCompletionPct == null
                      ? '—'
                      : '${a!.avgChecklistCompletionPct!.toStringAsFixed(0)}%',
                  icon: Icons.checklist_rounded,
                ),
                _InsightMetric(
                  title: 'Exec score',
                  value: a?.avgExecutionScore == null
                      ? '—'
                      : a!.avgExecutionScore!.toStringAsFixed(1),
                  icon: Icons.speed_outlined,
                ),
                _InsightMetric(
                  title: 'Top mistake',
                  value: topMistake == null
                      ? '—'
                      : humanizeEnum(topMistake),
                  icon: Icons.warning_amber_rounded,
                ),
                _InsightMetric(
                  title: 'Lessons',
                  value: '${_lessons.length}',
                  icon: Icons.lightbulb_outline_rounded,
                ),
                _InsightMetric(
                  title: 'Sample',
                  value: '${a?.sampleSize ?? 0}',
                  icon: Icons.tag_rounded,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            JournalFormSurface(
              title: 'Mistake cost',
              subtitle: 'Where discipline slips show up in P&L',
              leading: Icon(
                Icons.report_gmailerrorred_outlined,
                size: 18,
                color: ModuleColors.trade,
              ),
              child: _mistakes.isEmpty
                  ? Text(
                      'No mistake categories recorded yet.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.textSecondary,
                      ),
                    )
                  : Column(
                      children: [
                        for (var i = 0; i < _mistakes.length; i++) ...[
                          if (i > 0)
                            Divider(
                              height: AppSpacing.md + 4,
                              color: colors.border.withValues(alpha: 0.25),
                            ),
                          _MistakeRow(
                            mistake: _mistakes[i],
                            pnlFmt: pnlFmt,
                          ),
                        ],
                      ],
                    ),
            ),
            const SizedBox(height: AppSpacing.lg),
            JournalFormSurface(
              title: 'Lessons learned',
              subtitle: 'From completed post-trade reviews',
              leading: Icon(
                Icons.menu_book_outlined,
                size: 18,
                color: ModuleColors.trade,
              ),
              child: _lessons.isEmpty
                  ? Text(
                      'No lessons yet — finish a post-trade review.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.textSecondary,
                      ),
                    )
                  : Column(
                      children: [
                        for (var i = 0; i < _lessons.length; i++) ...[
                          if (i > 0)
                            Divider(
                              height: AppSpacing.md + 4,
                              color: colors.border.withValues(alpha: 0.25),
                            ),
                          _LessonRow(lesson: _lessons[i]),
                        ],
                      ],
                    ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InsightMetric {
  const _InsightMetric({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;
}

class _InsightMetricsRow extends StatelessWidget {
  const _InsightMetricsRow({required this.cards});

  final List<_InsightMetric> cards;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = AppSpacing.sm;
        final wide = constraints.maxWidth >= 960;
        final mid = constraints.maxWidth >= 640;
        final perRow = wide ? 6 : (mid ? 3 : 2);
        final itemWidth =
            (constraints.maxWidth - gap * (perRow - 1)) / perRow;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final c in cards)
              SizedBox(
                width: itemWidth,
                child: _InsightMetricCard(metric: c),
              ),
          ],
        );
      },
    );
  }
}

class _InsightMetricCard extends StatelessWidget {
  const _InsightMetricCard({required this.metric});

  final _InsightMetric metric;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;
    final empty = metric.value == '—';

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
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  metric.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  metric.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: empty ? colors.textSecondary : ModuleColors.trade,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: ModuleColors.trade.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(metric.icon, size: 16, color: ModuleColors.trade),
          ),
        ],
      ),
    );
  }
}

class _MistakeRow extends StatelessWidget {
  const _MistakeRow({
    required this.mistake,
    required this.pnlFmt,
  });

  final MistakeAnalysisDto mistake;
  final NumberFormat pnlFmt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;
    final impact = mistake.totalPnlImpact;
    final category = humanizeEnum(mistake.mistakeCategory ?? 'Unknown');

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            category,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        SizedBox(
          width: 56,
          child: Text(
            '×${mistake.occurrenceCount}',
            textAlign: TextAlign.end,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ),
        SizedBox(
          width: 96,
          child: Text(
            impact == null ? '—' : pnlFmt.format(impact),
            textAlign: TextAlign.end,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: impact == null
                  ? colors.textSecondary
                  : impact >= 0
                      ? context.statusSuccess
                      : context.statusError,
            ),
          ),
        ),
        SizedBox(
          width: 64,
          child: Text(
            mistake.percentageOfLosses == null
                ? '—'
                : '${mistake.percentageOfLosses!.toStringAsFixed(0)}%',
            textAlign: TextAlign.end,
            style: theme.textTheme.labelMedium?.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class _LessonRow extends StatelessWidget {
  const _LessonRow({required this.lesson});

  final LessonLearnedDto lesson;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                lesson.symbol ?? lesson.entryId ?? 'Lesson',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if ((lesson.lessonLearned ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  lesson.lessonLearned!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (lesson.executionScore != null)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xxs + 1,
            ),
            decoration: BoxDecoration(
              color: ModuleColors.trade.withValues(alpha: 0.12),
              borderRadius: AppRadii.chip,
            ),
            child: Text(
              '${lesson.executionScore}/10',
              style: theme.textTheme.labelSmall?.copyWith(
                color: ModuleColors.trade,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }
}
