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
    this.onTradeJournalPressed,
    this.listTitle = 'Log day',
    this.emptyMessage = 'No journal entries yet.\nTap Log Day to start.',
  });

  final List<JournalEntry> entries;
  final String? selectedEntryId;
  final ValueChanged<JournalEntry> onEntrySelected;
  final VoidCallback onLogDayPressed;
  final VoidCallback? onTradeJournalPressed;
  final String listTitle;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;
    final groupedEntries = _groupEntriesByDate(entries);

    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: colors.cardSurface,
        border: Border(
          right: BorderSide(color: colors.border.withValues(alpha: 0.35)),
          left: BorderSide(color: colors.border.withValues(alpha: 0.35)),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Icon(
                  Icons.note_add_outlined,
                  size: 20,
                  color: ModuleColors.trade,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    listTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: colors.border.withValues(alpha: 0.35)),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                AppButton(
                  text: 'Log Day',
                  icon: Icons.add_rounded,
                  backgroundColor: ModuleColors.trade,
                  width: double.infinity,
                  height: 44,
                  onPressed: onLogDayPressed,
                ),
                if (onTradeJournalPressed != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  AppButton(
                    text: 'Trade journal',
                    icon: Icons.candlestick_chart_outlined,
                    type: AppButtonType.secondary,
                    isOutlined: true,
                    width: double.infinity,
                    height: 40,
                    onPressed: onTradeJournalPressed,
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              children: [
                Text(
                  '${entries.length} entries',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.sort,
                  size: 18,
                  color: colors.textSecondary,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: entries.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Text(
                        emptyMessage,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    itemCount: groupedEntries.length,
                    itemBuilder: (context, index) {
                      final dateKey = groupedEntries.keys.elementAt(index);
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
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
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
