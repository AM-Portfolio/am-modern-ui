import 'package:flutter/material.dart';
import '../../../../internal/domain/entities/journal_entry.dart';

class ExecuteTradeStep extends StatelessWidget {
  final PreTradePlan? preTradePlan;
  final String? tradeId;
  final JournalEntry? entry;

  const ExecuteTradeStep({
    super.key,
    this.preTradePlan,
    this.tradeId,
    this.entry,
  });

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Execute Trade Step'));
  }
}
