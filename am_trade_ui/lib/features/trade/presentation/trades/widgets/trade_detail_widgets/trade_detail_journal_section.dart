import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Journal',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                FilledButton.tonalIcon(
                  onPressed: _openNew,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add journal'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (_error != null)
              Text(_error!)
            else if (_entries.isEmpty)
              const Text('No journal entries linked to this trade yet.')
            else
              ..._entries.map(
                (e) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(e.title),
                  subtitle: Text(e.journalStatus ?? e.entryType ?? ''),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
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
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
