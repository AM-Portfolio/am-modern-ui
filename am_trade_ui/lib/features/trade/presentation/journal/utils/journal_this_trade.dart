import 'package:flutter/material.dart';

import '../../../internal/domain/entities/journal_entry.dart';
import '../../cubit/journal/journal_cubit.dart';
import '../../models/trade_holding_view_model.dart';
import '../models/journal_folder_filter.dart';
import '../pages/trade_journal_workflow_page.dart';
import 'hydrate_journal_entry_from_holding.dart';

/// Lookup or create a durable trade journal stub, then hydrate from [holding].
Future<JournalEntry> journalThisTrade({
  required JournalCubit cubit,
  required String tradeId,
  String? portfolioId,
  TradeHoldingViewModel? holding,
}) async {
  final existing =
      await cubit.repository.getJournalEntriesByTrade(tradeId);

  late JournalEntry entry;
  if (existing.isNotEmpty) {
    entry = _preferEntry(existing);
  } else {
    final created = await cubit.createFromTrades(
      [tradeId],
      portfolioId: portfolioId ?? holding?.portfolioId,
    );
    if (created.isEmpty) {
      throw StateError('createFromTrades returned no journal for $tradeId');
    }
    entry = created.first;
  }

  return hydrateJournalEntryFromHolding(entry, holding);
}

JournalEntry _preferEntry(List<JournalEntry> entries) {
  JournalEntry newestOf(Iterable<JournalEntry> list) {
    return list.reduce(
      (a, b) => a.updatedAt.isAfter(b.updatedAt) ? a : b,
    );
  }

  final completed = entries
      .where(JournalFolderFilter.isCompletedTradeJournal)
      .toList();
  if (completed.isNotEmpty) return newestOf(completed);

  final openOrDraft = entries.where((e) {
    final s = (e.journalStatus ?? '').toUpperCase();
    return s != 'COMPLETED' && s != 'ARCHIVED';
  }).toList();
  if (openOrDraft.isNotEmpty) return newestOf(openOrDraft);

  return newestOf(entries);
}

/// Creates/opens journal for [tradeId] and navigates to the workflow template
/// (read-only when completed until Edit).
Future<JournalEntry?> openJournalThisTrade(
  BuildContext context, {
  required JournalCubit cubit,
  required String tradeId,
  String? portfolioId,
  TradeHoldingViewModel? holding,
  VoidCallback? onClosed,
}) async {
  try {
    final entry = await journalThisTrade(
      cubit: cubit,
      tradeId: tradeId,
      portfolioId: portfolioId,
      holding: holding,
    );
    if (!context.mounted) return entry;

    final resolvedPortfolio =
        portfolioId ?? holding?.portfolioId ?? entry.portfolioId;
    final completed = JournalFolderFilter.isCompletedTradeJournal(entry);

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TradeJournalWorkflowPage(
          journalCubit: cubit,
          initialEntry: entry,
          portfolioId: resolvedPortfolio,
          initialReadOnly: completed,
          startAtStep: completed ? 2 : null,
        ),
      ),
    );
    onClosed?.call();
    return entry;
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open journal: $e')),
      );
    }
    return null;
  }
}
