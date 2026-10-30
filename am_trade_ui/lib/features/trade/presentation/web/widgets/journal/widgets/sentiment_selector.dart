import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';

import '../../../../journal/widgets/journal_themed_dropdown.dart';
import '../models/journal_mood_options.dart';

class SentimentSelector extends StatelessWidget {
  const SentimentSelector({
    required this.selectedSentiment,
    required this.onSentimentSelected,
    this.compact = false,
    super.key,
  });

  final String? selectedSentiment;
  final ValueChanged<String?> onSentimentSelected;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sentiments = JournalMoodOptions.getSentiments(context);

    if (compact) {
      final colors = context.colors;
      // Floating label already says "Sentiment" — keep hint short for half-width row.
      return JournalThemedDropdown<String>(
        value: selectedSentiment,
        label: 'Sentiment',
        floatingLabel: true,
        hint: 'Select',
        compact: true,
        height: AppSpacing.xl + AppSpacing.md,
        fontSize: AppTypeScale.md,
        items: sentiments.entries.map((entry) {
          final data = entry.value;
          return DropdownMenuItem<String>(
            value: entry.key,
            child: Row(
              children: [
                Icon(
                  data['icon'] as IconData,
                  size: AppSpacing.md - AppSpacing.xxs,
                  color: data['color'] as Color? ?? colors.textSecondary,
                ),
                const SizedBox(width: AppSpacing.sm - AppSpacing.xxs),
                Flexible(
                  child: Text(
                    data['label'] as String,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: data['color'] as Color? ?? colors.textPrimary,
                      fontWeight: FontWeight.w500,
                      fontSize: AppTypeScale.md,
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        onChanged: onSentimentSelected,
      );
    }

    // Web view: original horizontal chip wrap
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
