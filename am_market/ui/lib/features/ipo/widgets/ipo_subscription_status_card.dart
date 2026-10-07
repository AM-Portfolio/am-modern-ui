import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import '../models/ipo_models.dart';

class IpoSubscriptionStatusCard extends StatelessWidget {
  final String? totalSubscription;
  final List<AsraxInvestorCategoryDto> eligibleInvestors;

  const IpoSubscriptionStatusCard({
    super.key,
    this.totalSubscription,
    this.eligibleInvestors = const [],
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasData = totalSubscription != null && totalSubscription!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.borderColor,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart_rounded, size: 18, color: ModuleColors.market),
              const SizedBox(width: 8),
              Text(
                'Subscription Status',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: context.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? context.dividerColor : context.borderColor,
                width: 1,
              ),
            ),
            child: hasData
                ? Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: context.colors.statusSuccess.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.check_circle_outline_rounded, color: context.colors.statusSuccess, size: 20),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Overall Subscription: ${totalSubscription!}x',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: context.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Bidding actively live across all categories',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: context.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (eligibleInvestors.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 12),
                        ...eligibleInvestors.map((investor) {
                          final value = double.tryParse(investor.subscription ?? '0') ?? 0.0;
                          final isSubscribed = value >= 1.0;
                          final displayValue = (investor.subscription != null && investor.subscription!.isNotEmpty)
                              ? '${investor.subscription}x'
                              : 'N/A';
                          final fillFraction = (value.clamp(0.0, 5.0) / 5.0).clamp(0.05, 1.0);
                          final statusColor = isSubscribed ? context.colors.statusSuccess : context.colors.statusWarning;
                          
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      investor.category,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: context.textSecondary,
                                      ),
                                    ),
                                    Text(
                                      displayValue,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: (investor.subscription != null && investor.subscription!.isNotEmpty)
                                            ? statusColor
                                            : context.textTertiary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  height: 6,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: context.dividerColor,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: FractionallySizedBox(
                                    alignment: Alignment.centerLeft,
                                    widthFactor: (investor.subscription != null && investor.subscription!.isNotEmpty) ? fillFraction : 0.0,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: isSubscribed
                                              ? [
                                                  context.colors.statusSuccess.withValues(alpha: 0.8),
                                                  context.colors.statusSuccess,
                                                ]
                                              : [
                                                  context.colors.statusWarning.withValues(alpha: 0.8),
                                                  context.colors.statusWarning,
                                                ],
                                        ),
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ],
                  )
                : Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isDark ? context.dividerColor : context.dividerColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.remove_rounded, color: context.textTertiary, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Subscription data not available yet',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: context.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Subscription details will be updated once bidding starts.',
                              style: TextStyle(
                                fontSize: 12,
                                color: context.textTertiary,
                              ),
                            ),
                          ],
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
