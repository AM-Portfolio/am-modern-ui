import 'package:flutter/material.dart';

import '../widgets/tags_selector.dart';

/// Section for displaying and managing journal entry tags
class TagsSection extends StatelessWidget {
  const TagsSection({required this.selectedTags, required this.onTagToggled, required this.isEditMode, super.key});

  final Set<String> selectedTags;
  final Function(String) onTagToggled;
  final bool isEditMode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (selectedTags.isEmpty && !isEditMode) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.1),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.label, size: 16, color: theme.colorScheme.primary),
              const SizedBox(width: 6),
              Text(
                'Tags',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          IgnorePointer(
            ignoring: !isEditMode,
            child: TagsSelector(selectedTags: selectedTags, onTagToggled: onTagToggled),
          ),
        ],
      ),
    );
  }
}
