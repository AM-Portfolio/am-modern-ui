import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../internal/domain/entities/journal_entry.dart';

class JournalDataTable extends StatelessWidget {
  const JournalDataTable({
    super.key,
    required this.entries,
    required this.onRowTap,
    this.selectedIds = const {},
    this.onSelectionChanged,
    this.onArchive,
    this.onDelete,
  });

  final List<JournalEntry> entries;
  final void Function(JournalEntry) onRowTap;
  final Set<String> selectedIds;
  final void Function(Set<String>)? onSelectionChanged;
  final void Function(JournalEntry)? onArchive;
  final void Function(JournalEntry)? onDelete;

  @override
  Widget build(BuildContext context) {
    final pnlFmt = NumberFormat.currency(symbol: '₹ ', decimalDigits: 0);
    final colors = context.colors;

    if (entries.isEmpty) {
      return Center(
        child: Text(
          'No journal entries',
          style: context.text.bodyMuted(compact: true).copyWith(
                color: colors.textSecondary,
              ),
        ),
      );
    }

    return SortableTable<JournalEntry>(
      items: entries,
      initialSortColumnIndex: 0,
      initialSortDirection: SortDirection.descending,
      onItemTap: onRowTap,
      headerTextStyle: context.text.caption(compact: true).copyWith(
            color: colors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
      columns: [
        if (onSelectionChanged != null)
          SortableColumn<JournalEntry>(
            title: '',
            flex: 1,
            builder: (entry) {
              final selected = selectedIds.contains(entry.id);
              return Checkbox(
                value: selected,
                activeColor: ModuleColors.trade,
                onChanged: (v) {
                  final next = {...selectedIds};
                  if (v == true) {
                    next.add(entry.id);
                  } else {
                    next.remove(entry.id);
                  }
                  onSelectionChanged!(next);
                },
              );
            },
          ),
        SortableColumn<JournalEntry>(
          title: 'Symbol / Date',
          flex: 3,
          sortBy: (e) => e.entryDate,
          builder: (entry) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                entry.symbol ?? entry.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                DateFormat('dd MMM yyyy').format(entry.entryDate),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.textSecondary,
                    ),
              ),
            ],
          ),
        ),
        SortableColumn<JournalEntry>(
          title: 'Type',
          flex: 1,
          sortBy: (e) => e.tradeDirection ?? '',
          builder: (entry) {
            final direction = (entry.tradeDirection ?? '').toUpperCase();
            return Text(
              direction.isEmpty ? '—' : direction,
              style: TextStyle(
                color: direction == 'SHORT'
                    ? context.statusError
                    : direction == 'LONG'
                        ? context.statusSuccess
                        : colors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            );
          },
        ),
        SortableColumn<JournalEntry>(
          title: 'Setup',
          flex: 2,
          sortBy: (e) => e.setup ?? e.preTradePlan?.setup ?? '',
          builder: (entry) => Text(
            entry.setup ?? entry.preTradePlan?.setup ?? '—',
            style: TextStyle(color: colors.textPrimary),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        SortableColumn<JournalEntry>(
          title: 'Status',
          flex: 2,
          sortBy: (e) => e.journalStatus ?? 'DRAFT',
          builder: (entry) =>
              _statusBadge(context, entry.journalStatus ?? 'DRAFT'),
        ),
        SortableColumn<JournalEntry>(
          title: 'R',
          flex: 1,
          sortBy: (e) => e.postTradeReview?.actualRMultiple,
          textAlign: TextAlign.end,
          builder: (entry) {
            final r = entry.postTradeReview?.actualRMultiple;
            return Text(
              r == null ? '—' : '${r >= 0 ? '+' : ''}${r.toStringAsFixed(2)}R',
              textAlign: TextAlign.end,
              style: TextStyle(
                color: r == null
                    ? colors.textSecondary
                    : r >= 0
                        ? context.statusSuccess
                        : context.statusError,
                fontWeight: FontWeight.bold,
              ),
            );
          },
        ),
        SortableColumn<JournalEntry>(
          title: 'P&L',
          flex: 2,
          sortBy: (e) => e.postTradeReview?.actualPnl,
          textAlign: TextAlign.end,
          builder: (entry) {
            final pnl = entry.postTradeReview?.actualPnl;
            return Text(
              pnl == null ? '—' : pnlFmt.format(pnl),
              textAlign: TextAlign.end,
              style: TextStyle(
                color: pnl == null
                    ? colors.textSecondary
                    : pnl >= 0
                        ? context.statusSuccess
                        : context.statusError,
                fontWeight: FontWeight.bold,
              ),
            );
          },
        ),
        SortableColumn<JournalEntry>(
          title: '',
          flex: 1,
          builder: (entry) => Align(
            alignment: Alignment.centerRight,
            child: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'archive') onArchive?.call(entry);
                if (value == 'delete') onDelete?.call(entry);
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'archive', child: Text('Archive')),
                PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _statusBadge(BuildContext context, String status) {
    final color = switch (status.toUpperCase()) {
      'OPEN' => context.statusInfo,
      'COMPLETED' => context.statusSuccess,
      'PLANNED' => context.statusWarning,
      'ARCHIVED' => context.statusNeutral,
      'DRAFT' => ModuleColors.trade,
      'MISSED' => context.statusError,
      _ => context.statusNeutral,
    };

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: AppRadii.chip,
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Text(
          status,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
        ),
      ),
    );
  }
}
