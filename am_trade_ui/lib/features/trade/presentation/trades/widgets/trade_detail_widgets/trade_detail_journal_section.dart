import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
        ),
      ),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final status = _loading
        ? SizedBox(
            height: 16,
            width: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: ModuleColors.trade,
            ),
          )
        : _error != null
            ? Text(
                _error!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.statusError,
                    ),
              )
            : _entries.isEmpty
                ? Text(
                    'No journal entries linked to this trade.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: context.textSecondary,
                        ),
                  )
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _entries
                          .map(
                            (e) => Padding(
                              padding: const EdgeInsets.only(
                                right: AppSpacing.sm,
                              ),
                              child: InkWell(
                                onTap: () => _openEntry(e),
                                borderRadius: BorderRadius.circular(
                                  AppRadii.xs,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.sm + 2,
                                    vertical: AppSpacing.xs,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colors.cardSurface,
                                    borderRadius: BorderRadius.circular(
                                      AppRadii.xs,
                                    ),
                                    border: Border.all(
                                      color: colors.border,
                                    ),
                                  ),
                                  child: Text(
                                    e.title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(
                                          color: colors.textPrimary,
                                        ),
                                  ),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + AppSpacing.xs,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppRadii.card,
        border: Border.all(color: colors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.book, size: 16, color: context.textSecondary),
          const SizedBox(width: AppSpacing.xs + 2),
          Text(
            'Journal',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: status),
          const SizedBox(width: AppSpacing.sm),
          AppButton(
            text: 'Journal this',
            icon: Icons.menu_book_outlined,
            isOutlined: true,
            textColor: ModuleColors.trade,
            height: 30,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            onPressed: _journaling ? null : _journalThis,
            isLoading: _journaling,
          ),
        ],
      ),
    );
  }
}
