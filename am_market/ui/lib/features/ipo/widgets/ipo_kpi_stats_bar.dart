import 'package:am_design_system/am_design_system.dart';
import 'package:am_market_ui/features/ipo/models/ipo_models.dart';
import 'package:am_market_ui/features/ipo/providers/ipo_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class IpoKpiStatsBar extends ConsumerWidget {
  final AsraxIpoCountsDto counts;

  const IpoKpiStatsBar({super.key, required this.counts});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeFilter = ref.watch(ipoFilterStateProvider).statusFilter;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? IpoColors.darkCardBg.withValues(alpha: 0.7) : context.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? IpoColors.darkCardBorder : context.borderColor,
          width: 1,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 600;

          if (isNarrow) {
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.spaceAround,
              children: [
                _buildKpiCard(
                  context,
                  ref,
                  label: 'Total IPOs',
                  count: counts.total,
                  icon: Icons.inventory_2_outlined,
                  filter: IpoStatusFilter.all,
                  isSelected: activeFilter == IpoStatusFilter.all,
                  indicatorColor: context.textPrimary,
                ),
                _buildKpiCard(
                  context,
                  ref,
                  label: 'Open',
                  count: counts.open,
                  filter: IpoStatusFilter.open,
                  isSelected: activeFilter == IpoStatusFilter.open,
                  indicatorColor: IpoColors.dotOpen,
                ),
                _buildKpiCard(
                  context,
                  ref,
                  label: 'Closing Today',
                  count: counts.closingToday,
                  filter: IpoStatusFilter.closingToday,
                  isSelected: activeFilter == IpoStatusFilter.closingToday,
                  indicatorColor: context.statusError,
                ),
                _buildKpiCard(
                  context,
                  ref,
                  label: 'Upcoming',
                  count: counts.upcoming,
                  filter: IpoStatusFilter.upcoming,
                  isSelected: activeFilter == IpoStatusFilter.upcoming,
                  indicatorColor: IpoColors.dotUpcoming,
                ),
                _buildKpiCard(
                  context,
                  ref,
                  label: 'Closed',
                  count: counts.closed,
                  filter: IpoStatusFilter.closed,
                  isSelected: activeFilter == IpoStatusFilter.closed,
                  indicatorColor: IpoColors.dotClosed,
                ),
              ],
            );
          }

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: _buildKpiCard(
                  context,
                  ref,
                  label: 'Total IPOs',
                  count: counts.total,
                  icon: Icons.inventory_2_outlined,
                  filter: IpoStatusFilter.all,
                  isSelected: activeFilter == IpoStatusFilter.all,
                  indicatorColor: context.textPrimary,
                ),
              ),
              _buildDivider(context),
              Expanded(
                child: _buildKpiCard(
                  context,
                  ref,
                  label: 'Open',
                  count: counts.open,
                  filter: IpoStatusFilter.open,
                  isSelected: activeFilter == IpoStatusFilter.open,
                  indicatorColor: IpoColors.dotOpen,
                ),
              ),
              _buildDivider(context),
              Expanded(
                child: _buildKpiCard(
                  context,
                  ref,
                  label: 'Closing Today',
                  count: counts.closingToday,
                  filter: IpoStatusFilter.closingToday,
                  isSelected: activeFilter == IpoStatusFilter.closingToday,
                  indicatorColor: context.statusError,
                ),
              ),
              _buildDivider(context),
              Expanded(
                child: _buildKpiCard(
                  context,
                  ref,
                  label: 'Upcoming',
                  count: counts.upcoming,
                  filter: IpoStatusFilter.upcoming,
                  isSelected: activeFilter == IpoStatusFilter.upcoming,
                  indicatorColor: IpoColors.dotUpcoming,
                ),
              ),
              _buildDivider(context),
              Expanded(
                child: _buildKpiCard(
                  context,
                  ref,
                  label: 'Closed',
                  count: counts.closed,
                  filter: IpoStatusFilter.closed,
                  isSelected: activeFilter == IpoStatusFilter.closed,
                  indicatorColor: IpoColors.dotClosed,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 36,
      width: 1,
      color: isDark ? IpoColors.darkCardBorder : context.dividerColor,
    );
  }

  Widget _buildKpiCard(
    BuildContext context,
    WidgetRef ref, {
    required String label,
    required int count,
    IconData? icon,
    required IpoStatusFilter filter,
    required bool isSelected,
    required Color indicatorColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () {
        ref.read(ipoFilterStateProvider.notifier).setStatusFilter(filter);
      },
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? indicatorColor.withValues(alpha: isDark ? 0.12 : 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: indicatorColor,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 14, color: context.textSecondary),
                  const SizedBox(width: 5),
                ] else ...[
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: indicatorColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                ],
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isSelected ? context.textPrimary : context.textSecondary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
