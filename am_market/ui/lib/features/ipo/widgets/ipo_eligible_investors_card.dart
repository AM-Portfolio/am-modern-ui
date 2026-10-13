import 'package:am_design_system/am_design_system.dart';
import 'package:am_market_ui/features/ipo/models/ipo_models.dart';
import 'package:flutter/material.dart';

class IpoEligibleInvestorsCard extends StatelessWidget {
  final List<AsraxInvestorCategoryDto>? eligibleInvestors;

  const IpoEligibleInvestorsCard({super.key, this.eligibleInvestors});

  @override
  Widget build(BuildContext context) {
    final list = eligibleInvestors ?? const [];
    final width = MediaQuery.sizeOf(context).width;
    final isCompact = width < AmBreakpoints.mobile;

    return Container(
      padding: EdgeInsets.all(isCompact ? 14 : 20),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(isCompact ? 12 : 16),
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
                  fontSize: isCompact ? 15 : 16,
                  fontWeight: FontWeight.w700,
                  color: context.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: isCompact ? 12 : 18),
          list.isEmpty
              ? Text(
                  'All eligible retail and institutional investors',
                  style: TextStyle(fontSize: 13, color: context.textSecondary),
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: list.map((inv) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: ModuleColors.market.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: ModuleColors.market.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Text(
                        inv.category,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: ModuleColors.market,
                        ),
                      ),
                    );
                  }).toList(),
                ),
        ],
      ),
    );
  }
}
