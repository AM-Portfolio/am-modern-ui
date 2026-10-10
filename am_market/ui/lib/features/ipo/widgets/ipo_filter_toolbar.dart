import 'package:am_design_system/am_design_system.dart';
import 'package:am_market_ui/features/ipo/models/ipo_models.dart';
import 'package:am_market_ui/features/ipo/providers/ipo_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class IpoFilterToolbar extends ConsumerWidget {
  final AsraxIpoCountsDto counts;

  const IpoFilterToolbar({super.key, required this.counts});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filterState = ref.watch(ipoFilterStateProvider);
    final industries = ref.watch(distinctIndustriesProvider);
    final industryDropdown = _buildIndustryDropdown(
      context,
      ref,
      industries,
      filterState.selectedIndustry,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;
        final isCompact = constraints.maxWidth < AmBreakpoints.mobile;

        if (isWide) {
          // Chips + board on the left; Industry CustomDropdown pinned right.
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      ..._statusChips(context, ref, filterState),
                      const SizedBox(width: 14),
                      _buildVerticalDivider(context),
                      const SizedBox(width: 14),
                      _buildCheckbox(
                        context,
                        label: 'Mainboard',
                        value: filterState.filterMainboard,
                        onChanged: (val) => ref
                            .read(ipoFilterStateProvider.notifier)
                            .toggleMainboard(val),
                      ),
                      const SizedBox(width: 12),
                      _buildCheckbox(
                        context,
                        label: 'SME',
                        value: filterState.filterSme,
                        onChanged: (val) => ref
                            .read(ipoFilterStateProvider.notifier)
                            .toggleSme(val),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              industryDropdown,
            ],
          );
        }

        // Narrow / Mobile: chips, then board chips left + industry right.
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: _statusChips(context, ref, filterState),
              ),
            ),
            SizedBox(height: isCompact ? 10 : 12),
            Row(
              children: [
                _buildBoardChip(
                  context,
                  label: 'Mainboard',
                  selected: filterState.filterMainboard,
                  onTap: () => ref
                      .read(ipoFilterStateProvider.notifier)
                      .toggleMainboard(!filterState.filterMainboard),
                ),
                const SizedBox(width: 8),
                _buildBoardChip(
                  context,
                  label: 'SME',
                  selected: filterState.filterSme,
                  onTap: () => ref
                      .read(ipoFilterStateProvider.notifier)
                      .toggleSme(!filterState.filterSme),
                ),
                const Spacer(),
                industryDropdown,
              ],
            ),
          ],
        );
      },
    );
  }

  List<Widget> _statusChips(
    BuildContext context,
    WidgetRef ref,
    IpoFilterState filterState,
  ) {
    final chips = <({String label, int count, IpoStatusFilter filter})>[
      (label: 'All', count: counts.total, filter: IpoStatusFilter.all),
      (label: 'Open', count: counts.open, filter: IpoStatusFilter.open),
      (
        label: 'Closing Today',
        count: counts.closingToday,
        filter: IpoStatusFilter.closingToday,
      ),
      (
        label: 'Upcoming',
        count: counts.upcoming,
        filter: IpoStatusFilter.upcoming,
      ),
      (
        label: 'Closed',
        count: counts.closed + counts.listed,
        filter: IpoStatusFilter.closed,
      ),
    ];

    final widgets = <Widget>[];
    for (var i = 0; i < chips.length; i++) {
      if (i > 0) widgets.add(const SizedBox(width: 8));
      final c = chips[i];
      widgets.add(
        _buildFilterChip(
          context,
          ref,
          label: c.label,
          count: c.count,
          filter: c.filter,
          isSelected: filterState.statusFilter == c.filter,
        ),
      );
    }
    return widgets;
  }

  Widget _buildVerticalDivider(BuildContext context) {
    return Container(
      height: 20,
      width: 1,
      color: context.dividerColor,
    );
  }

  Widget _buildFilterChip(
    BuildContext context,
    WidgetRef ref, {
    required String label,
    required int count,
    required IpoStatusFilter filter,
    required bool isSelected,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          ref.read(ipoFilterStateProvider.notifier).setStatusFilter(filter);
        },
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? context.surfaceColor : context.textPrimary)
                : context.surfaceColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? (isDark ? ModuleColors.market : context.textPrimary)
                  : context.borderColor,
              width: isSelected ? 1.2 : 1,
            ),
          ),
          child: Text(
            '$label ($count)',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected
                  ? (isDark ? ModuleColors.market : context.cardColor)
                  : context.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBoardChip(
    BuildContext context, {
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: selected
                ? ModuleColors.market.withValues(alpha: isDark ? 0.16 : 0.10)
                : context.surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? ModuleColors.market : context.borderColor,
              width: selected ? 1.2 : 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: selected ? ModuleColors.market : context.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCheckbox(
    BuildContext context, {
    required String label,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: Checkbox(
                value: value,
                onChanged: onChanged,
                activeColor: ModuleColors.market,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                side: BorderSide(color: context.textTertiary, width: 1.2),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.textPrimary,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIndustryDropdown(
    BuildContext context,
    WidgetRef ref,
    List<String> industries,
    String? selected,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentVal =
        (selected != null && industries.contains(selected)) ? selected : 'All';

    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Align(
        alignment: Alignment.centerRight,
        widthFactor: 1,
        child: CustomDropdown<String>(
          value: currentVal,
          height: 36,
          isExpanded: false,
          fontSize: 12,
          iconSize: 16,
          borderRadius: 10,
          menuMaxHeight: 220,
          primaryColor: ModuleColors.market,
          backgroundColor:
              isDark ? Colors.white.withValues(alpha: 0.06) : null,
          borderColor: isDark ? Colors.white.withValues(alpha: 0.1) : null,
          contentPadding: const EdgeInsets.symmetric(horizontal: 10),
          items: industries.map((ind) {
            // Short closed-button label; full names still clear in the menu.
            final label = ind == 'All' ? 'Industry' : ind;
            return DropdownMenuItem<String>(
              value: ind,
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: context.textPrimary,
                ),
              ),
            );
          }).toList(),
          onChanged: (val) {
            ref
                .read(ipoFilterStateProvider.notifier)
                .setIndustry(val == null || val == 'All' ? null : val);
          },
        ),
      ),
    );
  }
}
