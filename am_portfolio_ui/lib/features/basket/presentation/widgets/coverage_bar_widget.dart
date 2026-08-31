import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';

class CoverageBarWidget extends StatelessWidget {
  final double matchScore; // 0 to 100
  final double replicaScore; // 0 to 100
  final double missingScore; // 0 to 100

  const CoverageBarWidget({
    Key? key,
    required this.matchScore,
    required this.replicaScore,
    required this.missingScore,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Basket Coverage', style: Theme.of(context).textTheme.titleSmall),
            Text('${replicaScore.toStringAsFixed(1)}% / 100%', style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        ClipRRect(
          borderRadius: AppRadii.card,
          child: Container(
            height: 12,
            width: double.infinity,
            color: context.dividerColor,
            child: Row(
              children: [
                if (matchScore > 0)
                  Expanded(
                    flex: (matchScore * 100).toInt(),
                    child: Container(color: context.statusSuccess),
                  ),
                if (replicaScore - matchScore > 0)
                  Expanded(
                    flex: ((replicaScore - matchScore) * 100).toInt(),
                    child: Container(color: context.statusInfo),
                  ),
                if (missingScore > 0)
                  Expanded(
                    flex: (missingScore * 100).toInt(),
                    child: Container(color: context.colors.actionPrimaryBg.withOpacity(0.2)),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            _buildLegend(context, 'Held', context.statusSuccess),
            const SizedBox(width: AppSpacing.sm),
            _buildLegend(context, 'Substituted', context.statusInfo),
            const SizedBox(width: AppSpacing.sm),
            _buildLegend(context, 'Gap', context.colors.actionPrimaryBg.withOpacity(0.2)),
          ],
        )
      ],
    );
  }

  Widget _buildLegend(BuildContext context, String label, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}
