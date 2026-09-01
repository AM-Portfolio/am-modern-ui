import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';

class CustomizeActualCostBanner extends StatelessWidget {
  final double actualCost;
  final double variance;
  final double investmentAmount;
  final double? residualCash;
  final double heldCoverage;
  final String Function(double) formatCurrency;

  const CustomizeActualCostBanner({
    super.key,
    required this.actualCost,
    required this.variance,
    required this.investmentAmount,
    this.residualCash,
    required this.heldCoverage,
    required this.formatCurrency,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOverBudget = variance > 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isOverBudget
            ? context.statusWarning.withValues(alpha: 0.1)
            : context.statusSuccess.withValues(alpha: 0.1),
        borderRadius: AppRadii.button,
        border: Border.all(
          color: isOverBudget
              ? context.statusWarning.withValues(alpha: 0.3)
              : context.statusSuccess.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(
              isOverBudget
                  ? Icons.warning_amber_rounded
                  : Icons.check_circle_outline,
              size: 16,
              color:
                  isOverBudget ? context.statusWarning : context.statusSuccess,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order Budget: ${formatCurrency(actualCost)} of ${formatCurrency(investmentAmount)} deployed in fresh orders',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: context.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                if (heldCoverage > 0)
                  Text(
                    'Held stocks cover ${formatCurrency(heldCoverage)} of the basket',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: context.statusSuccess,
                    ),
                  ),
                if (residualCash != null && residualCash! > 0)
                  Text(
                    'Rounding leftover: ${formatCurrency(residualCash!)} (undeployed)',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: context.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
