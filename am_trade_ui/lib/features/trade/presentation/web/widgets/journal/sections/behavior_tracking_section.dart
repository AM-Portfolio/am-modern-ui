import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';

import '../widgets/phase_tracking_widget.dart';

/// Section for tracking behavior, mood, and sentiment across trading phases.
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
  State<BehaviorTrackingSection> createState() =>
      _BehaviorTrackingSectionState();
}

class _BehaviorTrackingSectionState extends State<BehaviorTrackingSection>
    with SingleTickerProviderStateMixin {
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
    final colors = context.colors;
    final hasPlanningBehavior =
        widget.planningBehaviorController.text.trim().isNotEmpty;
    final hasMidBehavior = widget.midBehaviorController.text.trim().isNotEmpty;
    final hasEndBehavior = widget.endBehaviorController.text.trim().isNotEmpty;

    if (!widget.isEditMode &&
        !hasPlanningBehavior &&
        !hasMidBehavior &&
        !hasEndBehavior) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.psychology_alt_outlined,
              size: 18,
              color: ModuleColors.trade,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Behavior & mood',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                height: 1.1,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Track planning, mid-session, and end-of-day state',
          style: theme.textTheme.labelSmall?.copyWith(
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        DecoratedBox(
          decoration: BoxDecoration(
            color: colors.cardSurface.withValues(alpha: 0.4),
            borderRadius: AppRadii.input,
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: colors.textPrimary,
            unselectedLabelColor: colors.textSecondary,
            indicator: BoxDecoration(
              color: ModuleColors.trade.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            labelPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            labelStyle: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
            unselectedLabelStyle: theme.textTheme.labelLarge?.copyWith(
              fontSize: 13,
            ),
            tabs: const [
              Tab(
                height: 42,
                iconMargin: EdgeInsets.only(bottom: 2),
                icon: Icon(Icons.wb_sunny_outlined, size: 16),
                text: 'Planning',
              ),
              Tab(
                height: 42,
                iconMargin: EdgeInsets.only(bottom: 2),
                icon: Icon(Icons.timeline_outlined, size: 16),
                text: 'Mid',
              ),
              Tab(
                height: 42,
                iconMargin: EdgeInsets.only(bottom: 2),
                icon: Icon(Icons.nightlight_outlined, size: 16),
                text: 'End',
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
        // Natural height — avoid fixed TabBarView which overflowed chips/tags.
        AnimatedBuilder(
          animation: _tabController,
          builder: (context, _) {
            switch (_tabController.index) {
              case 1:
                return _buildTabContent(
                  behaviorController: widget.midBehaviorController,
                  mood: widget.midMood,
                  sentiment: widget.midSentiment,
                  hint: 'During trading — active execution',
                  onMoodChanged: widget.onMidMoodChanged,
                  onSentimentChanged: widget.onMidSentimentChanged,
                );
              case 2:
                return _buildTabContent(
                  behaviorController: widget.endBehaviorController,
                  mood: widget.endMood,
                  sentiment: widget.endSentiment,
                  hint: 'Market close — reflection',
                  onMoodChanged: widget.onEndMoodChanged,
                  onSentimentChanged: widget.onEndSentimentChanged,
                );
              case 0:
              default:
                return _buildTabContent(
                  behaviorController: widget.planningBehaviorController,
                  mood: widget.planningMood,
                  sentiment: widget.planningSentiment,
                  hint: 'Pre-market preparation and plan',
                  onMoodChanged: widget.onPlanningMoodChanged,
                  onSentimentChanged: widget.onPlanningSentimentChanged,
                );
            }
          },
        ),
      ],
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
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Summary',
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs + AppSpacing.xxs),
        TextFormField(
          controller: behaviorController,
          enabled: widget.isEditMode,
          maxLines: 3,
          minLines: 2,
          style: theme.textTheme.bodyMedium?.copyWith(
            height: 1.4,
            color: widget.isEditMode
                ? null
                : colors.textPrimary.withValues(alpha: 0.85),
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: theme.textTheme.bodyMedium?.copyWith(
              color: colors.textSecondary.withValues(alpha: 0.7),
            ),
            filled: true,
            fillColor: colors.cardSurface.withValues(alpha: 0.55),
            border: OutlineInputBorder(
              borderRadius: AppRadii.input,
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppRadii.input,
              borderSide: BorderSide(color: colors.border.withValues(alpha: 0.4)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppRadii.input,
              borderSide: BorderSide(
                color: ModuleColors.trade.withValues(alpha: 0.6),
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: AppRadii.input,
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm + AppSpacing.xs,
              vertical: AppSpacing.sm + AppSpacing.xs,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mood',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs + AppSpacing.xxs),
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
            const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sentiment',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs + AppSpacing.xxs),
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
        const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
        Text(
          'Tags',
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs + AppSpacing.xxs),
        IgnorePointer(
          ignoring: !widget.isEditMode,
          child: PhaseTrackingWidget.buildTagsSelector(
            selectedTags: widget.selectedTags,
            onTagToggled: widget.onTagToggled,
          ),
        ),
      ],
    );
  }
}
