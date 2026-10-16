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
    final groupedEntries = _groupEntriesByDate(entries);

    return Container(
      width: 340,
      decoration: BoxDecoration(
        color: colors.cardSurface.withValues(alpha: 0.55),
        border: Border(
          right: BorderSide(color: colors.border.withValues(alpha: 0.35)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                Text(
                  listTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '${entries.length} ${entries.length == 1 ? 'entry' : 'entries'}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: colors.border.withValues(alpha: 0.35)),
          Expanded(
            child: entries.isEmpty
                ? _EmptyListState(
                    message: emptyMessage,
                    subtitle: emptySubtitle,
                    onLogDayPressed: onLogDayPressed,
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.lg,
                    ),
                    itemCount: groupedEntries.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: AppButton(
                            text: 'Log day',
                            icon: Icons.add_rounded,
                            backgroundColor: ModuleColors.trade,
                            width: double.infinity,
                            height: 44,
                            onPressed: onLogDayPressed,
                          ),
                        );
                      }
                      final dateKey =
                          groupedEntries.keys.elementAt(index - 1);
                      final dayEntries = groupedEntries[dateKey]!;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: dayEntries
                            .map(
                              (entry) => JournalEntryItem(
                                entry: entry,
                                isSelected: entry.id == selectedEntryId,
                                onTap: () => onEntrySelected(entry),
                              ),
                            )
                            .toList(),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Map<String, List<JournalEntry>> _groupEntriesByDate(
    List<JournalEntry> entries,
  ) {
    final grouped = <String, List<JournalEntry>>{};
    for (final entry in entries) {
      final dateKey = DateFormat('yyyy-MM-dd').format(entry.entryDate);
      grouped.putIfAbsent(dateKey, () => []).add(entry);
    }
    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
    return {for (final key in sortedKeys) key: grouped[key]!};
  }
}

class _EmptyListState extends StatelessWidget {
  const _EmptyListState({
    required this.message,
    required this.subtitle,
    required this.onLogDayPressed,
  });

  final String message;
  final String subtitle;
  final VoidCallback onLogDayPressed;

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
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: ModuleColors.trade.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.menu_book_outlined,
                size: 30,
                color: ModuleColors.trade.withValues(alpha: 0.85),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
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
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              text: 'Log day',
              icon: Icons.add_rounded,
              backgroundColor: ModuleColors.trade,
              height: 44,
              onPressed: onLogDayPressed,
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;
    final dateStr =
        DateFormat('EEE, MMM dd, yyyy').format(widget.entry.entryDate);
    final title = widget.entry.title.trim().isEmpty
        ? 'Untitled entry'
        : widget.entry.title;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Material(
          color: widget.isSelected
              ? ModuleColors.trade.withValues(alpha: 0.12)
              : _isHovered
                  ? colors.surface.withValues(alpha: 0.55)
                  : colors.surface.withValues(alpha: 0.28),
          borderRadius: AppRadii.card,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: AppRadii.card,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.sm + AppSpacing.xs),
              decoration: BoxDecoration(
                borderRadius: AppRadii.card,
                border: Border.all(
                  color: widget.isSelected
                      ? ModuleColors.trade.withValues(alpha: 0.75)
                      : colors.border.withValues(alpha: 0.3),
                  width: widget.isSelected ? 1.4 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dateStr,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: widget.isSelected
                          ? ModuleColors.trade
                          : colors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (widget.entry.relatedTradeIds.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${widget.entry.relatedTradeIds.length} linked trades',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
