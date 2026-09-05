import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';

class FpStepper extends StatelessWidget {
  const FpStepper({super.key});

  Widget _buildStep(
    BuildContext context,
    String label, {
    required bool isCompleted,
    required bool isActive,
    required bool isPending,
    String? number,
  }) {
    final theme = Theme.of(context);
    final color = isCompleted || isActive
        ? ModuleColors.portfolio
        : context.colors.border;
    final textColor = (isCompleted || isActive)
        ? context.colors.textPrimary
        : context.colors.textTertiary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: (isCompleted || isActive) ? color : Colors.transparent,
            border: isPending ? Border.all(color: color, width: 2) : null,
          ),
          alignment: Alignment.center,
          child: isCompleted
              ? const Icon(Icons.check, size: 16, color: Colors.white)
              : Text(
                  number ?? '',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isActive ? Colors.white : color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: textColor,
            fontWeight: (isCompleted || isActive) ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildLine(BuildContext context) {
    return Container(
      width: 40,
      height: 1,
      color: context.colors.border,
      margin: const EdgeInsets.symmetric(horizontal: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildStep(context, 'Preview', isCompleted: true, isActive: false, isPending: false),
            _buildLine(context),
            _buildStep(context, 'Customize', isCompleted: true, isActive: false, isPending: false),
            _buildLine(context),
            _buildStep(context, 'Final Preview', isCompleted: false, isActive: true, isPending: false, number: '3'),
            _buildLine(context),
            _buildStep(context, 'Confirm & Create', isCompleted: false, isActive: false, isPending: true, number: '4'),
          ],
        ),
      ),
    );
  }
}
