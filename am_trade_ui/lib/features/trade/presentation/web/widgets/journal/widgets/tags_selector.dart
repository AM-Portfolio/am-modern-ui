import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';

import '../models/journal_mood_options.dart';

class TagsSelector extends StatelessWidget {
  const TagsSelector({
    required this.selectedTags,
    required this.onTagToggled,
    super.key,
  });

  final Set<String> selectedTags;
  final ValueChanged<String> onTagToggled;

  @override
  Widget build(BuildContext context) {
    final catalog = JournalMoodOptions.getTags(context);
    final catalogLabels = catalog.map((t) => t['label'] as String).toSet();
    // Keep template-applied tags visible even if not in the static catalog.
    final extras = selectedTags.where((t) => !catalogLabels.contains(t));

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        ...catalog.map((tagData) {
          final tag = tagData['label'] as String;
          final color = tagData['color'] as Color;
          return AmToggleChip(
            label: tag,
            selected: selectedTags.contains(tag),
            compact: true,
            accentColor: color,
            onTap: () => onTagToggled(tag),
          );
        }),
        ...extras.map(
          (tag) => AmToggleChip(
            label: tag,
            selected: true,
            compact: true,
            accentColor: ModuleColors.trade,
            onTap: () => onTagToggled(tag),
          ),
        ),
      ],
    );
  }
}
