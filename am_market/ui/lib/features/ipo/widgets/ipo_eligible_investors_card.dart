import 'package:am_design_system/am_design_system.dart';
import 'package:am_market_ui/features/ipo/models/ipo_models.dart';
import 'package:flutter/material.dart';

class IpoEligibleInvestorsCard extends StatelessWidget {
  final List<AsraxInvestorCategoryDto>? eligibleInvestors;

  const IpoEligibleInvestorsCard({super.key, this.eligibleInvestors});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final list = eligibleInvestors ?? const [];

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
              Icon(Icons.badge_outlined, size: 18, color: ModuleColors.market),
              const SizedBox(width: 8),
              Text(
                'Eligible Investors',
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? context.dividerColor : context.borderColor,
                width: 1,
              ),
            ),
            child: list.isEmpty
                ? Text(
                    'All eligible retail and institutional investors',
                    style: TextStyle(fontSize: 13, color: context.textSecondary),
                  )
                : Wrap(
                    spacing: 12,
                    runSpacing: 10,
                    children: list.map((inv) {
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: ModuleColors.market.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: ModuleColors.market.withValues(alpha: 0.35)),
                            ),
                            child: Text(
                              inv.category,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: ModuleColors.market,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            inv.subscription != null && inv.subscription!.isNotEmpty
                                ? '${inv.subscription}x'
                                : '—',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: context.textSecondary,
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }
}
