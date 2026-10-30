import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../internal/domain/entities/portfolio_holding.dart';
import '../../../providers/portfolio_providers.dart';

/// Mobile holdings Sector / Industry strip.
///
/// Visibility is controlled by [mobileHoldingsFiltersExpandedProvider]
/// (toggle lives beside the settings icon on the sticky header).
/// When collapsed this widget takes **no** vertical space.
class PortfolioHoldingsMobileFilters extends ConsumerWidget {
  const PortfolioHoldingsMobileFilters({
    required this.allHoldings,
    required this.filteredCount,
    required this.selectedSector,
    required this.selectedIndustry,
    required this.onSectorChanged,
    required this.onIndustryChanged,
    required this.onReset,
    super.key,
  });

  final List<PortfolioHolding> allHoldings;
  final int filteredCount;
  final String selectedSector;
  final String selectedIndustry;
  final ValueChanged<String> onSectorChanged;
  final ValueChanged<String> onIndustryChanged;
  final VoidCallback onReset;

  static const double _controlHeight = 40;

  List<String> get _sectors {
    final set = <String>{};
    for (final h in allHoldings) {
      final s = h.sector.trim();
      if (s.isNotEmpty && s.toLowerCase() != 'unknown') set.add(s);
    }
    final list = set.toList()..sort();
    return ['All', ...list];
  }

  List<String> get _industries {
    final set = <String>{};
    for (final h in allHoldings) {
      if (selectedSector != 'All' && h.sector.trim() != selectedSector) {
        continue;
      }
      final i = h.industry.trim();
      if (i.isNotEmpty && i.toLowerCase() != 'unknown') set.add(i);
    }
    final list = set.toList()..sort();
    return ['All', ...list];
  }

  bool get _hasActive =>
      selectedSector != 'All' || selectedIndustry != 'All';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expanded = ref.watch(mobileHoldingsFiltersExpandedProvider);

    if (!expanded) {
      return const SizedBox.shrink();
    }

    final accent = ModuleColors.portfolio;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom:
              BorderSide(color: context.borderColor.withValues(alpha: 0.6)),
        ),
      ),
      child: SizedBox(
        height: _controlHeight,
        child: Row(
          children: [
            Expanded(
              child: _buildFilterDropdown(
                context,
                icon: Icons.public_outlined,
                placeholder: 'Sector',
                value: selectedSector,
                allMenuLabel: 'All Sectors',
                options: _sectors,
                onSelected: onSectorChanged,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildFilterDropdown(
                context,
                icon: Icons.bar_chart_rounded,
                placeholder: 'Industry',
                value: selectedIndustry,
                allMenuLabel: 'All Industries',
                options: _industries,
                onSelected: onIndustryChanged,
              ),
            ),
            if (_hasActive) ...[
              const SizedBox(width: 6),
              _buildClearChip(context, accent),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildClearChip(BuildContext context, Color accent) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onReset,
        borderRadius: BorderRadius.circular(AppRadii.sm),
        child: Container(
          height: _controlHeight,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadii.sm),
            border: Border.all(color: accent.withValues(alpha: 0.45)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$filteredCount',
                style: TextStyle(
                  color: accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.close, size: 14, color: accent),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterDropdown(
    BuildContext context, {
    required IconData icon,
    required String placeholder,
    required String value,
    required String allMenuLabel,
    required List<String> options,
    required ValueChanged<String> onSelected,
  }) {
    final accent = ModuleColors.portfolio;
    final filtered = value != 'All';
    final triggerLabel = filtered ? value : placeholder;

    return SizedBox(
      height: _controlHeight,
      child: CustomDropdown<String>(
        value: value,
        primaryColor: accent,
        isExpanded: true,
        height: _controlHeight,
        borderRadius: AppRadii.sm,
        backgroundColor: filtered
            ? accent.withValues(alpha: 0.12)
            : context.glassOverlay(0.05),
        borderColor:
            filtered ? accent.withValues(alpha: 0.55) : context.borderColor,
        menuMaxHeight: 320,
        menuMaxWidth: 300,
        contentPadding: const EdgeInsets.only(left: 10, right: 6),
        leading: Icon(
          icon,
          size: 14,
          color: filtered ? accent : context.textTertiary,
        ),
        selectedItemBuilder: (context, _) => Text(
          triggerLabel,
          style: TextStyle(
            fontSize: 12,
            fontWeight: filtered ? FontWeight.w700 : FontWeight.w500,
            color: filtered ? accent : context.textSecondary,
            height: 1.1,
          ),
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.ellipsis,
        ),
        items: options
            .map(
              (opt) => DropdownMenuItem<String>(
                value: opt,
                child: Text(
                  opt == 'All' ? allMenuLabel : opt,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            )
            .toList(),
        onChanged: (v) {
          if (v != null) onSelected(v);
        },
      ),
    );
  }
}
