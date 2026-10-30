import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';

import '../../../../journal/widgets/journal_themed_dropdown.dart';
import '../models/journal_mood_options.dart';

class MoodSelector extends StatelessWidget {
  const MoodSelector({
    required this.selectedMood,
    required this.onMoodSelected,
    this.compact = false,
    super.key,
  });

  final String? selectedMood;
  final ValueChanged<String?> onMoodSelected;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final moods = JournalMoodOptions.getMoods(context);

    if (compact) {
      final theme = Theme.of(context);
      final colors = context.colors;
      // Floating label already says "Mood" — keep hint short for half-width row.
      return JournalThemedDropdown<String>(
        value: selectedMood,
        label: 'Mood',
        floatingLabel: true,
        hint: 'Select',
        compact: true,
        height: AppSpacing.xl + AppSpacing.md,
        fontSize: AppTypeScale.md,
        items: moods.entries.map((entry) {
          final moodData = entry.value;
          return DropdownMenuItem<String>(
            value: entry.key,
            child: Text(
              '${moodData['emoji']} ${moodData['label']}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                    color: moodData['color'] as Color? ?? colors.textPrimary,
                    fontWeight: FontWeight.w500,
                    fontSize: AppTypeScale.md,
                    height: 1.2,
                  ),
            ),
          );
        }).toList(),
        onChanged: onMoodSelected,
      );
    }

    // Web view: original chip wrap
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: moods.entries.map((entry) {
        final moodData = entry.value;
        return AmToggleChip(
          label: '${moodData['emoji']} ${moodData['label']}',
          selected: selectedMood == entry.key,
          compact: true,
          accentColor: moodData['color'] as Color,
          onTap: () => onMoodSelected(entry.key),
        );
      }).toList(),
    );
  }
}
