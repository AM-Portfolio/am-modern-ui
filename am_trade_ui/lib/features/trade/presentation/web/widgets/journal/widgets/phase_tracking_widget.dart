import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';

import '../utils/journal_field_decoration.dart';
import 'mood_selector.dart';
import 'sentiment_selector.dart';
import 'tags_selector.dart';

/// Widget for tracking behavior, mood, and sentiment for a specific trading phase.
///
/// Theme-only chrome: [context.colors], [AppRadii], [AppSpacing], Trade accent.
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

  Color _accent(BuildContext context) =>
      ModuleColorProvider.maybeOf(context) ?? ModuleColors.trade;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = _accent(context);
    final hasBehavior = behaviorController.text.trim().isNotEmpty;
    final hasMood = mood != null;
    final hasSentiment = sentiment != null;

    // Hide in view mode if all empty
    if (!isEditMode && !hasBehavior && !hasMood && !hasSentiment) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: colors.border.withValues(alpha: 0.4)),
        borderRadius: AppRadii.input,
        color: colors.surface.withValues(alpha: 0.45),
      ),
      padding: const EdgeInsets.all(AppSpacing.sm + AppSpacing.xxs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: AppSpacing.md, color: accent),
              const SizedBox(width: AppSpacing.sm - AppSpacing.xxs),
              Text(
                label,
                style: context.text.label(compact: true).copyWith(
                      fontWeight: FontWeight.w600,
                      color: accent,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (isEditMode || hasBehavior)
            TextFormField(
              controller: behaviorController,
              enabled: isEditMode,
              maxLines: 2,
              minLines: 1,
              style: context.text.body(compact: true).copyWith(
                    color: isEditMode
                        ? colors.textPrimary
                        : colors.textPrimary.withValues(alpha: 0.85),
                  ),
              decoration: JournalFieldDecoration.outlined(
                context,
                hintText: hint,
                dense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm + AppSpacing.xxs,
                  vertical: AppSpacing.sm,
                ),
              ),
            ),
          if (isEditMode || hasBehavior)
            const SizedBox(height: AppSpacing.sm),
          if (isEditMode || hasMood || hasSentiment)
            Row(
              children: [
                if (isEditMode || hasMood)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mood',
                          style: context.text.caption(compact: true).copyWith(
                                color: colors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        IgnorePointer(
                          ignoring: !isEditMode,
                          child: MoodSelector(
                            selectedMood: mood,
                            onMoodSelected: onMoodChanged,
                          ),
                        ),
                      ],
                    ),
                  ),
                if ((isEditMode || hasMood) && (isEditMode || hasSentiment))
                  const SizedBox(width: AppSpacing.sm + AppSpacing.xxs),
                if (isEditMode || hasSentiment)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sentiment',
                          style: context.text.caption(compact: true).copyWith(
                                color: colors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
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
    bool compact = false,
  }) =>
      MoodSelector(
        selectedMood: mood,
        onMoodSelected: onMoodChanged,
        compact: compact,
      );

  /// Static helper to build sentiment selector for use in tab views
  static Widget buildSentimentSelector({
    required String? sentiment,
    required Function(String?) onSentimentChanged,
    required bool isEditMode,
    bool compact = false,
  }) =>
      SentimentSelector(
        selectedSentiment: sentiment,
        onSentimentSelected: onSentimentChanged,
        compact: compact,
      );

  /// Static helper to build tags selector for use in tab views
  static Widget buildTagsSelector({
    required Set<String> selectedTags,
    required Function(String) onTagToggled,
    bool compact = false,
  }) =>
      TagsSelector(
        selectedTags: selectedTags,
        onTagToggled: onTagToggled,
        compact: compact,
      );
}
