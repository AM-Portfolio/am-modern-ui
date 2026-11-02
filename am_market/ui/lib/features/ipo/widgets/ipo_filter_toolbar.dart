import 'package:am_design_system/am_design_system.dart';
import 'package:am_market_ui/features/ipo/models/ipo_models.dart';
import 'package:am_market_ui/features/ipo/providers/ipo_providers.dart';
import 'package:am_market_ui/features/ipo/ipo_view_mode.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class IpoFilterToolbar extends ConsumerWidget {
  final AsraxIpoCountsDto counts;
  final IpoViewMode viewMode;
  final ValueChanged<IpoViewMode> onViewModeChanged;

  const IpoFilterToolbar({
    super.key,
    required this.counts,
    required this.viewMode,
    required this.onViewModeChanged,
  });

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
                      const SizedBox(width: 14),
                      _buildViewModeControl(context),
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
                if (!isCompact) ...[
                  const SizedBox(width: 8),
                  _buildViewModeControl(context),
                ],
                const Spacer(),
                industryDropdown,
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildViewModeControl(BuildContext context) {
    return Semantics(
      label: 'IPO list view',
      child: AppSegmentedControl<IpoViewMode>(
        selectedValue: viewMode,
        children: const {
          IpoViewMode.cards: 'Cards',
          IpoViewMode.table: 'Table',
        },
        primaryColor: ModuleColorProvider.of(context),
        onValueChanged: onViewModeChanged,
      ),
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
        borderRadius: BorderRadius.circular(AppRadii.xl),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? context.surfaceColor : context.textPrimary)
                : context.surfaceColor,
            borderRadius: BorderRadius.circular(AppRadii.xl),
            border: Border.all(
              color: isSelected
                  ? (isDark ? ModuleColorProvider.of(context) : context.textPrimary)
                  : context.borderColor,
              width: isSelected ? 1.2 : 1,
            ),
          ),
          child: Text(
            '$label ($count)',
            style: TextStyle(
              fontSize: AppTypeScale.sm,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected
                  ? (isDark ? ModuleColorProvider.of(context) : context.cardColor)
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
        borderRadius: BorderRadius.circular(AppRadii.lg),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: selected
                ? ModuleColorProvider.of(context).withValues(alpha: isDark ? 0.16 : 0.10)
                : context.surfaceColor,
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(
              color: selected ? ModuleColorProvider.of(context) : context.borderColor,
              width: selected ? 1.2 : 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: AppTypeScale.sm,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: selected ? ModuleColorProvider.of(context) : context.textSecondary,
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
      borderRadius: BorderRadius.circular(AppRadii.xs + 2),
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
                activeColor: ModuleColorProvider.of(context),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadii.xs),
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
                    fontSize: AppTypeScale.md,
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
          fontSize: AppTypeScale.sm,
          iconSize: 16,
          borderRadius: 10,
          menuMaxHeight: 220,
          primaryColor: ModuleColorProvider.of(context),
          // Keep the trigger subtle, but give the open menu an opaque themed
          // surface so options remain readable over IPO cards.
          backgroundColor:
              isDark ? context.colors.surface.withValues(alpha: 0.72) : null,
          menuBackgroundColor: context.colors.cardSurface,
          borderColor: isDark ? context.colors.border : null,
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
                  fontSize: AppTypeScale.sm,
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
