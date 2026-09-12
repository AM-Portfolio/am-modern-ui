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

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const SizedBox(width: 40),
              _header(context, 'Symbol / Date', flex: 3),
              _header(context, 'Type', flex: 1),
              _header(context, 'Setup', flex: 2),
              _header(context, 'Status', flex: 2),
              _header(context, 'R', flex: 1),
              _header(context, 'P&L', flex: 2),
              const SizedBox(width: 40),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: entries.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final entry = entries[index];
              final pnl = entry.postTradeReview?.actualPnl;
              final r = entry.postTradeReview?.actualRMultiple;
              final selected = selectedIds.contains(entry.id);
              final direction = (entry.tradeDirection ?? '').toUpperCase();

              return InkWell(
                onTap: () => onRowTap(entry),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 40,
                        child: Checkbox(
                          value: selected,
                          onChanged: onSelectionChanged == null
                              ? null
                              : (v) {
                                  final next = {...selectedIds};
                                  if (v == true) {
                                    next.add(entry.id);
                                  } else {
                                    next.remove(entry.id);
                                  }
                                  onSelectionChanged!(next);
                                },
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.symbol ?? entry.title,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              DateFormat('dd MMM yyyy').format(entry.entryDate),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Text(
                          direction.isEmpty ? '—' : direction,
                          style: TextStyle(
                            color: direction == 'SHORT'
                                ? context.statusError
                                : direction == 'LONG'
                                    ? context.statusSuccess
                                    : null,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(entry.setup ?? entry.preTradePlan?.setup ?? '—'),
                      ),
                      Expanded(
                        flex: 2,
                        child: _statusBadge(
                          context,
                          entry.journalStatus ?? 'DRAFT',
                        ),
                      ),
                      Expanded(
                        child: Text(
                          r == null ? '—' : '${r >= 0 ? '+' : ''}${r.toStringAsFixed(2)}R',
                          style: TextStyle(
                            color: r == null
                                ? null
                                : r >= 0
                                    ? context.statusSuccess
                                    : context.statusError,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          pnl == null ? '—' : pnlFmt.format(pnl),
                          style: TextStyle(
                            color: pnl == null
                                ? null
                                : pnl >= 0
                                    ? context.statusSuccess
                                    : context.statusError,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'archive') onArchive?.call(entry);
                          if (value == 'delete') onDelete?.call(entry);
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'archive', child: Text('Archive')),
                          PopupMenuItem(value: 'delete', child: Text('Delete')),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _header(BuildContext context, String label, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
      ),
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
          borderRadius: BorderRadius.circular(12),
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
