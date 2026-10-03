import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:am_design_system/am_design_system.dart';

import '../../../../journal_providers.dart';
import '../../../../internal/domain/entities/journal_entry.dart';
import '../../../journal/pages/trade_journal_workflow_page.dart';

/// Journal entries linked to a specific trade (trade detail panel).
class TradeDetailJournalSection extends ConsumerStatefulWidget {
  const TradeDetailJournalSection({
    super.key,
    required this.tradeId,
    required this.portfolioId,
    this.symbol,
  });

  final String tradeId;
  final String portfolioId;
  final String? symbol;

  @override
  ConsumerState<TradeDetailJournalSection> createState() =>
      _TradeDetailJournalSectionState();
}

class _TradeDetailJournalSectionState
    extends ConsumerState<TradeDetailJournalSection> {
  List<JournalEntry> _entries = [];
  var _loading = true;
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

  Future<void> _openNew() async {
    final cubit = await ref.read(journalCubitProvider.future);
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TradeJournalWorkflowPage(
          journalCubit: cubit,
          portfolioId: widget.portfolioId,
          initialEntry: JournalEntry(
            id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
            userId: '',
            title: widget.symbol ?? 'Trade journal',
            entryDate: DateTime.now(),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            tradeId: widget.tradeId,
            symbol: widget.symbol,
            entryType: 'TRADE_JOURNAL',
            journalStatus: 'PLANNED',
            preTradePlan: const PreTradePlan(),
            tradeExecution: const TradeExecution(),
            postTradeReview: const PostTradeReview(),
          ),
        ),
      ),
    );
    await _load();
  }

  Future<void> _openEntry(JournalEntry e) async {
    final cubit = await ref.read(journalCubitProvider.future);
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TradeJournalWorkflowPage(
          journalCubit: cubit,
          initialEntry: e,
          portfolioId: widget.portfolioId,
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
                    child: SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                : _error != null 
                    ? Text(_error!, style: TextStyle(color: context.colors.statusError, fontSize: 13))
                    : _entries.isEmpty
                        ? Text('No journal entries linked to this trade.', style: TextStyle(color: context.colors.textSecondary, fontSize: 13))
                        : SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: _entries.map((e) => Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: InkWell(
                                  onTap: () => _openEntry(e),
                                  borderRadius: BorderRadius.circular(4),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: context.colors.cardSurface,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: context.colors.border),
                                    ),
                                    child: Text(e.title, style: TextStyle(fontSize: 12, color: context.colors.textPrimary)),
                                  ),
                                ),
                              )).toList(),
                            ),
                          ),
          ),
          const SizedBox(width: 16),
          TextButton.icon(
            onPressed: _openNew,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add Journal', style: TextStyle(fontSize: 12)),
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
