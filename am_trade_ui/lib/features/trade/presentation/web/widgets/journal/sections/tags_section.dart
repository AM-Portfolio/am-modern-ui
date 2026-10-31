import 'package:am_design_system/am_design_system.dart';
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
    final colors = context.colors;
    final accent = ModuleColorProvider.maybeOf(context) ?? ModuleColors.trade;

    if (selectedTags.isEmpty && !isEditMode) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: colors.divider),
        borderRadius: BorderRadius.circular(12),
        color: colors.cardSurface.withValues(alpha: 0.08),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.label, size: 16, color: accent),
              const SizedBox(width: 6),
              Text(
                'Tags',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: accent,
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
