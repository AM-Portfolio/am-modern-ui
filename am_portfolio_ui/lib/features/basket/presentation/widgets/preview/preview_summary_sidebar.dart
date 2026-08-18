import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';
import '../../../domain/models/basket_opportunity.dart';

class PreviewSummarySidebar extends StatelessWidget {
  final BasketOpportunity opportunity;
  final VoidCallback onCustomizeTap;

  const PreviewSummarySidebar({
    super.key,
    required this.opportunity,
    required this.onCustomizeTap,
  });

  @override
  Widget build(BuildContext context) {
    final double matchScore = opportunity.matchScore;
    final Color scoreColor = matchScore > 85
        ? context.statusSuccess
        : (matchScore > 60 ? context.statusWarning : context.statusError);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.colors.surfacePrimary,
        borderRadius: AppRadii.card,
        border: Border.all(color: context.colors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Health Summary',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: CircularProgressIndicator(
                    value: matchScore / 100,
                    strokeWidth: 8,
                    backgroundColor: context.colors.surfaceSecondary,
                    valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${matchScore.toStringAsFixed(0)}%',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: scoreColor,
                          ),
                    ),
                    Text(
                      'Match Score',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: context.colors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          _buildStatRow(
            context,
            'Held Stocks',
            '${opportunity.heldCount}',
            context.statusSuccess,
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildStatRow(
            context,
            'Substituted',
            '${opportunity.totalItems - opportunity.heldCount - opportunity.missingCount}',
            context.statusWarning,
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildStatRow(
            context,
            'Missing',
            '${opportunity.missingCount}',
            context.statusError,
          ),
          const SizedBox(height: AppSpacing.lg),
          const Divider(),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onCustomizeTap,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadii.button,
                ),
              ),
              child: const Text('Customize & Create Portfolio'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(
      BuildContext context, String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: context.colors.textSecondary,
                  ),
            ),
          ],
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
}
