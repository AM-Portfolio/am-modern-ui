import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';

import '../utils/journal_field_decoration.dart';
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
    this.compact = false,
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
  final bool compact;

  @override
  State<BehaviorTrackingSection> createState() =>
      _BehaviorTrackingSectionState();
}

class _BehaviorTrackingSectionState extends State<BehaviorTrackingSection> {
  int _phaseIndex = 0;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
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
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Compact segmented control — avoids Tab icon+label overflow on mobile.
        SegmentedButton<int>(
          showSelectedIcon: false,
          style: ButtonStyle(
            visualDensity: widget.compact
                ? VisualDensity.compact
                : VisualDensity.standard,
            padding: WidgetStatePropertyAll(
              EdgeInsets.symmetric(
                horizontal: widget.compact ? AppSpacing.xs : AppSpacing.sm,
                vertical: widget.compact ? AppSpacing.xs : AppSpacing.sm,
              ),
            ),
            foregroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return colors.actionPrimaryBg;
              }
              return colors.textSecondary;
            }),
            iconColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return colors.actionPrimaryBg;
              }
              return colors.textSecondary;
            }),
            backgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return colors.actionPrimaryBg.withValues(alpha: 0.16);
              }
              return colors.surface.withValues(alpha: 0.55);
            }),
            side: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return BorderSide(
                  color: colors.actionPrimaryBg.withValues(alpha: 0.55),
                );
              }
              return BorderSide(color: colors.border.withValues(alpha: 0.4));
            }),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: AppRadii.input),
            ),
            textStyle: WidgetStatePropertyAll(
              theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          segments: [
            ButtonSegment(
              value: 0,
              label: Text(widget.compact ? 'Plan' : 'Planning'),
              icon: widget.compact
                  ? null
                  : const Icon(Icons.wb_sunny_outlined, size: AppSpacing.md),
            ),
            ButtonSegment(
              value: 1,
              label: const Text('Mid'),
              icon: widget.compact
                  ? null
                  : const Icon(Icons.timeline_outlined, size: AppSpacing.md),
            ),
            ButtonSegment(
              value: 2,
              label: const Text('End'),
              icon: widget.compact
                  ? null
                  : const Icon(Icons.nightlight_outlined, size: AppSpacing.md),
            ),
          ],
          selected: {_phaseIndex},
          onSelectionChanged: (s) => setState(() => _phaseIndex = s.first),
        ),
        SizedBox(
          height: widget.compact ? AppSpacing.sm : AppSpacing.md,
        ),
        switch (_phaseIndex) {
          1 => _buildTabContent(
              behaviorController: widget.midBehaviorController,
              mood: widget.midMood,
              sentiment: widget.midSentiment,
              hint: 'During trading — active execution',
              onMoodChanged: widget.onMidMoodChanged,
              onSentimentChanged: widget.onMidSentimentChanged,
            ),
          2 => _buildTabContent(
              behaviorController: widget.endBehaviorController,
              mood: widget.endMood,
              sentiment: widget.endSentiment,
              hint: 'Market close — reflection',
              onMoodChanged: widget.onEndMoodChanged,
              onSentimentChanged: widget.onEndSentimentChanged,
            ),
          _ => _buildTabContent(
              behaviorController: widget.planningBehaviorController,
              mood: widget.planningMood,
              sentiment: widget.planningSentiment,
              hint: 'Pre-market preparation and plan',
              onMoodChanged: widget.onPlanningMoodChanged,
              onSentimentChanged: widget.onPlanningSentimentChanged,
            ),
        },
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

    final summaryField = TextFormField(
      controller: behaviorController,
      enabled: widget.isEditMode,
      maxLines: widget.compact ? 2 : 3,
      minLines: widget.compact ? 1 : 2,
      style: theme.textTheme.bodyMedium?.copyWith(
        height: 1.35,
        color: widget.isEditMode
            ? null
            : colors.textPrimary.withValues(alpha: 0.85),
      ),
      decoration: JournalFieldDecoration.outlined(
        context,
        labelText: widget.compact ? 'Summary' : null,
        hintText: hint,
        floatingLabel: widget.compact,
        dense: widget.compact,
      ),
    );

    Widget labeledAbove({
      required String label,
      required Widget child,
    }) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          child,
        ],
      );
    }

    final moodField = IgnorePointer(
      ignoring: !widget.isEditMode,
      child: PhaseTrackingWidget.buildMoodSelector(
        mood: mood,
        onMoodChanged: onMoodChanged,
        isEditMode: widget.isEditMode,
        compact: widget.compact,
      ),
    );
    final sentimentField = IgnorePointer(
      ignoring: !widget.isEditMode,
      child: PhaseTrackingWidget.buildSentimentSelector(
        sentiment: sentiment,
        onSentimentChanged: onSentimentChanged,
        isEditMode: widget.isEditMode,
        compact: widget.compact,
      ),
    );
    final tagsField = IgnorePointer(
      ignoring: !widget.isEditMode,
      child: PhaseTrackingWidget.buildTagsSelector(
        selectedTags: widget.selectedTags,
        onTagToggled: widget.onTagToggled,
        compact: widget.compact,
      ),
    );

    final gap = widget.compact ? AppSpacing.sm : AppSpacing.md;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!widget.compact) ...[
          Text(
            'Summary',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
        summaryField,
        SizedBox(height: gap),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: widget.compact
                  ? moodField
                  : labeledAbove(label: 'Mood', child: moodField),
            ),
            SizedBox(width: gap),
            Expanded(
              child: widget.compact
                  ? sentimentField
                  : labeledAbove(label: 'Sentiment', child: sentimentField),
            ),
          ],
        ),
        SizedBox(height: gap),
        widget.compact
            ? tagsField
            : labeledAbove(label: 'Tags', child: tagsField),
      ],
    );
  }
}
