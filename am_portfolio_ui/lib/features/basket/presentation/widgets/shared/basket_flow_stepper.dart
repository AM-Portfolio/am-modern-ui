import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';
import '../../utils/basket_responsive.dart';
import 'basket_flow_step.dart';

/// Horizontal stepper shown across Preview → Customize → Final Review → Confirm.
class BasketFlowStepper extends StatelessWidget {
  final BasketFlowStep currentStep;
  final Widget? trailing;

  const BasketFlowStepper({
    super.key,
    required this.currentStep,
    this.trailing,
  });

  String _shortLabel(BasketFlowStep step) {
    switch (step) {
      case BasketFlowStep.preview:
        return 'Preview';
      case BasketFlowStep.customize:
        return 'Customize';
      case BasketFlowStep.finalReview:
        return 'Review';
      case BasketFlowStep.confirm:
        return 'Confirm';
    }
  }

  Widget _buildStep(
    BuildContext context,
    BasketFlowStep step, {
    required bool isCompleted,
    required bool isActive,
    required bool isNext,
    required bool showLabel,
    required bool compact,
  }) {
    final theme = Theme.of(context);
    final isPending = !isCompleted && !isActive;
    final color = isCompleted || isActive
        ? ModuleColors.portfolio
        : context.colors.border;
    final textColor = isCompleted || isActive
        ? context.colors.textPrimary
        : (isNext
            ? context.colors.textSecondary
            : context.colors.textTertiary);
    final label = compact ? _shortLabel(step) : step.label;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: (isCompleted || isActive) ? color : Colors.transparent,
            border: isPending ? Border.all(color: color, width: 2) : null,
          ),
          alignment: Alignment.center,
          child: isCompleted
              ? const Icon(Icons.check, size: 16, color: Colors.white)
              : Text(
                  '${step.stepNumber}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isActive ? Colors.white : color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
        if (showLabel) ...[
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: textColor,
              fontWeight: (isCompleted || isActive)
                  ? FontWeight.w700
                  : FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLine(BuildContext context, {double width = 24}) {
    return Container(
      width: width,
      height: 1,
      color: context.colors.border.withValues(alpha: 0.7),
      margin: const EdgeInsets.symmetric(horizontal: 6),
    );
  }

  @override
  Widget build(BuildContext context) {
    const steps = BasketFlowStep.values;
    final compact = BasketResponsive.useCompactPreview(context);
    final showAllLabels = BasketResponsive.widthOf(context) >= 720;
    final currentIndex = currentStep.index;

    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border(
          bottom: BorderSide(
            color: context.colors.border.withValues(alpha: 0.6),
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 6,
          ),
          child: Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < steps.length; i++) ...[
                        if (i > 0)
                          _buildLine(context, width: compact ? 10 : 24),
                        _buildStep(
                          context,
                          steps[i],
                          isCompleted: steps[i].stepNumber <
                              currentStep.stepNumber,
                          isActive: steps[i] == currentStep,
                          isNext: i == currentIndex + 1,
                          showLabel: showAllLabels ||
                              steps[i] == currentStep ||
                              steps[i].stepNumber < currentStep.stepNumber ||
                              i == currentIndex + 1,
                          compact: compact || !showAllLabels,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}
