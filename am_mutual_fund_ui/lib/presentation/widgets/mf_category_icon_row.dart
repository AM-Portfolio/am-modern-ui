import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';

import '../../data/mf_scheme_view.dart';

/// Circular category icons (mock-style) for Explore.
class MfCategoryIconRow extends StatelessWidget {
  const MfCategoryIconRow({
    required this.selected,
    required this.accent,
    required this.onSelected,
    super.key,
  });

  final MfExploreCategoryFilter selected;
  final Color accent;
  final ValueChanged<MfExploreCategoryFilter> onSelected;

  static const items = <(MfExploreCategoryFilter, IconData, String)>[
    (MfExploreCategoryFilter.all, Icons.apps_rounded, 'All Funds'),
    (MfExploreCategoryFilter.equity, Icons.show_chart_rounded, 'Equity'),
    (MfExploreCategoryFilter.hybrid, Icons.pie_chart_outline_rounded, 'Hybrid'),
    (MfExploreCategoryFilter.debt, Icons.account_balance_outlined, 'Debt'),
    (MfExploreCategoryFilter.indexFunds, Icons.stacked_line_chart, 'Index'),
  ];

  static String labelFor(MfExploreCategoryFilter f) =>
      items.firstWhere((e) => e.$1 == f).$3;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.md),
              child: _CircleCategory(
                label: item.$3,
                icon: item.$2,
                selected: selected == item.$1,
                accent: accent,
                onTap: () => onSelected(item.$1),
              ),
            ),
        ],
      ),
    );
  }
}

class _CircleCategory extends StatelessWidget {
  const _CircleCategory({
    required this.label,
    required this.icon,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = selected
        ? accent.withValues(alpha: 0.2)
        : context.cardColor;
    final border = selected
        ? accent.withValues(alpha: 0.7)
        : context.borderColor;
    final fg = selected ? accent : context.textSecondary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: bg,
                shape: BoxShape.circle,
                border: Border.all(color: border, width: selected ? 1.5 : 1),
              ),
              child: Icon(icon, color: fg, size: 22),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: context.text.caption().copyWith(
                    color: selected
                        ? context.textPrimary
                        : context.textSecondary,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
