import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';
import '../../../domain/models/basket_detail.dart';
import 'bd_dashboard_math.dart';
import 'bd_holdings_table.dart';

class BdHoldingsSection extends StatelessWidget {
  final List<BasketLineDetail> lines;
  final double totalCurrentValue;
  final BdHoldingsFilter filter;
  final ValueChanged<BdHoldingsFilter> onFilterChanged;
  final VoidCallback onViewAllocation;
  final bool isMobile;

  const BdHoldingsSection({
    super.key,
    required this.lines,
    required this.totalCurrentValue,
    required this.filter,
    required this.onFilterChanged,
    required this.onViewAllocation,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    final filtered = BdDashboardMath.filterLines(lines, filter);
    final sorted = BdDashboardMath.sortedByWeight(filtered, totalCurrentValue);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: context.cardColor.withValues(alpha: context.isDark ? 0.35 : 0.85),
        border: Border.all(
          color: context.isDark
              ? Colors.white.withValues(alpha: 0.07)
              : Colors.black.withValues(alpha: 0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: context.isDark ? 0.2 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                Text(
                  'Basket Holdings',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: context.colors.actionPrimaryBg.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${filtered.length} Stocks',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: context.colors.actionPrimaryBg,
                    ),
                  ),
                ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: onViewAllocation,
                  icon: Icon(
                    Icons.visibility_outlined,
                    size: 18,
                    color: context.colors.actionPrimaryBg,
                  ),
                  label: Text(
                    'View Allocation',
                    style: TextStyle(color: context.colors.actionPrimaryBg),
                  ),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              children: BdHoldingsFilter.values.map((f) {
                final selected = f == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(_filterLabel(f)),
                    selected: selected,
                    onSelected: (_) => onFilterChanged(f),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (isMobile)
            ...sorted.map(
              (line) => BdHoldingCard(
                line: line,
                weightPercent: BdDashboardMath.basketWeightPercent(
                  line,
                  totalCurrentValue,
                ),
              ),
            )
          else
            BdHoldingsTable(lines: sorted, totalCurrentValue: totalCurrentValue),
          if (filter == BdHoldingsFilter.active &&
              lines.any((l) => l.status.toUpperCase() == 'MISSING'))
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(
                '${lines.where((l) => l.status.toUpperCase() == 'MISSING').length} gap(s) remaining — switch to Missing filter',
                style: TextStyle(fontSize: 12, color: context.statusWarning),
              ),
            ),
        ],
      ),
    );
  }

  String _filterLabel(BdHoldingsFilter f) {
    switch (f) {
      case BdHoldingsFilter.all:
        return 'All';
      case BdHoldingsFilter.held:
        return 'Held';
      case BdHoldingsFilter.substitute:
        return 'Substitute';
      case BdHoldingsFilter.missing:
        return 'Missing';
      case BdHoldingsFilter.active:
        return 'Active';
    }
  }
}
