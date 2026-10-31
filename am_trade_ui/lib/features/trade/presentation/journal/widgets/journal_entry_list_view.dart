import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../internal/domain/entities/journal_entry.dart';
import '../models/journal_folder_filter.dart';
import 'journal_trade_header.dart';

/// Left rail: create toggle, optional filters, entry cards.
class JournalEntryListView extends StatelessWidget {
  const JournalEntryListView({
    super.key,
    required this.entries,
    required this.selectedEntryId,
    required this.onEntrySelected,
    required this.onLogDayPressed,
    this.onNewTradeJournalPressed,
    this.onDeleteEntry,
    this.listTitle = 'Entries',
    this.showListTitle = true,
    this.emptyMessage = 'No journal entries yet.',
    this.emptySubtitle =
        'Start documenting your trades to unlock powerful insights.',
    this.filterSlot,
    this.width = 320,
    this.createMode,
  });

  final List<JournalEntry> entries;
  final String? selectedEntryId;
  final ValueChanged<JournalEntry> onEntrySelected;
  final VoidCallback onLogDayPressed;
  /// Opens Pre-Trade → Execute → Post-Trade workflow.
  final VoidCallback? onNewTradeJournalPressed;
  final ValueChanged<JournalEntry>? onDeleteEntry;
  final String listTitle;
  final bool showListTitle;
  final String emptyMessage;
  final String emptySubtitle;

  /// Inspiration layout: folder / tag / outcome / sort in two rows.
  final Widget? filterSlot;
  final double width;

  /// `null` browsing; `false` Log Day composer; `true` trade workflow.
  final bool? createMode;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      width: width.isFinite ? width : null,
      decoration: BoxDecoration(
        color: colors.cardSurface.withValues(alpha: 0.4),
        border: Border(
          right: BorderSide(color: colors.border.withValues(alpha: 0.28)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showListTitle)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: Text(
                listTitle,
                style: context.text.sectionTitle(compact: true).copyWith(
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
              ),
            ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.sm + AppSpacing.xxs,
              showListTitle ? 0 : AppSpacing.sm + AppSpacing.xxs,
              AppSpacing.sm + AppSpacing.xxs,
              AppSpacing.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                JournalCreateModeToggle(
                  selected: createMode,
                  onLogDay: onLogDayPressed,
                  onTradeJournal: onNewTradeJournalPressed,
                ),
                if (filterSlot != null) ...[
                  const SizedBox(height: AppSpacing.sm + AppSpacing.xxs),
                  filterSlot!,
                ],
              ],
            ),
          ),
          Expanded(
            child: entries.isEmpty
                ? _EmptyListState(
                    message: emptyMessage,
                    subtitle: emptySubtitle,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.sm,
                      0,
                      AppSpacing.sm,
                      AppSpacing.md,
                    ),
                    itemCount: entries.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.sm - AppSpacing.xxs),
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      return JournalEntryItem(
                        entry: entry,
                        isSelected: entry.id == selectedEntryId,
                        onTap: () => onEntrySelected(entry),
                        onDelete: onDeleteEntry == null
                            ? null
                            : () => onDeleteEntry!(entry),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// Full-width Log day | Trade journal toggle (pill track). Shared by web + mobile.
class JournalCreateModeToggle extends StatelessWidget {
  const JournalCreateModeToggle({
    required this.onLogDay,
    this.selected,
    this.onTradeJournal,
    super.key,
  });

  /// `null` browsing; `false` Log day; `true` Trade journal.
  final bool? selected;
  final VoidCallback onLogDay;
  final VoidCallback? onTradeJournal;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent =
        ModuleColorProvider.maybeOf(context) ?? ModuleColors.trade;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xxs),
      decoration: BoxDecoration(
        borderRadius: AppRadii.input,
        color: colors.textPrimary.withValues(alpha: isDark ? 0.06 : 0.05),
        border: Border.all(color: colors.border.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _CreateModeSegment(
              label: 'Log day',
              icon: Icons.add_rounded,
              selected: selected == false,
              accent: accent,
              onTap: onLogDay,
            ),
          ),
          Expanded(
            child: _CreateModeSegment(
              label: 'Trade journal',
              icon: Icons.candlestick_chart_outlined,
              selected: selected == true,
              accent: accent,
              onTap: onTradeJournal,
            ),
          ),
        ],
      ),
    );
  }
}

