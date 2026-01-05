import 'package:flutter/material.dart';

import '../widgets/phase_tracking_widget.dart';

/// Section for tracking behavior, mood, and sentiment across all trading phases
class BehaviorTrackingSection extends StatefulWidget {
  const BehaviorTrackingSection({
    required this.planningBehaviorController,
    required this.planningMood,
    required this.planningSentiment,
    required this.midBehaviorController,
    required this.midMood,
    required this.midSentiment,
    required this.endBehaviorController,
    required this.endMood,
    required this.endSentiment,
    required this.onPlanningMoodChanged,
    required this.onPlanningSentimentChanged,
    required this.onMidMoodChanged,
    required this.onMidSentimentChanged,
    required this.onEndMoodChanged,
    required this.onEndSentimentChanged,
    required this.selectedTags,
    required this.onTagToggled,
    required this.isEditMode,
    super.key,
  });

  final TextEditingController planningBehaviorController;
  final String? planningMood;
  final String? planningSentiment;
  final TextEditingController midBehaviorController;
  final String? midMood;
  final String? midSentiment;
  final TextEditingController endBehaviorController;
  final String? endMood;
  final String? endSentiment;
  final Function(String?) onPlanningMoodChanged;
  final Function(String?) onPlanningSentimentChanged;
  final Function(String?) onMidMoodChanged;
  final Function(String?) onMidSentimentChanged;
  final Function(String?) onEndMoodChanged;
  final Function(String?) onEndSentimentChanged;
  final Set<String> selectedTags;
  final Function(String) onTagToggled;
  final bool isEditMode;

  @override
  State<BehaviorTrackingSection> createState() => _BehaviorTrackingSectionState();
}

class _BehaviorTrackingSectionState extends State<BehaviorTrackingSection> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasPlanningBehavior = widget.planningBehaviorController.text.trim().isNotEmpty;
    final hasMidBehavior = widget.midBehaviorController.text.trim().isNotEmpty;
    final hasEndBehavior = widget.endBehaviorController.text.trim().isNotEmpty;

    // Only show in edit mode or if any behavior data exists
    if (!widget.isEditMode && !hasPlanningBehavior && !hasMidBehavior && !hasEndBehavior) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
        color: theme.colorScheme.primaryContainer.withOpacity(0.1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
            child: Row(
              children: [
                Icon(Icons.psychology, size: 13, color: theme.colorScheme.primary),
                const SizedBox(width: 3),
                Text(
                  'Daily Behavior & Mood Tracking',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),

          // Tab Bar
          TabBar(
            controller: _tabController,
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
            indicatorColor: theme.colorScheme.primary,
            indicatorSize: TabBarIndicatorSize.tab,
            labelPadding: const EdgeInsets.symmetric(horizontal: 4),
            padding: EdgeInsets.zero,
            labelStyle: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600, fontSize: 10),
            unselectedLabelStyle: theme.textTheme.labelSmall?.copyWith(fontSize: 10),
            tabs: const [
              Tab(
                icon: Icon(Icons.lightbulb_outline, size: 12),
                text: 'Planning',
                iconMargin: EdgeInsets.only(bottom: 1),
                height: 36,
              ),
              Tab(
                icon: Icon(Icons.access_time, size: 12),
                text: 'Mid',
                iconMargin: EdgeInsets.only(bottom: 1),
                height: 36,
              ),
              Tab(
                icon: Icon(Icons.nightlight_outlined, size: 12),
                text: 'End',
                iconMargin: EdgeInsets.only(bottom: 1),
                height: 36,
              ),
            ],
          ),

          // Tab Content
          SizedBox(
            height: 180,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTabContent(
                  behaviorController: widget.planningBehaviorController,
                  mood: widget.planningMood,
                  sentiment: widget.planningSentiment,
                  hint: 'Pre-market preparation and plan',
                  onMoodChanged: widget.onPlanningMoodChanged,
                  onSentimentChanged: widget.onPlanningSentimentChanged,
                ),
                _buildTabContent(
                  behaviorController: widget.midBehaviorController,
                  mood: widget.midMood,
                  sentiment: widget.midSentiment,
                  hint: 'During trading - active execution',
                  onMoodChanged: widget.onMidMoodChanged,
                  onSentimentChanged: widget.onMidSentimentChanged,
                ),
                _buildTabContent(
                  behaviorController: widget.endBehaviorController,
                  mood: widget.endMood,
                  sentiment: widget.endSentiment,
                  hint: 'Market close - reflection',
                  onMoodChanged: widget.onEndMoodChanged,
                  onSentimentChanged: widget.onEndSentimentChanged,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent({
    required TextEditingController behaviorController,
    required String? mood,
    required String? sentiment,
    required String hint,
    required Function(String?) onMoodChanged,
    required Function(String?) onSentimentChanged,
  }) {
    final theme = Theme.of(context);
    final hasBehavior = behaviorController.text.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.all(4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Summary label and input
          Text(
            'Summary',
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 2),
          Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: hasBehavior ? theme.colorScheme.primary.withOpacity(0.3) : theme.dividerColor.withOpacity(0.2),
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: TextFormField(
              controller: behaviorController,
              enabled: widget.isEditMode,
              maxLines: 3,
              minLines: 2,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: widget.isEditMode ? null : theme.colorScheme.onSurface.withOpacity(0.85),
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 10,
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(height: 4),

          // Mood and Sentiment with labels
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mood',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 2),
                    IgnorePointer(
                      ignoring: !widget.isEditMode,
                      child: PhaseTrackingWidget.buildMoodSelector(
                        mood: mood,
                        onMoodChanged: onMoodChanged,
                        isEditMode: widget.isEditMode,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sentiment',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 2),
                    IgnorePointer(
                      ignoring: !widget.isEditMode,
                      child: PhaseTrackingWidget.buildSentimentSelector(
                        sentiment: sentiment,
                        onSentimentChanged: onSentimentChanged,
                        isEditMode: widget.isEditMode,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Tags section with label
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tags',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 2),
              IgnorePointer(
                ignoring: !widget.isEditMode,
                child: PhaseTrackingWidget.buildTagsSelector(
                  selectedTags: widget.selectedTags,
                  onTagToggled: widget.onTagToggled,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
