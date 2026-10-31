import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:am_design_system/am_design_system.dart';

import '../../../../journal_providers.dart';
import '../../../../internal/domain/entities/journal_entry.dart';
import '../../../journal/models/journal_folder_filter.dart';
import '../../../journal/pages/trade_journal_workflow_page.dart';
import '../../../journal/utils/hydrate_journal_entry_from_holding.dart';
import '../../../journal/utils/journal_this_trade.dart';
import '../../../models/trade_holding_view_model.dart';

/// Journal entries linked to a specific trade (trade detail panel).
class TradeDetailJournalSection extends ConsumerStatefulWidget {
  const TradeDetailJournalSection({
    super.key,
    required this.tradeId,
    required this.portfolioId,
    this.symbol,
    this.holding,
  });

  final String tradeId;
  final String portfolioId;
  final String? symbol;
  final TradeHoldingViewModel? holding;

  @override
  ConsumerState<TradeDetailJournalSection> createState() =>
      _TradeDetailJournalSectionState();
}

class _TradeDetailJournalSectionState
    extends ConsumerState<TradeDetailJournalSection> {
  List<JournalEntry> _entries = [];
  var _loading = true;
  var _journaling = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant TradeDetailJournalSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tradeId != widget.tradeId) _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = await ref.read(journalRepositoryProvider.future);
      final entries = await repo.getJournalEntriesByTrade(widget.tradeId);
      if (!mounted) return;
      setState(() {
        _entries = entries;
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

  Future<void> _journalThis() async {
    if (_journaling) return;
    setState(() => _journaling = true);
    try {
      final cubit = await ref.read(journalCubitProvider.future);
      if (!mounted) return;
      await openJournalThisTrade(
        context,
        cubit: cubit,
        tradeId: widget.tradeId,
        portfolioId: widget.portfolioId,
        holding: widget.holding,
        onClosed: _load,
      );
    } finally {
      if (mounted) setState(() => _journaling = false);
    }
  }

  Future<void> _openEntry(JournalEntry e) async {
    final cubit = await ref.read(journalCubitProvider.future);
    if (!mounted) return;
    final entry = hydrateJournalEntryFromHolding(e, widget.holding);
    final completed = JournalFolderFilter.isCompletedTradeJournal(entry);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TradeJournalWorkflowPage(
          journalCubit: cubit,
          initialEntry: entry,
          portfolioId: widget.portfolioId,
          initialReadOnly: completed,
          startAtStep: completed ? 2 : null,
        ),
      ),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.colors.border),
      ),
      child: Row(
        children: [
          Icon(Icons.book, size: 18, color: context.colors.textSecondary),
          const SizedBox(width: 8),
          Text(
            'Journal',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: context.colors.textPrimary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _loading
                ? const Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : _error != null
                    ? Text(
                        _error!,
                        style: TextStyle(
                          color: context.colors.statusError,
                          fontSize: 13,
                        ),
                      )
                    : _entries.isEmpty
                        ? Text(
                            'No journal entries linked to this trade.',
                            style: TextStyle(
                              color: context.colors.textSecondary,
                              fontSize: 13,
                            ),
                          )
                        : SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: _entries
                                  .map(
                                    (e) => Padding(
                                      padding: const EdgeInsets.only(right: 8.0),
                                      child: InkWell(
                                        onTap: () => _openEntry(e),
                                        borderRadius: BorderRadius.circular(4),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: context.colors.cardSurface,
                                            borderRadius:
                                                BorderRadius.circular(4),
                                            border: Border.all(
                                              color: context.colors.border,
                                            ),
                                          ),
                                          child: Text(
                                            e.title,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color:
                                                  context.colors.textPrimary,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
          ),
          const SizedBox(width: 16),
          TextButton.icon(
            onPressed: _journaling ? null : _journalThis,
            icon: _journaling
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.menu_book_outlined, size: 16),
            label: const Text('Journal this', style: TextStyle(fontSize: 12)),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: Size.zero,
            ),
          ),
        ],
      ),
    );
  }
}