class _CreateModeSegment extends StatelessWidget {
  const _CreateModeSegment({
    required this.label,
    required this.icon,
    required this.selected,
    required this.accent,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final Color accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final enabled = onTap != null;
    final fg = !enabled
        ? colors.textTertiary
        : selected
            ? colors.actionPrimaryFg
            : colors.textSecondary;
    final clear = colors.cardSurface.withValues(alpha: 0);

    return Material(
      color: clear,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.button,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.sm + AppSpacing.xxs,
            horizontal: AppSpacing.sm - AppSpacing.xxs,
          ),
          decoration: BoxDecoration(
            color: selected ? accent : clear,
            borderRadius: AppRadii.button,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: AppSpacing.md - AppSpacing.xxs, color: fg),
              const SizedBox(width: AppSpacing.xs),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: context.text.label(compact: true).copyWith(
                        color: fg,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyListState extends StatelessWidget {
  const _EmptyListState({
    required this.message,
    required this.subtitle,
  });

  final String message;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.menu_book_outlined,
              size: 32,
              color: colors.textTertiary,
            ),
            const SizedBox(height: AppSpacing.sm + AppSpacing.xxs),
            Text(
              message,
              textAlign: TextAlign.center,
              style: context.text.sectionTitle(compact: true).copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: context.text.caption(compact: true).copyWith(
                    color: colors.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class JournalEntryItem extends StatefulWidget {
  const JournalEntryItem({
    super.key,
    required this.entry,
    required this.isSelected,
    required this.onTap,
    this.onDelete,
  });

  final JournalEntry entry;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  @override
  State<JournalEntryItem> createState() => _JournalEntryItemState();
}

class _JournalEntryItemState extends State<JournalEntryItem> {
  bool _isHovered = false;

  static Color _moduleAccent(BuildContext context) =>
      ModuleColorProvider.maybeOf(context) ?? ModuleColors.trade;

  static ({String label, Color fg, Color bg})? statusChip(
    BuildContext context,
    JournalEntry entry,
  ) {
    if (!JournalFolderFilter.shouldOpenTradeWorkflow(entry)) return null;
    final status = (entry.journalStatus ?? 'DRAFT').toUpperCase();
    final colors = context.colors;
    final accent = _moduleAccent(context);
    switch (status) {
      case 'DRAFT':
      case 'PLANNED':
        return (
          label: 'Draft',
          fg: accent,
          bg: accent.withValues(alpha: 0.16),
        );
      case 'OPEN':
        return (
          label: 'Open',
          fg: colors.statusWarning,
          bg: colors.statusWarning.withValues(alpha: 0.16),
        );
      default:
        return null;
    }
  }

  static ({String label, Color fg, Color bg})? outcomePill(
    BuildContext context,
    JournalEntry entry,
  ) {
    final raw = entry.postTradeReview?.tradeOutcome?.trim();
    if (raw == null || raw.isEmpty) return null;
    final key = raw.toLowerCase();
    final colors = context.colors;
    final accent = _moduleAccent(context);
    if (key.contains('profit') ||
        key.contains('win') ||
        key == 'green' ||
        key == 'positive') {
      return (
        label: 'Profitable',
        fg: colors.marketPositiveIndicator,
        bg: colors.marketPositiveBg,
      );
    }
    if (key.contains('loss') ||
        key.contains('lose') ||
        key == 'red' ||
        key == 'negative') {
      return (
        label: 'Loss',
        fg: colors.marketNegativeIndicator,
        bg: colors.marketNegativeBg,
      );
    }
    if (key.contains('neutral') || key.contains('breakeven') || key == 'flat') {
      return (
        label: 'Neutral',
        fg: colors.textTertiary,
        bg: colors.statusNeutral.withValues(alpha: 0.18),
      );
    }
    return (
      label: raw,
      fg: accent,
      bg: accent.withValues(alpha: 0.16),
    );
  }

  Widget _pill(
    BuildContext context, {
    required String label,
    required Color fg,
    required Color bg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm - AppSpacing.xxs,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadii.chip,
      ),
      child: Text(
        label,
        style: context.text.caption(compact: true).copyWith(
              color: fg,
              fontWeight: FontWeight.w700,
              fontSize: AppTypeScale.xs,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final moduleAccent = _moduleAccent(context);
    final locale = Localizations.localeOf(context).toString();
    final dateStr = DateFormat('EEE, MMM d, yyyy', locale)
        .format(widget.entry.entryDate);
    final title = JournalTradeHeader.displayTitle(widget.entry);
    final isTrade = JournalFolderFilter.shouldOpenTradeWorkflow(widget.entry);
    final outcome = outcomePill(context, widget.entry);
    final statusPill =
        outcome == null ? statusChip(context, widget.entry) : null;
    final selected = widget.isSelected;
    final accent = isTrade
        ? moduleAccent
        : colors.border.withValues(alpha: 0.7);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Material(
        color: selected
            ? moduleAccent.withValues(alpha: 0.12)
            : _isHovered
                ? colors.surface.withValues(alpha: 0.7)
                : colors.surface.withValues(alpha: 0.4),
        borderRadius: AppRadii.card,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: AppRadii.card,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 3,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(AppRadii.sm + AppSpacing.xxs),
                      bottomLeft: Radius.circular(AppRadii.sm + AppSpacing.xxs),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.sm + AppSpacing.xxs,
                      AppSpacing.sm,
                      AppSpacing.xs,
                      AppSpacing.sm,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                dateStr,
                                style:
                                    context.text.caption(compact: true).copyWith(
                                          color: colors.textTertiary,
                                          fontSize: AppTypeScale.xs,
                                        ),
                              ),
                              const SizedBox(height: AppSpacing.xxs),
                              Text(
                                title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: context.text
                                    .sectionTitle(compact: true)
                                    .copyWith(
                                      fontWeight: FontWeight.w700,
                                      fontSize: AppTypeScale.md,
                                      color: colors.textPrimary,
                                    ),
                              ),
                              const SizedBox(
                                height: AppSpacing.sm - AppSpacing.xxs,
                              ),
                              Wrap(
                                spacing: AppSpacing.sm - AppSpacing.xxs,
                                runSpacing: AppSpacing.xs,
                                children: [
                                  _pill(
                                    context,
                                    label: isTrade ? 'Trade journal' : 'Log',
                                    fg: isTrade
                                        ? moduleAccent
                                        : colors.textSecondary,
                                    bg: isTrade
                                        ? moduleAccent.withValues(alpha: 0.16)
                                        : colors.statusNeutral
                                            .withValues(alpha: 0.18),
                                  ),
                                  if (outcome != null)
                                    _pill(
                                      context,
                                      label: outcome.label,
                                      fg: outcome.fg,
                                      bg: outcome.bg,
                                    ),
                                  if (statusPill != null)
                                    _pill(
                                      context,
                                      label: statusPill.label,
                                      fg: statusPill.fg,
                                      bg: statusPill.bg,
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (widget.onDelete != null)
                          PopupMenuButton<String>(
                            tooltip: 'More',
                            padding: EdgeInsets.zero,
                            color: colors.cardSurface,
                            surfaceTintColor:
                                colors.cardSurface.withValues(alpha: 0),
                            shape: RoundedRectangleBorder(
                              borderRadius: AppRadii.card,
                              side: BorderSide(
                                color: colors.border.withValues(alpha: 0.45),
                              ),
                            ),
                            icon: Icon(
                              Icons.more_vert_rounded,
                              size: 16,
                              color: colors.textTertiary,
                            ),
                            onSelected: (v) {
                              if (v == 'delete') widget.onDelete?.call();
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(
                                value: 'delete',
                                child: Text('Delete'),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
