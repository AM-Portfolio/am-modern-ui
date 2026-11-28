import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';

import '../../data/mf_scheme_view.dart';
import 'mf_category_icon_row.dart';

/// Mock-style dropdown filter row for Explore.
class MfExploreFilterBar extends StatelessWidget {
  const MfExploreFilterBar({
    required this.accent,
    required this.category,
    required this.optionFilter,
    required this.riskFilter,
    required this.amcFilter,
    required this.amcOptions,
    required this.period,
    required this.purchaseOnly,
    required this.onCategory,
    required this.onOption,
    required this.onRisk,
    required this.onAmc,
    required this.onPeriod,
    required this.onPurchaseOnly,
    super.key,
  });

  final Color accent;
  final MfExploreCategoryFilter category;
  final MfExploreOptionFilter optionFilter;
  final MfExploreRiskFilter riskFilter;
  final String? amcFilter;
  final List<String> amcOptions;
  final MfReturnPeriod period;
  final bool purchaseOnly;
  final ValueChanged<MfExploreCategoryFilter> onCategory;
  final ValueChanged<MfExploreOptionFilter> onOption;
  final ValueChanged<MfExploreRiskFilter> onRisk;
  final ValueChanged<String?> onAmc;
  final ValueChanged<MfReturnPeriod> onPeriod;
  final ValueChanged<bool> onPurchaseOnly;

  static const _periods = [
    MfReturnPeriod.m1,
    MfReturnPeriod.m3,
    MfReturnPeriod.y1,
    MfReturnPeriod.y3,
    MfReturnPeriod.y5,
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _Drop<MfExploreCategoryFilter>(
            label: 'Category',
            value: category,
            items: MfExploreCategoryFilter.values,
            itemLabel: MfCategoryIconRow.labelFor,
            onChanged: onCategory,
            accent: accent,
          ),
          const SizedBox(width: AppSpacing.sm),
          _Drop<MfExploreRiskFilter>(
            label: 'Risk',
            value: riskFilter,
            items: MfExploreRiskFilter.values,
            itemLabel: (r) => r.label,
            onChanged: onRisk,
            accent: accent,
          ),
          const SizedBox(width: AppSpacing.sm),
          _Drop<String?>(
            label: 'AMC',
            value: amcFilter,
            items: [null, ...amcOptions],
            itemLabel: (a) => a ?? 'All AMCs',
            onChanged: onAmc,
            accent: accent,
          ),
          const SizedBox(width: AppSpacing.sm),
          _Drop<MfReturnPeriod>(
            label: 'Return period',
            value: period,
            items: _periods,
            itemLabel: (p) => p.label,
            onChanged: onPeriod,
            accent: accent,
          ),
          const SizedBox(width: AppSpacing.sm),
          _Drop<MfExploreOptionFilter>(
            label: 'Options',
            value: optionFilter,
            items: MfExploreOptionFilter.values,
            itemLabel: (o) => o.label,
            onChanged: onOption,
            accent: accent,
          ),
          const SizedBox(width: AppSpacing.sm),
          _Drop<bool>(
            label: 'Buyable',
            value: purchaseOnly,
            items: const [true, false],
            itemLabel: (b) => b ? 'Buyable only' : 'All schemes',
            onChanged: onPurchaseOnly,
            accent: accent,
          ),
        ],
      ),
    );
  }
}

class _Drop<T> extends StatelessWidget {
  const _Drop({
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
    required this.accent,
  });

  final String label;
  final T value;
  final List<T> items;
  final String Function(T) itemLabel;
  final ValueChanged<T> onChanged;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: context.borderColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isDense: true,
          borderRadius: BorderRadius.circular(AppRadii.md),
          dropdownColor: context.cardColor,
          style: context.text.label().copyWith(color: context.textPrimary),
          iconEnabledColor: accent,
          hint: Text(label),
          items: [
            for (final item in items)
              DropdownMenuItem(
                value: item,
                child: Text(itemLabel(item)),
              ),
          ],
          onChanged: (v) {
            if (v != null || items.contains(null)) {
              onChanged(v as T);
            }
          },
        ),
      ),
    );
  }
}
