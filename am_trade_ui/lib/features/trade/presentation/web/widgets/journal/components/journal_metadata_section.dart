import 'package:flutter/material.dart';

import '../widgets/mood_selector.dart';
import '../widgets/sentiment_selector.dart';
import '../widgets/tags_selector.dart';

class JournalMetadataSection extends StatelessWidget {
  const JournalMetadataSection({
    required this.selectedMood,
    required this.marketSentiment,
    required this.selectedTags,
    required this.isEditMode,
    required this.onMoodSelected,
    required this.onSentimentSelected,
    required this.onTagToggled,
    super.key,
  });

  final String? selectedMood;
  final String? marketSentiment;
  final Set<String> selectedTags;
  final bool isEditMode;
  final ValueChanged<String?> onMoodSelected;
  final ValueChanged<String?> onSentimentSelected;
  final ValueChanged<String> onTagToggled;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      IgnorePointer(
        ignoring: !isEditMode,
        child: MoodSelector(selectedMood: selectedMood, onMoodSelected: onMoodSelected),
      ),
      const SizedBox(height: 16),
      IgnorePointer(
        ignoring: !isEditMode,
        child: SentimentSelector(selectedSentiment: marketSentiment, onSentimentSelected: onSentimentSelected),
      ),
      const SizedBox(height: 16),
      IgnorePointer(
        ignoring: !isEditMode,
        child: TagsSelector(selectedTags: selectedTags, onTagToggled: onTagToggled),
      ),
    ],
  );
}
