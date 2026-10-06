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

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;

        if (isWide) {
          return Row(
            children: [
              // 1. Status Filter Pills
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      _buildFilterChip(
                        context,
                        ref,
                        label: 'All',
                        count: counts.total,
                        filter: IpoStatusFilter.all,
                        isSelected: filterState.statusFilter == IpoStatusFilter.all,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        context,
                        ref,
                        label: 'Open',
                        count: counts.open,
                        filter: IpoStatusFilter.open,
                        isSelected: filterState.statusFilter == IpoStatusFilter.open,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        context,
                        ref,
                        label: 'Closing Today',
                        count: counts.closingToday,
                        filter: IpoStatusFilter.closingToday,
                        isSelected: filterState.statusFilter == IpoStatusFilter.closingToday,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        context,
                        ref,
                        label: 'Upcoming',
                        count: counts.upcoming,
                        filter: IpoStatusFilter.upcoming,
                        isSelected: filterState.statusFilter == IpoStatusFilter.upcoming,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        context,
                        ref,
                        label: 'Closed',
                        count: counts.closed,
                        filter: IpoStatusFilter.closed,
                        isSelected: filterState.statusFilter == IpoStatusFilter.closed,
                      ),
                      const SizedBox(width: 14),
                      _buildVerticalDivider(context),
                      const SizedBox(width: 14),
                      // 2. Board Checkboxes
                      _buildCheckbox(
                        context,
                        label: 'Mainboard',
                        value: filterState.filterMainboard,
                        onChanged: (val) => ref.read(ipoFilterStateProvider.notifier).toggleMainboard(val),
                      ),
                      const SizedBox(width: 12),
                      _buildCheckbox(
                        context,
                        label: 'SME',
                        value: filterState.filterSme,
                        onChanged: (val) => ref.read(ipoFilterStateProvider.notifier).toggleSme(val),
                      ),
                      const SizedBox(width: 14),
                      // 3. Industry Dropdown
                      _buildIndustryDropdown(context, ref, industries, filterState.selectedIndustry),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // 4. Search Box
              SizedBox(
                width: 260,
                child: _buildSearchBox(context, ref, filterState.searchQuery),
              ),
            ],
          );
        }

        // Narrow / Mobile View: 2 rows
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _buildFilterChip(
                    context,
                    ref,
                    label: 'All',
                    count: counts.total,
                    filter: IpoStatusFilter.all,
                    isSelected: filterState.statusFilter == IpoStatusFilter.all,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    context,
                    ref,
                    label: 'Open',
                    count: counts.open,
                    filter: IpoStatusFilter.open,
                    isSelected: filterState.statusFilter == IpoStatusFilter.open,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    context,
                    ref,
                    label: 'Closing Today',
                    count: counts.closingToday,
                    filter: IpoStatusFilter.closingToday,
                    isSelected: filterState.statusFilter == IpoStatusFilter.closingToday,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    context,
                    ref,
                    label: 'Upcoming',
                    count: counts.upcoming,
                    filter: IpoStatusFilter.upcoming,
                    isSelected: filterState.statusFilter == IpoStatusFilter.upcoming,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    context,
                    ref,
                    label: 'Closed',
                    count: counts.closed,
                    filter: IpoStatusFilter.closed,
                    isSelected: filterState.statusFilter == IpoStatusFilter.closed,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildSearchBox(context, ref, filterState.searchQuery),
                ),
                const SizedBox(width: 8),
                _buildIndustryDropdown(context, ref, industries, filterState.selectedIndustry),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildCheckbox(
                  context,
                  label: 'Mainboard',
                  value: filterState.filterMainboard,
                  onChanged: (val) => ref.read(ipoFilterStateProvider.notifier).toggleMainboard(val),
                ),
                const SizedBox(width: 12),
                _buildCheckbox(
                  context,
                  label: 'SME',
                  value: filterState.filterSme,
                  onChanged: (val) => ref.read(ipoFilterStateProvider.notifier).toggleSme(val),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildVerticalDivider(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 20,
      width: 1,
      color: isDark ? const Color(0xFF334155) : context.borderColor,
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

    return InkWell(
      onTap: () {
        ref.read(ipoFilterStateProvider.notifier).setStatusFilter(filter);
      },
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF1E293B) : Colors.black87)
              : (isDark ? const Color(0xFF0F172A).withValues(alpha: 0.5) : context.surfaceColor),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? (isDark ? const Color(0xFF38BDF8) : Colors.black87)
                : (isDark ? const Color(0xFF1E293B) : context.borderColor),
            width: isSelected ? 1.2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isSelected ? '$label ($count)' : label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.white : context.textSecondary,
              ),
            ),
            if (!isSelected && count > 0) ...[
              const SizedBox(width: 5),
              Text(
                '($count)',
                style: TextStyle(
                  fontSize: 12,
                  color: context.textTertiary,
                ),
              ),
            ],
          ],
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
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
    final currentVal = (selected != null && industries.contains(selected)) ? selected : 'All';

    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.6) : context.surfaceColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : context.borderColor,
          width: 1,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentVal,
          icon: Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: context.textSecondary),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: context.textPrimary,
          ),
          dropdownColor: isDark ? const Color(0xFF0F172A) : context.surfaceColor,
          items: industries.map((ind) {
            return DropdownMenuItem<String>(
              value: ind,
              child: Text(
                ind == 'All' ? 'Industry: All' : ind,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (val) {
            ref.read(ipoFilterStateProvider.notifier).setIndustry(val == 'All' ? null : val);
          },
        ),
      ),
    );
  }

  Widget _buildSearchBox(BuildContext context, WidgetRef ref, String query) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.6) : context.surfaceColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : context.borderColor,
          width: 1,
        ),
      ),
      child: TextField(
        controller: TextEditingController(text: query)..selection = TextSelection.collapsed(offset: query.length),
        onChanged: (val) {
          ref.read(ipoFilterStateProvider.notifier).setSearchQuery(val);
        },
        style: TextStyle(
          fontSize: 13,
          color: context.textPrimary,
        ),
        decoration: InputDecoration(
          isDense: true,
          hintText: 'Search IPO by name or symbol...',
          hintStyle: TextStyle(
            fontSize: 12,
            color: context.textTertiary,
          ),
          prefixIcon: Icon(Icons.search_rounded, size: 18, color: context.textTertiary),
          suffixIcon: query.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear_rounded, size: 16, color: context.textTertiary),
                  onPressed: () => ref.read(ipoFilterStateProvider.notifier).setSearchQuery(''),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        ),
      ),
    );
  }
}
