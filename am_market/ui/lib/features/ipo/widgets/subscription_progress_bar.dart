import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';

class SubscriptionProgressBar extends StatelessWidget {
  final String? subscriptionStr;

  const SubscriptionProgressBar({super.key, required this.subscriptionStr});

  @override
  Widget build(BuildContext context) {
    double value = 0.0;
    if (subscriptionStr != null && subscriptionStr!.isNotEmpty) {
      value = double.tryParse(subscriptionStr!) ?? 0.0;
    }

    final hasData = subscriptionStr != null && subscriptionStr!.isNotEmpty;
    final isSubscribed = value >= 1.0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color statusColor = !hasData
        ? context.textTertiary
        : isSubscribed
            ? (isDark ? IpoColors.progressSubscribed : IpoColors.progressSubscribedLight)
            : (isDark ? IpoColors.progressUnderSubscribed : IpoColors.progressUnderSubscribedLight);

    final String displayValue = hasData ? '${value.toStringAsFixed(2)}x' : 'N/A';

    // Progress bar fill fraction between 0.0 and 1.0 (capped at 1.0 for visual bar)
    final double fillFraction = hasData ? (value.clamp(0.0, 5.0) / 5.0).clamp(0.05, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  'Subscription',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 4),
                Tooltip(
                  message: 'Total subscription multiplier across all investor categories',
                  child: Icon(
                    Icons.info_outline_rounded,
                    size: 13,
                    color: context.textTertiary,
                  ),
                ),
              ],
            ),
            Text(
              displayValue,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: statusColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: 6,
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDark ? IpoColors.darkCardBorder : context.dividerColor,
            borderRadius: BorderRadius.circular(3),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: fillFraction,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isSubscribed
                      ? [
                          IpoColors.progressSubscribed.withValues(alpha: 0.8),
                          IpoColors.stepCompleted,
                        ]
                      : [
                          IpoColors.progressUnderSubscribed.withValues(alpha: 0.8),
                          IpoColors.statusClosingSoon,
                        ],
                ),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
