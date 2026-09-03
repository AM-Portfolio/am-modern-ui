import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';

class MinimumInvestmentWarningWidget extends StatelessWidget {
  final double minimumInvestmentAmount;
  final double currentInvestmentAmount;

  const MinimumInvestmentWarningWidget({
    Key? key,
    required this.minimumInvestmentAmount,
    required this.currentInvestmentAmount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (currentInvestmentAmount >= minimumInvestmentAmount) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: context.statusWarning.withOpacity(0.1),
        borderRadius: AppRadii.card,
        border: Border.all(color: context.statusWarning.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: context.statusWarning, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Minimum required investment is ₹${minimumInvestmentAmount.toStringAsFixed(0)} to maintain target weights.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.statusWarning,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
