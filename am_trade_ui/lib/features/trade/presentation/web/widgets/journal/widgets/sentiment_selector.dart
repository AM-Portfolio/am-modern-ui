import 'package:flutter/material.dart';

import '../models/journal_mood_options.dart';

class SentimentSelector extends StatelessWidget {
  const SentimentSelector({required this.selectedSentiment, required this.onSentimentSelected, super.key});

  final String? selectedSentiment;
  final ValueChanged<String> onSentimentSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Wrap(
      spacing: 3,
      runSpacing: 3,
      children: JournalMoodOptions.sentiments.entries.map((entry) {
        final isSelected = selectedSentiment == entry.key;
        final sentimentData = entry.value;
        return InkWell(
          onTap: () => onSentimentSelected(entry.key),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: isSelected
                  ? (sentimentData['color'] as Color).withOpacity(0.15)
                  : theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
              border: Border.all(color: isSelected ? sentimentData['color'] as Color : Colors.transparent, width: 1.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  sentimentData['icon'] as IconData,
                  size: 11,
                  color: isSelected ? sentimentData['color'] as Color : theme.colorScheme.onSurface.withOpacity(0.6),
                ),
                const SizedBox(width: 3),
                Text(
                  sentimentData['label'] as String,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected ? sentimentData['color'] as Color : null,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
