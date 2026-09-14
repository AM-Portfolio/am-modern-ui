import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';

import '../models/journal_mood_options.dart';

class MoodSelector extends StatelessWidget {
  const MoodSelector({
    required this.selectedMood,
    required this.onMoodSelected,
    super.key,
  });

  final String? selectedMood;
  final ValueChanged<String> onMoodSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: JournalMoodOptions.getMoods(context).entries.map((entry) {
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
