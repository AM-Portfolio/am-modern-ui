import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';

import '../models/journal_mood_options.dart';

class SentimentSelector extends StatelessWidget {
  const SentimentSelector({
    required this.selectedSentiment,
    required this.onSentimentSelected,
    super.key,
  });

  final String? selectedSentiment;
  final ValueChanged<String> onSentimentSelected;

  @override
  Widget build(BuildContext context) {
    final sentiments = JournalMoodOptions.getSentiments(context);

    // Prefer AmToggleChip for null-safe multi-select chrome consistent with mood/tags.
    // PillSelector requires a non-null selectedItem.
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: sentiments.entries.map((entry) {
        final data = entry.value;
        return AmToggleChip(
          label: data['label'] as String,
          selected: selectedSentiment == entry.key,
          compact: true,
          accentColor: data['color'] as Color,
          onTap: () => onSentimentSelected(entry.key),
        );
      }).toList(),
    );
  }
}
