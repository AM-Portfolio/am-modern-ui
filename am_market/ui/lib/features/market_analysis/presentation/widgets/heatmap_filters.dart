import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:am_market_ui/features/market/widgets/market_colors.dart';

class HeatmapFilters extends StatelessWidget {
  final String? percentFilter;
  final ValueChanged<String?> onPercentFilterChanged;
  final List<String> filters;
  final String? title;

  const HeatmapFilters({
    super.key,
    required this.percentFilter,
    required this.onPercentFilterChanged,
    this.filters = const [
      'Above +5%',
      '+2 to +5%',
      '0 to +2%',
      '0 to -2%',
      '-2 to -5%',
      'Below -5%',
    ],
    this.title,
  });

  Color _filterColor(BuildContext context, String f) {
    final pos = MarketColors.positive(context);
    final neg = MarketColors.negative(context);
    if (f.contains('Above')) return pos;
    if (f.contains('+2')) return Color.lerp(pos, context.colors.surface, 0.15)!;
    if (f.contains('0 to +2')) {
      return Color.lerp(pos, context.colors.surface, 0.35)!;
    }
    if (f.contains('0 to -2')) {
      return Color.lerp(neg, context.colors.surface, 0.35)!;
    }
    if (f.contains('-2 to')) {
      return Color.lerp(neg, context.colors.surface, 0.15)!;
    }
    return neg;
  }

  Widget _chip(BuildContext context, String f) {
    final isSelected = percentFilter == f;
    final selectedColor = _filterColor(context, f);
    final onSelected = context.colors.actionPrimaryFg;

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(f, style: const TextStyle(fontSize: 11)),
        selected: isSelected,
        onSelected: (selected) {
          onPercentFilterChanged(selected ? f : null);
        },
        backgroundColor: MarketColors.cardSurface(context),
        selectedColor: selectedColor,
        checkmarkColor: onSelected,
        labelStyle: TextStyle(
          color: isSelected
              ? onSelected
              : MarketColors.textSecondary(context),
        ),
        side: BorderSide(
          color: isSelected
              ? selectedColor
              : MarketColors.borderDefault(context),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: const EdgeInsets.symmetric(horizontal: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 768;

    // Mobile Focus Mode: one horizontal chip row, no tall card chrome.
    if (isMobile) {
      return SizedBox(
        height: 40,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          children: [
            if (title != null) ...[
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Text(
                    title!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: MarketColors.textPrimary(context),
                    ),
                  ),
                ),
              ),
            ],
            ...filters.map((f) => _chip(context, f)),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      width: double.infinity,
      decoration: BoxDecoration(
        color: MarketColors.cardSurface(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        border: Border(
          bottom: BorderSide(color: MarketColors.borderDefault(context)),
        ),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: [
          if (title != null)
            Text(
              title!,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: MarketColors.textPrimary(context),
              ),
            ),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: filters.map((f) => _chip(context, f)).toList(),
          ),
        ],
      ),
    );
  }
}
