import 'package:flutter/material.dart';
import '../../../../internal/domain/entities/journal_entry.dart';

class JournalTradeHeader extends StatelessWidget {
  final JournalEntry? entry;
  final String? tradeId;

  const JournalTradeHeader({
    super.key,
    this.entry,
    this.tradeId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: const Text('Journal Trade Header'),
    );
  }
}
