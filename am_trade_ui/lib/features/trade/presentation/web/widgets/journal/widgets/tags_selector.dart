import 'package:flutter/material.dart';

import '../models/journal_mood_options.dart';

class TagsSelector extends StatelessWidget {
  const TagsSelector({required this.selectedTags, required this.onTagToggled, super.key});

  final Set<String> selectedTags;
  final ValueChanged<String> onTagToggled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Wrap(
      spacing: 3,
      runSpacing: 3,
      children: JournalMoodOptions.tags.map((tagData) {
        final tag = tagData['label'] as String;
        final color = tagData['color'] as Color;
        final isSelected = selectedTags.contains(tag);
        return InkWell(
          onTap: () => onTagToggled(tag),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: isSelected ? color.withOpacity(0.15) : theme.colorScheme.surfaceContainerHighest.withOpacity(0.8),
              border: Border.all(
                color: isSelected ? color : theme.colorScheme.outline.withOpacity(0.3),
                width: isSelected ? 1.5 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSelected)
                  Padding(
                    padding: const EdgeInsets.only(right: 2),
                    child: Icon(Icons.check, size: 9, color: color),
                  ),
                Text(
                  tag,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? color : theme.colorScheme.onSurface.withOpacity(0.75),
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
