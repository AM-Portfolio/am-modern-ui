import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../internal/data/dtos/journal_entry_dto.dart';
import '../../../internal/domain/entities/journal_entry.dart';
import '../../cubit/journal/journal_cubit.dart';
import '../../cubit/journal/journal_state.dart';
import '../widgets/journal_data_table.dart';
import '../widgets/journal_metrics_header.dart';
import 'trade_journal_workflow_page.dart';
import 'simple_journal_note_page.dart';
import '../widgets/journal_import_dialog.dart';

class TradeJournalListPage extends ConsumerStatefulWidget {
  const TradeJournalListPage({
    super.key,
    required this.journalCubit,
    this.portfolioId,
  });

  final JournalCubit journalCubit;
  final String? portfolioId;

  @override
  ConsumerState<TradeJournalListPage> createState() =>
      _TradeJournalListPageState();
}

class _TradeJournalListPageState extends ConsumerState<TradeJournalListPage> {
  final _searchController = TextEditingController();
  Set<String> _selectedIds = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openWorkflow({JournalEntry? entry, String? entryType}) {
    if (entryType == 'DAILY' || entryType == 'MISSED') {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => SimpleJournalNotePage(
            journalCubit: widget.journalCubit,
            entryType: entryType!,
            initialEntry: entry,
          ),
        ),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TradeJournalWorkflowPage(
          journalCubit: widget.journalCubit,
          initialEntry: entry,
          portfolioId: widget.portfolioId,
        ),
      ),
    );
  }

  Future<void> _export() async {
    try {
      final csv = await widget.journalCubit.exportCsv();
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Export CSV'),
          content: SizedBox(
            width: 560,
            height: 360,
            child: SingleChildScrollView(child: SelectableText(csv)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<JournalCubit, JournalState>(
      bloc: widget.journalCubit,
      builder: (context, state) {
        List<JournalEntry> entries = [];
        JournalSummaryDto? summary;
        var isLoading = false;
        var statusFilter = 'ALL';
        String? error;

        state.maybeWhen(
          loaded: (loadedEntries, s, status, folder, tags, q, setup) {
            entries = loadedEntries;
            summary = s;
            statusFilter = status.isEmpty ? 'ALL' : status;
            if (_searchController.text != q) {
              _searchController.text = q;
            }
          },
          loading: () => isLoading = true,
          error: (msg) => error = msg,
          orElse: () {},
        );

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: Column(
            children: [
              JournalMetricsHeader(summary: summary),
              _buildToolbar(context, statusFilter, summary),
              if (_selectedIds.isNotEmpty) _buildBulkBar(context),
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : error != null
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(error!),
                                const SizedBox(height: 12),
                                FilledButton(
                                  onPressed: widget.journalCubit.loadJournalEntries,
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          )
                        : entries.isEmpty
                            ? const Center(
                                child: Text('No journal entries found.'),
                              )
                            : JournalDataTable(
                                entries: entries,
                                selectedIds: _selectedIds,
                                onSelectionChanged: (ids) =>
                                    setState(() => _selectedIds = ids),
                                onRowTap: (entry) => _openWorkflow(entry: entry),
                                onArchive: (e) =>
                                    widget.journalCubit.bulkArchive([e.id]),
                                onDelete: (e) =>
                                    widget.journalCubit.removeJournalEntry(e.id),
                              ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBulkBar(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Text('${_selectedIds.length} selected'),
            const Spacer(),
            TextButton(
              onPressed: () async {
                await widget.journalCubit.bulkArchive(_selectedIds.toList());
                setState(() => _selectedIds = {});
              },
              child: const Text('Archive'),
            ),
            TextButton(
              onPressed: () async {
                await widget.journalCubit.bulkDelete(_selectedIds.toList());
                setState(() => _selectedIds = {});
              },
              child: const Text('Delete'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbar(
    BuildContext context,
    String statusFilter,
    JournalSummaryDto? summary,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SegmentedButton<String>(
            segments: [
              const ButtonSegment(value: 'ALL', label: Text('All')),
              ButtonSegment(
                value: 'PLANNED',
                label: Text('Planned (${summary?.plannedCount ?? 0})'),
              ),
              ButtonSegment(
                value: 'OPEN',
                label: Text('Open (${summary?.openCount ?? 0})'),
              ),
              ButtonSegment(
                value: 'COMPLETED',
                label: Text('Completed (${summary?.completedCount ?? 0})'),
              ),
              ButtonSegment(
                value: 'ARCHIVED',
                label: Text('Archived (${summary?.archivedCount ?? 0})'),
              ),
            ],
            selected: {statusFilter},
            onSelectionChanged: (s) {
              widget.journalCubit.setFilters(status: s.first);
            },
          ),
          SizedBox(
            width: 220,
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search symbol, setup, notes…',
                prefixIcon: Icon(Icons.search, size: 18),
                isDense: true,
                border: OutlineInputBorder(),
              ),
              onSubmitted: (q) => widget.journalCubit.setFilters(searchQuery: q),
            ),
          ),
          OutlinedButton.icon(
            onPressed: () async {
              await showDialog<void>(
                context: context,
                builder: (_) => JournalImportDialog(
                  journalCubit: widget.journalCubit,
                ),
              );
            },
            icon: const Icon(Icons.upload_file),
            label: const Text('Import'),
          ),
          OutlinedButton.icon(
            onPressed: _export,
            icon: const Icon(Icons.download),
            label: const Text('Export'),
          ),
          MenuAnchor(
            builder: (context, controller, child) {
              return FilledButton.icon(
                onPressed: () {
                  if (controller.isOpen) {
                    controller.close();
                  } else {
                    controller.open();
                  }
                },
                icon: const Icon(Icons.add),
                label: const Text('New Journal'),
              );
            },
            menuChildren: [
              MenuItemButton(
                onPressed: () => _openWorkflow(entryType: 'TRADE_JOURNAL'),
                child: const Text('Trade Journal'),
              ),
              MenuItemButton(
                onPressed: () => _openWorkflow(entryType: 'DAILY'),
                child: const Text('Daily Note'),
              ),
              MenuItemButton(
                onPressed: () => _openWorkflow(entryType: 'MISSED'),
                child: const Text('Missed Trade'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
