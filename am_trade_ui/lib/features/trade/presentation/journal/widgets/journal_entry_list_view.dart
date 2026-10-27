import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../internal/domain/entities/journal_entry.dart';
import 'journal_trade_header.dart';

/// Left rail: create actions, optional filters, entry cards.
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
    this.width = 400,
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

  /// Inspiration layout: folder / tag / outcome / sort in one row.
  final Widget? filterSlot;
  final double width;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;

    return Container(
      width: width,
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
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
              child: Text(
                listTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          Padding(
            padding: EdgeInsets.fromLTRB(14, showListTitle ? 0 : 14, 14, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppButton(
                  text: 'Log day',
                  icon: Icons.add_rounded,
                  backgroundColor: ModuleColors.trade,
                  width: double.infinity,
                  height: 42,
                  onPressed: onLogDayPressed,
                ),
                if (onNewTradeJournalPressed != null) ...[
                  const SizedBox(height: 8),
                  AppButton(
                    text: 'New trade journal',
                    icon: Icons.candlestick_chart_outlined,
                    type: AppButtonType.secondary,
                    isOutlined: true,
                    backgroundColor: ModuleColors.trade,
                    width: double.infinity,
                    height: 40,
                    onPressed: onNewTradeJournalPressed,
                  ),
                ],
                if (filterSlot != null) ...[
                  const SizedBox(height: 12),
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
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                    itemCount: entries.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
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

class _EmptyListState extends StatelessWidget {
  const _EmptyListState({
    required this.message,
    required this.subtitle,
  });

  final String message;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.menu_book_outlined,
              size: 36,
              color: colors.textTertiary,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
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

  /// Draft / Open chip for trade stubs that have no outcome yet.
  static ({String label, Color fg, Color bg})? statusChip(
    BuildContext context,
    JournalEntry entry,
  ) {
    final type = (entry.entryType ?? '').toUpperCase();
    final isTrade = type == 'TRADE_JOURNAL' ||
        type == 'PRE_PLAN' ||
        type == 'POST_REVIEW' ||
        (entry.tradeId != null && entry.tradeId!.trim().isNotEmpty);
    if (!isTrade) return null;
    final status = (entry.journalStatus ?? 'DRAFT').toUpperCase();
    final colors = context.colors;
    switch (status) {
      case 'DRAFT':
      case 'PLANNED':
        return (
          label: 'Draft',
          fg: ModuleColors.trade,
          bg: ModuleColors.trade.withValues(alpha: 0.16),
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
      fg: ModuleColors.trade,
      bg: ModuleColors.trade.withValues(alpha: 0.16),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;
    final dateStr =
        DateFormat('EEE, MMM d, yyyy').format(widget.entry.entryDate);
    final title = JournalTradeHeader.displayTitle(widget.entry);
    final outcome = outcomePill(context, widget.entry);
    final statusPill =
        outcome == null ? statusChip(context, widget.entry) : null;
    final selected = widget.isSelected;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Material(
        color: selected
            ? ModuleColors.trade.withValues(alpha: 0.12)
            : _isHovered
                ? colors.surface.withValues(alpha: 0.7)
                : colors.surface.withValues(alpha: 0.4),
        borderRadius: AppRadii.card,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: AppRadii.card,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dateStr,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colors.textTertiary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (outcome != null || statusPill != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: (outcome ?? statusPill)!.bg,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            (outcome ?? statusPill)!.label,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: (outcome ?? statusPill)!.fg,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (widget.onDelete != null)
                  PopupMenuButton<String>(
                    tooltip: 'More',
                    padding: EdgeInsets.zero,
                    icon: Icon(
                      Icons.more_vert_rounded,
                      size: 18,
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
      ),
    );
  }
}
