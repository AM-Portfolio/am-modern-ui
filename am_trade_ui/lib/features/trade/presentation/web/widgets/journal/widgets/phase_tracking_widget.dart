import 'package:flutter/material.dart';

import 'mood_selector.dart';
import 'sentiment_selector.dart';
import 'tags_selector.dart';

/// Widget for tracking behavior, mood, and sentiment for a specific trading phase
class PhaseTrackingWidget extends StatelessWidget {
  const PhaseTrackingWidget({
    required this.label,
    required this.icon,
    required this.behaviorController,
    required this.mood,
    required this.sentiment,
    required this.hint,
    required this.onMoodChanged,
    required this.onSentimentChanged,
    required this.isEditMode,
    super.key,
  });

  final String label;
  final IconData icon;
  final TextEditingController behaviorController;
  final String? mood;
  final String? sentiment;
  final String hint;
  final Function(String?) onMoodChanged;
  final Function(String?) onSentimentChanged;
  final bool isEditMode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasBehavior = behaviorController.text.trim().isNotEmpty;
    final hasMood = mood != null;
    final hasSentiment = sentiment != null;

    // Hide in view mode if all empty
    if (!isEditMode && !hasBehavior && !hasMood && !hasSentiment) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(10),
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Phase header with icon and label
          Row(
            children: [
              Icon(icon, size: 14, color: theme.colorScheme.primary),
              const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Behavior notes
          if (isEditMode || hasBehavior)
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: hasBehavior ? theme.colorScheme.primary.withOpacity(0.3) : theme.dividerColor.withOpacity(0.2),
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextFormField(
                controller: behaviorController,
                enabled: isEditMode,
                maxLines: 2,
                minLines: 1,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 12,
                  color: isEditMode ? null : theme.colorScheme.onSurface.withOpacity(0.85),
                ),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  isDense: true,
                ),
              ),
            ),

          if (isEditMode || hasBehavior) const SizedBox(height: 8),

          // Mood and Sentiment in a row
          if (isEditMode || hasMood || hasSentiment)
            Row(
              children: [
                // Mood selector
                if (isEditMode || hasMood)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mood',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 10,
                            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: 4),
                        IgnorePointer(
                          ignoring: !isEditMode,
                          child: MoodSelector(selectedMood: mood, onMoodSelected: onMoodChanged),
                        ),
                      ],
                    ),
                  ),

                if ((isEditMode || hasMood) && (isEditMode || hasSentiment)) const SizedBox(width: 10),

                // Sentiment selector
                if (isEditMode || hasSentiment)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sentiment',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 10,
                            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: 4),
                        IgnorePointer(
                          ignoring: !isEditMode,
                          child: SentimentSelector(
                            selectedSentiment: sentiment,
                            onSentimentSelected: onSentimentChanged,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  /// Static helper to build mood selector for use in tab views
  static Widget buildMoodSelector({
    required String? mood,
    required Function(String?) onMoodChanged,
    required bool isEditMode,
  }) => MoodSelector(selectedMood: mood, onMoodSelected: onMoodChanged);

  /// Static helper to build sentiment selector for use in tab views
  static Widget buildSentimentSelector({
    required String? sentiment,
    required Function(String?) onSentimentChanged,
    required bool isEditMode,
  }) => SentimentSelector(selectedSentiment: sentiment, onSentimentSelected: onSentimentChanged);

  /// Static helper to build tags selector for use in tab views
  static Widget buildTagsSelector({required Set<String> selectedTags, required Function(String) onTagToggled}) =>
      TagsSelector(selectedTags: selectedTags, onTagToggled: onTagToggled);
}
