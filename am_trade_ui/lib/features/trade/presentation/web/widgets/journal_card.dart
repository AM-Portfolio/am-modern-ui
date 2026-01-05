import 'package:flutter/material.dart';

import '../../../internal/domain/entities/journal_entry.dart';
import 'journal/models/journal_mood_options.dart';
import 'journal/utils/journal_helpers.dart';

class JournalCard extends StatefulWidget {
  const JournalCard({
    required this.entry,
    required this.onTap,
    required this.onDelete,
    required this.extractPlainText,
    required this.limitToWords,
    super.key,
  });

  final JournalEntry entry;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final String Function(String) extractPlainText;
  final String Function(String, int) limitToWords;

  @override
  State<JournalCard> createState() => _JournalCardState();
}

class _JournalCardState extends State<JournalCard> with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(duration: const Duration(milliseconds: 200), vsync: this);
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entry = widget.entry;

    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _hoverController.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _hoverController.reverse();
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _hoverController,
          builder: (context, child) => Transform.scale(
            scale: 1.0 + (0.02 * _hoverController.value),
            child: Card(
              elevation: 2 + (6 * _hoverController.value),
              shadowColor: theme.colorScheme.primary.withOpacity(0.3 * _hoverController.value),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: theme.colorScheme.primary.withOpacity(0.1 + (0.3 * _hoverController.value)),
                  width: 1.5,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.surface,
                      theme.colorScheme.surfaceContainerHighest.withOpacity(0.2 + (0.3 * _hoverController.value)),
                    ],
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header with date and metadata
                      Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 12), child: _buildHeader(theme)),
                      Divider(height: 1, color: theme.dividerColor.withOpacity(0.2)),

                      // Main content
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTitle(theme),
                            const SizedBox(height: 12),
                            _buildContent(theme),
                            if (_hasMoodOrSentiment()) ...[const SizedBox(height: 12), _buildMoodAndSentiment(theme)],
                            if (_hasWatchlistItems()) ...[const SizedBox(height: 12), _buildWatchlistSection(theme)],
                            if (_hasReflectionItems()) ...[const SizedBox(height: 12), _buildReflectionSection(theme)],
                            if (_hasTags()) ...[const SizedBox(height: 12), _buildTags(theme)],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool _hasMoodOrSentiment() {
    if (widget.entry.behaviorPatternSummaries.isEmpty) return false;
    final firstPattern = widget.entry.behaviorPatternSummaries.first;
    return firstPattern.mood != null || firstPattern.marketSentiment != null;
  }

  bool _hasTags() {
    if (widget.entry.behaviorPatternSummaries.isEmpty) return false;
    return widget.entry.behaviorPatternSummaries.any((pattern) => pattern.tags.isNotEmpty);
  }

  bool _hasWatchlistItems() =>
      widget.entry.customFields.containsKey('watchlist') &&
      (widget.entry.customFields['watchlist'] as List?)?.isNotEmpty == true;

  bool _hasReflectionItems() =>
      widget.entry.customFields.containsKey('reflection') &&
      (widget.entry.customFields['reflection'] as String?)?.isNotEmpty == true;

  Widget _buildHeader(ThemeData theme) {
    final entry = widget.entry;
    final attachmentCount = entry.attachments.isNotEmpty ? entry.attachments.length : entry.imageUrls.length;
    final hasBehaviorTracking =
        entry.customFields.containsKey('startBehavior') ||
        entry.customFields.containsKey('midBehavior') ||
        entry.customFields.containsKey('endBehavior');

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            entry.entryDate.toString().split(' ')[0],
            style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(width: 8),
        if (entry.relatedTradeIds.isNotEmpty) ...[
          _buildMetadataChip(
            theme,
            icon: Icons.analytics_outlined,
            label: '${entry.relatedTradeIds.length} Trades',
            color: theme.colorScheme.secondary,
          ),
          const SizedBox(width: 6),
        ],
        if (attachmentCount > 0) ...[
          _buildMetadataChip(
            theme,
            icon: Icons.attach_file,
            label: '$attachmentCount',
            color: theme.colorScheme.tertiary,
          ),
          const SizedBox(width: 6),
        ],
        if (hasBehaviorTracking) ...[
          _buildMetadataChip(theme, icon: Icons.psychology, label: 'Behavior', color: theme.colorScheme.primary),
        ],
        const Spacer(),
        IconButton(
          icon: Icon(
            Icons.delete_outline,
            size: 18,
            color: _isHovered ? theme.colorScheme.error : theme.colorScheme.error.withOpacity(0.5),
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: widget.onDelete,
        ),
      ],
    );
  }

  Widget _buildTitle(ThemeData theme) => Text(
    widget.entry.title,
    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.3),
    maxLines: 2,
    overflow: TextOverflow.ellipsis,
  );

  Widget _buildContent(ThemeData theme) => Text(
    widget.limitToWords(widget.extractPlainText(widget.entry.content), 25),
    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.7), height: 1.5),
    maxLines: 3,
    overflow: TextOverflow.ellipsis,
  );

  Widget _buildMoodAndSentiment(ThemeData theme) {
    if (widget.entry.behaviorPatternSummaries.isEmpty) return const SizedBox.shrink();
    final firstPattern = widget.entry.behaviorPatternSummaries.first;

    return Row(
      children: [
        if (firstPattern.mood != null) _buildMoodChip(firstPattern.mood!),
        if (firstPattern.mood != null && firstPattern.marketSentiment != null) const SizedBox(width: 6),
        if (firstPattern.marketSentiment != null)
          _buildSentimentChip(JournalHelpers.mapSentimentFromValue(firstPattern.marketSentiment) ?? 'neutral'),
      ],
    );
  }

  Widget _buildWatchlistSection(ThemeData theme) {
    final watchlist = widget.entry.customFields['watchlist'] as List? ?? [];
    if (watchlist.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.secondary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.visibility, size: 14, color: theme.colorScheme.secondary),
              const SizedBox(width: 6),
              Text(
                'Pre-Market Watchlist',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...watchlist
              .take(2)
              .map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '• ${item.toString()}',
                    style: theme.textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildReflectionSection(ThemeData theme) {
    final reflection = widget.entry.customFields['reflection'] as String? ?? '';
    if (reflection.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.tertiary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, size: 14, color: theme.colorScheme.tertiary),
              const SizedBox(width: 6),
              Text(
                'Post-Session Thoughts',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.tertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(reflection, style: theme.textTheme.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildMoodChip(String mood) {
    var moodData = JournalMoodOptions.moods[mood];

    if (moodData == null) {
      final moodKey = JournalHelpers.mapMoodFromEntry(mood);
      if (moodKey != null) {
        moodData = JournalMoodOptions.moods[moodKey];
      }
    }

    if (moodData == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: (moodData['color'] as Color).withOpacity(0.15),
        border: Border.all(color: moodData['color'] as Color, width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '${moodData['emoji']} ${moodData['label']}',
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: moodData['color'] as Color),
      ),
    );
  }

  Widget _buildSentimentChip(String sentiment) {
    final sentimentData = JournalMoodOptions.sentiments[sentiment];
    if (sentimentData == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: (sentimentData['color'] as Color).withOpacity(0.15),
        border: Border.all(color: sentimentData['color'] as Color, width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(sentimentData['icon'] as IconData, size: 12, color: sentimentData['color'] as Color),
          const SizedBox(width: 4),
          Text(
            sentimentData['label'] as String,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: sentimentData['color'] as Color),
          ),
        ],
      ),
    );
  }

  Widget _buildTags(ThemeData theme) {
    final allTags = widget.entry.behaviorPatternSummaries.expand((pattern) => pattern.tags).toSet().toList();
    if (allTags.isEmpty) return const SizedBox.shrink();

    return Wrap(spacing: 6, runSpacing: 6, children: allTags.take(3).map(_buildTagChip).toList());
  }

  Widget _buildTagChip(String tag) {
    final tagData = JournalMoodOptions.tags.firstWhere(
      (t) => t['label'] == tag,
      orElse: () => {'label': tag, 'color': const Color(0xFF6B7280)},
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: (tagData['color'] as Color).withOpacity(0.15),
        border: Border.all(color: tagData['color'] as Color, width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        tag,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: tagData['color'] as Color),
      ),
    );
  }

  Widget _buildMetadataChip(ThemeData theme, {required IconData icon, required String label, required Color color}) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600, color: color, fontSize: 11),
            ),
          ],
        ),
      );
}
