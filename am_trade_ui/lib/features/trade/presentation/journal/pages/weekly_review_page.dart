import 'dart:convert';

import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:intl/intl.dart';

import '../../../internal/data/dtos/journal_entry_dto.dart';
import '../../../internal/domain/entities/journal_entry.dart';
import '../../cubit/journal/journal_cubit.dart';
import '../widgets/journal_form_surface.dart';
import 'trade_journal_workflow_page.dart';

/// Persist notes as Quill delta JSON so Entries detail can open them.
String _notesAsQuillJson(String text) {
  final trimmed = text.trim();
  final doc = quill.Document();
  if (trimmed.isEmpty) {
    doc.insert(0, '\n');
  } else {
    doc.insert(0, '$trimmed\n');
  }
  return jsonEncode(doc.toDelta().toJson());
}

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
  static const _maxNotes = 1000;

  final _notes = TextEditingController();
  final _checklist = <String, bool>{
    'Reviewed all completed trades': false,
    'Identified top mistake this week': false,
    'Updated playbook / rules': false,
    'Reviewed risk management': false,
    'Set focus for next week': false,
    'Reviewed journal & key learnings': false,
  };

  late DateTimeRange _weekRange;
  List<JournalEntry> _completed = const [];
  JournalReportCardDto? _report;
  var _loading = true;
  var _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _weekRange = defaultLastTradingWeekRange();
    _notes.addListener(() => setState(() {}));
    _loadWeek();
  }

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  int get _checkedCount => _checklist.values.where((v) => v).length;

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

  Future<void> _pickWeekRange() async {
    // Use the design-system compact dialog (popup), not Material's
    // full-page showDateRangePicker which takes over the route on web.
    final picked = await showDialog<DateTimeRange>(
      context: context,
      barrierDismissible: true,
      builder: (context) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: ModuleColors.trade,
              ),
        ),
        child: CompactDateRangePickerDialog(
          initialDateRange: _weekRange,
        ),
      ),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _weekRange = DateTimeRange(
        start: DateTime(picked.start.year, picked.start.month, picked.start.day),
        end: DateTime(picked.end.year, picked.end.month, picked.end.day),
      );
    });
    await _loadWeek();
  }

  Future<void> _saveWeeklyReview() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final checked = _checklist.entries
          .where((e) => e.value)
          .map((e) => e.key)
          .toList();
      final notes = _notes.text;
      await widget.journalCubit.saveEntryFull(
        title:
            'Weekly review — ${DateFormat('dd MMM yyyy').format(DateTime.now())}',
        content: _notesAsQuillJson(notes),
        entryDate: DateTime.now(),
        entryType: 'WEEKLY_REVIEW',
        journalStatus: 'COMPLETED',
        relatedTradeIds:
            _completed.map((e) => e.tradeId).whereType<String>().toList(),
        postTradeReview: PostTradeReview(
          lessonLearned: notes.trim().isEmpty ? null : notes.trim(),
          completedChecklistItems: checked,
          postChecklist: _checklist.keys.toList(),
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Weekly review saved'),
          backgroundColor: context.statusSuccess,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Save failed: $e'),
          backgroundColor: context.statusError,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _openFullReview(JournalEntry entry) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TradeJournalWorkflowPage(
          journalCubit: widget.journalCubit,
          initialEntry: entry,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              text: 'Retry',
              type: AppButtonType.primary,
              backgroundColor: ModuleColors.trade,
              onPressed: _loadWeek,
              height: 36,
            ),
          ],
        ),
      );
    }

    final summary = _report?.summary;
    final pnlFmt = NumberFormat.currency(symbol: '₹ ', decimalDigits: 0);
    final pnl = summary?.totalPnl;
    final winRate = summary?.winRate;
    final adherence = _report?.adherence?.avgPlanAdherenceScore;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        _WeeklyHero(
          weekLabel: weekLabel,
          onPickRange: _pickWeekRange,
          onSave: _saveWeeklyReview,
          saving: _saving,
        ),
        const SizedBox(height: AppSpacing.lg),
        _WeekStatsRow(
          cards: [
            (
              'Total trades',
              '${summary?.totalTrades ?? _completed.length}',
              Icons.swap_horiz_rounded,
              ModuleColors.trade,
              null,
            ),
            (
              'Win rate',
              winRate == null ? '—' : '${winRate.toStringAsFixed(1)}%',
              Icons.emoji_events_outlined,
              ModuleColors.trade,
              null,
            ),
            (
              'Net P&L',
              pnl == null ? '—' : pnlFmt.format(pnl),
              Icons.bar_chart_rounded,
              pnl == null
                  ? ModuleColors.trade
                  : (pnl >= 0
                      ? context.marketPositive
                      : context.marketNegative),
              null,
            ),
            (
              'Plan adherence',
              adherence == null ? '—' : '${adherence.toStringAsFixed(0)}%',
              Icons.track_changes_outlined,
              ModuleColors.trade,
              null,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 900;
            final checklist = _ProcessChecklistCard(
              checklist: _checklist,
              checkedCount: _checkedCount,
              onChanged: (key, value) =>
                  setState(() => _checklist[key] = value),
            );
            final notes = _NotesLessonsCard(
              controller: _notes,
              maxLength: _maxNotes,
            );
            if (wide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: checklist),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: notes),
                ],
              );
            }
            return Column(
              children: [
                checklist,
                const SizedBox(height: AppSpacing.md),
                notes,
              ],
            );
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        _CompletedTradesCard(
          entries: _completed,
          onOpen: _openFullReview,
          onRefresh: _loadWeek,
        ),
        const SizedBox(height: AppSpacing.xl),
        Align(
          alignment: Alignment.centerRight,
          child: AppButton(
            text: 'Save weekly review',
            icon: Icons.save_outlined,
            type: AppButtonType.primary,
            backgroundColor: ModuleColors.trade,
            onPressed: _saving ? null : _saveWeeklyReview,
            isLoading: _saving,
            height: 40,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Hero
// ---------------------------------------------------------------------------

class _WeeklyHero extends StatelessWidget {
  const _WeeklyHero({
    required this.weekLabel,
    required this.onPickRange,
    required this.onSave,
    required this.saving,
  });

  final String weekLabel;
  final VoidCallback onPickRange;
  final VoidCallback onSave;
  final bool saving;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.cardSurface,
        borderRadius: AppRadii.card,
        border: Border.all(color: colors.border.withValues(alpha: 0.35)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.cardSurface,
            ModuleColors.trade.withValues(alpha: 0.08),
          ],
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final showDecor = constraints.maxWidth >= 720;
          return Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: ModuleColors.trade.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.calendar_month_rounded,
                  color: ModuleColors.trade,
                  size: 28,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Weekly Review',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    InkWell(
                      onTap: onPickRange,
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              weekLabel,
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: ModuleColors.trade,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.expand_more_rounded,
                              size: 18,
                              color: ModuleColors.trade,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Guided process review for your last trading week.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (showDecor) ...[
                const SizedBox(width: AppSpacing.md),
                Opacity(
                  opacity: 0.9,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        Icons.assignment_outlined,
                        size: 72,
                        color: ModuleColors.trade.withValues(alpha: 0.22),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: ModuleColors.trade,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check_rounded,
                            size: 14,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(width: AppSpacing.md),
              AppButton(
                text: 'Save',
                icon: Icons.save_outlined,
                type: AppButtonType.primary,
                backgroundColor: ModuleColors.trade,
                onPressed: saving ? null : onSave,
                isLoading: saving,
                height: 36,
              ),
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Stats
// ---------------------------------------------------------------------------

class _WeekStatsRow extends StatelessWidget {
  const _WeekStatsRow({required this.cards});

  final List<(String title, String value, IconData icon, Color accent, String?)>
      cards;

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
                  child: _WeekStatCard(
                    title: cards[i].$1,
                    value: cards[i].$2,
                    icon: cards[i].$3,
                    accent: cards[i].$4,
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
                child: _WeekStatCard(
                  title: c.$1,
                  value: c.$2,
                  icon: c.$3,
                  accent: c.$4,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _WeekStatCard extends StatelessWidget {
  const _WeekStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.accent,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;

    return Container(
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
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
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
                    color: accent == ModuleColors.trade
                        ? theme.colorScheme.onSurface
                        : accent,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: accent),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Checklist
// ---------------------------------------------------------------------------

class _ProcessChecklistCard extends StatelessWidget {
  const _ProcessChecklistCard({
    required this.checklist,
    required this.checkedCount,
    required this.onChanged,
  });

  final Map<String, bool> checklist;
  final int checkedCount;
  final void Function(String key, bool value) onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;
    final total = checklist.length;
    final progress = total == 0 ? 0.0 : checkedCount / total;

    return JournalFormSurface(
      title: 'Process checklist',
      subtitle: '$checkedCount / $total completed',
      leading: Icon(
        Icons.checklist_rounded,
        size: 18,
        color: ModuleColors.trade,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: ModuleColors.trade.withValues(alpha: 0.12),
              color: ModuleColors.trade,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          for (final entry in checklist.entries) ...[
            _ChecklistRow(
              label: entry.key,
              checked: entry.value,
              onChanged: (v) => onChanged(entry.key, v),
            ),
            if (entry.key != checklist.keys.last)
              Divider(
                height: AppSpacing.md + 4,
                color: colors.border.withValues(alpha: 0.25),
              ),
          ],
          if (checkedCount == total && total > 0) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'All process items done for this week.',
              style: theme.textTheme.labelSmall?.copyWith(
                color: context.statusSuccess,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  const _ChecklistRow({
    required this.label,
    required this.checked,
    required this.onChanged,
  });

  final String label;
  final bool checked;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;

    return InkWell(
      onTap: () => onChanged(!checked),
      borderRadius: BorderRadius.circular(AppRadii.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs * 2),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: checked,
                onChanged: (v) => onChanged(v ?? false),
                activeColor: ModuleColors.trade,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  decoration: checked ? TextDecoration.lineThrough : null,
                  color: checked ? colors.textSecondary : null,
                  fontWeight: checked ? FontWeight.w500 : FontWeight.w600,
                ),
              ),
            ),
            if (checked)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xxs + 1,
                ),
                decoration: BoxDecoration(
                  color: context.statusSuccess.withValues(alpha: 0.12),
                  borderRadius: AppRadii.chip,
                ),
                child: Text(
                  'Completed',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: context.statusSuccess,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Notes
// ---------------------------------------------------------------------------

class _NotesLessonsCard extends StatelessWidget {
  const _NotesLessonsCard({
    required this.controller,
    required this.maxLength,
  });

  final TextEditingController controller;
  final int maxLength;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;
    final len = controller.text.characters.length;

    return JournalFormSurface(
      title: 'Notes / lessons',
      subtitle:
          'Write your key takeaways, what went well, what didn’t, and what to improve.',
      leading: Icon(
        Icons.lightbulb_outline_rounded,
        size: 18,
        color: ModuleColors.trade,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: controller,
            maxLines: 10,
            minLines: 8,
            maxLength: maxLength,
            maxLengthEnforcement: MaxLengthEnforcement.enforced,
            buildCounter: (
              context, {
              required currentLength,
              required isFocused,
              maxLength,
            }) =>
                const SizedBox.shrink(),
            decoration: InputDecoration(
              hintText: 'Write your weekly thoughts here...',
              hintStyle: theme.textTheme.bodyMedium?.copyWith(
                color: colors.textSecondary.withValues(alpha: 0.7),
              ),
              filled: true,
              fillColor: colors.surface.withValues(alpha: 0.45),
              border: OutlineInputBorder(
                borderRadius: AppRadii.card,
                borderSide: BorderSide(
                  color: colors.border.withValues(alpha: 0.35),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppRadii.card,
                borderSide: BorderSide(
                  color: colors.border.withValues(alpha: 0.35),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: AppRadii.card,
                borderSide: BorderSide(
                  color: ModuleColors.trade.withValues(alpha: 0.7),
                ),
              ),
              contentPadding: const EdgeInsets.all(AppSpacing.md),
              alignLabelWithHint: true,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '$len/$maxLength',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Completed trades table
// ---------------------------------------------------------------------------

class _CompletedTradesCard extends StatelessWidget {
  const _CompletedTradesCard({
    required this.entries,
    required this.onOpen,
    required this.onRefresh,
  });

  final List<JournalEntry> entries;
  final ValueChanged<JournalEntry> onOpen;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;
    final dateFmt = DateFormat('dd MMM');
    final pnlFmt = NumberFormat.currency(symbol: '₹ ', decimalDigits: 0);

    return JournalFormSurface(
      title: 'Completed trades this week (${entries.length})',
      subtitle: 'Journal entries marked completed in the selected range',
      leading: Icon(
        Icons.candlestick_chart_outlined,
        size: 18,
        color: ModuleColors.trade,
      ),
      trailing: TextButton(
        onPressed: onRefresh,
        style: TextButton.styleFrom(
          foregroundColor: ModuleColors.trade,
          visualDensity: VisualDensity.compact,
        ),
        child: const Text('Refresh'),
      ),
      child: entries.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Text(
                'No completed journal entries this week.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            )
          : Column(
              children: [
                _TableHeader(),
                const SizedBox(height: AppSpacing.xs),
                for (final e in entries) ...[
                  _TradeRow(
                    entry: e,
                    dateLabel: dateFmt.format(e.entryDate),
                    pnlLabel: e.postTradeReview?.actualPnl == null
                        ? '—'
                        : pnlFmt.format(e.postTradeReview!.actualPnl),
                    pnlColor: e.postTradeReview?.actualPnl == null
                        ? colors.textSecondary
                        : (e.postTradeReview!.actualPnl! >= 0
                            ? context.marketPositive
                            : context.marketNegative),
                    onOpen: () => onOpen(e),
                  ),
                  Divider(
                    height: 1,
                    color: colors.border.withValues(alpha: 0.2),
                  ),
                ],
              ],
            ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: context.colors.textSecondary,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          SizedBox(width: 88, child: Text('Date', style: style)),
          Expanded(flex: 2, child: Text('Symbol / title', style: style)),
          SizedBox(width: 72, child: Text('Type', style: style)),
          SizedBox(width: 88, child: Text('P&L', style: style)),
          Expanded(child: Text('Notes', style: style)),
          const SizedBox(width: 40),
        ],
      ),
    );
  }
}

class _TradeRow extends StatelessWidget {
  const _TradeRow({
    required this.entry,
    required this.dateLabel,
    required this.pnlLabel,
    required this.pnlColor,
    required this.onOpen,
  });

  final JournalEntry entry;
  final String dateLabel;
  final String pnlLabel;
  final Color pnlColor;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;
    final direction = (entry.tradeDirection ?? '').toUpperCase();
    final isBuy = direction.contains('LONG') || direction.contains('BUY');
    final isSell = direction.contains('SHORT') || direction.contains('SELL');
    final typeLabel = isBuy
        ? 'Buy'
        : isSell
            ? 'Sell'
            : (direction.isEmpty ? '—' : direction);
    final lesson = entry.postTradeReview?.lessonLearned?.trim();
    final notes = (lesson != null && lesson.isNotEmpty)
        ? lesson
        : (entry.title);

    return InkWell(
      onTap: onOpen,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm + 2),
        child: Row(
          children: [
            SizedBox(
              width: 88,
              child: Text(
                dateLabel,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                entry.symbol?.isNotEmpty == true ? entry.symbol! : entry.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(
              width: 72,
              child: typeLabel == '—'
                  ? Text('—', style: theme.textTheme.bodySmall)
                  : Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: (isBuy
                                  ? context.marketPositive
                                  : context.marketNegative)
                              .withValues(alpha: 0.12),
                          borderRadius: AppRadii.chip,
                        ),
                        child: Text(
                          typeLabel,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: isBuy
                                ? context.marketPositive
                                : context.marketNegative,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
            ),
            SizedBox(
              width: 88,
              child: Text(
                pnlLabel,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: pnlColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Expanded(
              child: Text(
                notes,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ),
            SizedBox(
              width: 40,
              child: IconButton(
                tooltip: 'Open full review',
                onPressed: onOpen,
                icon: Icon(
                  Icons.more_horiz_rounded,
                  color: colors.textSecondary,
                ),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
