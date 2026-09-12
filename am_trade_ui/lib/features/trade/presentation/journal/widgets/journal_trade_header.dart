import 'package:flutter/material.dart';
import '../../../internal/domain/entities/journal_entry.dart';

class JournalTradeHeader extends StatelessWidget {
  const JournalTradeHeader({
    super.key,
    required this.entry,
  });

  final JournalEntry entry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Text(
                  entry.symbol?.substring(0, 1) ?? 'T',
                  style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.symbol ?? 'New Trade',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    entry.setup ?? 'No Setup Selected',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getStatusColor(context, entry.journalStatus).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _getStatusColor(context, entry.journalStatus)),
            ),
            child: Text(
              entry.journalStatus ?? 'OPEN',
              style: TextStyle(
                color: _getStatusColor(context, entry.journalStatus),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(BuildContext context, String? status) {
    switch (status) {
      case 'PLANNED':
        return Colors.blue;
      case 'OPEN':
        return Colors.orange;
      case 'COMPLETED':
        return Colors.green;
      case 'ARCHIVED':
        return Colors.grey;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }
}
