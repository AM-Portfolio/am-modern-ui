import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../internal/domain/entities/journal_entry.dart';

class JournalEntryListView extends StatelessWidget {
  const JournalEntryListView({
    super.key,
    required this.entries,
    required this.selectedEntryId,
    required this.onEntrySelected,
    required this.onLogDayPressed,
    this.listTitle = 'Entries',
    this.emptyMessage = 'No journal entries yet.',
    this.emptySubtitle =
        'Start documenting your trades to unlock powerful insights.',
  });

  final List<JournalEntry> entries;
  final String? selectedEntryId;
  final ValueChanged<JournalEntry> onEntrySelected;
  final VoidCallback onLogDayPressed;
  final String listTitle;
  final String emptyMessage;
  final String emptySubtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;

    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: colors.cardSurface.withValues(alpha: 0.35),
        border: Border(
          right: BorderSide(color: colors.border.withValues(alpha: 0.28)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: Text(
              '$listTitle (${entries.length})',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: AppButton(
              text: 'Log day',
              icon: Icons.add_rounded,
              backgroundColor: ModuleColors.trade,
              width: double.infinity,
              height: 42,
              onPressed: onLogDayPressed,
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
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.menu_book_outlined,
              size: 28,
              color: ModuleColors.trade.withValues(alpha: 0.85),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.textSecondary,
                height: 1.4,
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
    required this.entry,
    required this.isSelected,
    required this.onTap,
    super.key,
  });

  final JournalEntry entry;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<JournalEntryItem> createState() => _JournalEntryItemState();
}

class _JournalEntryItemState extends State<JournalEntryItem> {
  bool _isHovered = false;

  /// Short card title — mockup uses the trade/type name, not the long date suffix.
  static String displayTitle(JournalEntry entry) {
    final raw = entry.title.trim();
    if (raw.isEmpty) return 'Untitled entry';
    final type = (entry.entryType ?? '').toUpperCase();
    if (type == 'WEEKLY_REVIEW' || raw.toLowerCase().startsWith('weekly')) {
      return 'Weekly review';
    }
    // Strip trailing "— 16 Oct 2026" style suffixes for cleaner cards.
    final emDash = raw.indexOf('—');
    if (emDash > 0) return raw.substring(0, emDash).trim();
    final hyphen = RegExp(r'\s[-–]\s+\d').firstMatch(raw);
    if (hyphen != null) return raw.substring(0, hyphen.start).trim();
    return raw;
  }

  static ({String label, Color fg, Color bg})? outcomePill(JournalEntry entry) {
    final raw = entry.postTradeReview?.tradeOutcome?.trim();
    if (raw == null || raw.isEmpty) return null;
    final key = raw.toLowerCase();
    if (key.contains('profit') ||
        key.contains('win') ||
        key == 'green' ||
        key == 'positive') {
      return (
        label: 'Profitable',
        fg: const Color(0xFF00B894),
        bg: const Color(0xFF00B894).withValues(alpha: 0.16),
      );
    }
    if (key.contains('loss') ||
        key.contains('lose') ||
        key == 'red' ||
        key == 'negative') {
      return (
        label: 'Loss',
        fg: const Color(0xFFFF7675),
        bg: const Color(0xFFFF7675).withValues(alpha: 0.16),
      );
    }
    if (key.contains('neutral') || key.contains('breakeven') || key == 'flat') {
      return (
        label: 'Neutral',
        fg: const Color(0xFFB0B0B0),
        bg: const Color(0xFF9E9E9E).withValues(alpha: 0.18),
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
    final title = displayTitle(widget.entry);
    final outcome = outcomePill(widget.entry);
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
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected
                    ? ModuleColors.trade
                    : colors.border.withValues(alpha: 0.28),
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: selected
                        ? ModuleColors.trade.withValues(alpha: 0.2)
                        : colors.cardSurface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: colors.border.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Icon(
                    Icons.description_outlined,
                    size: 17,
                    color: selected
                        ? ModuleColors.trade
                        : colors.textSecondary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dateStr,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: selected
                              ? ModuleColors.trade
                              : colors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
                if (outcome != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: outcome.bg,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      outcome.label,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: outcome.fg,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
