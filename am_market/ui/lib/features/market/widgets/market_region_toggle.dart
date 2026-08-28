import 'package:flutter/material.dart';
import 'package:am_market_common/models/indices_region.dart';
import 'package:am_market_ui/features/market/widgets/market_colors.dart';

/// Indian | Global segment control for All Indices / Compare panels.
/// Uses [MarketColors] / theme tokens only — no hardcoded accent colors.
class MarketRegionToggle extends StatelessWidget {
  final IndicesRegion value;
  final ValueChanged<IndicesRegion> onChanged;

  const MarketRegionToggle({
    required this.value,
    required this.onChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: MarketColors.tfBarBg(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: MarketColors.borderDefault(context),
          width: MarketColors.borderWidth(context),
        ),
      ),
      child: Row(
        children: IndicesRegion.values.map((region) {
          final selected = value == region;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(region),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: selected
                      ? MarketColors.borderSelected(context).withValues(alpha: 0.18)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: selected
                      ? Border.all(
                          color: MarketColors.borderSelected(context),
                          width: 1,
                        )
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  region.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: selected
                        ? MarketColors.borderSelected(context)
                        : MarketColors.textMuted(context),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
