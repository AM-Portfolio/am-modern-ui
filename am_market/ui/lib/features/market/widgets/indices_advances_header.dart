import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:am_market_ui/features/market/widgets/market_colors.dart';
import 'package:am_market_ui/features/market/widgets/ranked_index_helpers.dart';

/// Indian | Global | All segment control for ranked indices lists.
class IndicesListFilterToggle extends StatelessWidget {
  const IndicesListFilterToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final IndicesListFilter value;
  final ValueChanged<IndicesListFilter> onChanged;

  Color _accent(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorsTheme>();
    return colors?.actionPrimaryBg ?? const Color(0xFFC9A84C);
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accent(context);
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
        children: IndicesListFilter.values.map((filter) {
          final selected = value == filter;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(filter),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: selected
                      ? accent.withValues(alpha: 0.18)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: selected
                      ? Border.all(color: accent, width: 1)
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  filter.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: selected
                        ? accent
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

/// "Ranked by Top Gainers • N Advances / M Declines" + optional time.
class IndicesAdvancesHeader extends StatelessWidget {
  const IndicesAdvancesHeader({
    super.key,
    required this.advances,
    required this.declines,
    this.clockLabel,
  });

  final int advances;
  final int declines;
  final String? clockLabel;

  @override
  Widget build(BuildContext context) {
    final muted = MarketColors.textMuted(context);
    final colors = Theme.of(context).extension<AppColorsTheme>();
    final gain = colors?.actionPrimaryBg ?? const Color(0xFFC9A84C);
    final neg = MarketColors.negative(context);

    return Row(
      children: [
        Expanded(
          child: Text.rich(
            TextSpan(
              style: TextStyle(fontSize: 11, color: muted, height: 1.25),
              children: [
                const TextSpan(text: 'Ranked by Top Gainers • '),
                TextSpan(
                  text: '$advances Advances',
                  style: TextStyle(
                    color: gain,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const TextSpan(text: ' / '),
                TextSpan(
                  text: '$declines Declines',
                  style: TextStyle(
                    color: declines > 0 ? neg : muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (clockLabel != null && clockLabel!.isNotEmpty)
          Text(
            clockLabel!,
            style: TextStyle(fontSize: 11, color: muted),
          ),
      ],
    );
  }
}
