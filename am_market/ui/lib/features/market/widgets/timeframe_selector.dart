import 'package:flutter/material.dart';
import 'package:am_market_ui/core/styles/market_theme_extension.dart';

class TimeframeSelector extends StatelessWidget {
  final String selectedTimeframe;
  final ValueChanged<String> onTimeframeChanged;

  const TimeframeSelector({
    required this.selectedTimeframe,
    required this.onTimeframeChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    final mt = context.marketTheme;

    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: ['1D', '1W', '1M', '3M', '6M', '1Y', '5Y'].map((tf) {
        final isSelected = tf == selectedTimeframe;
        return _buildTimeframeButton(tf, isSelected, mt);
      }).toList(),
    );

    final container = Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: mt.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: mt.border,
          width: 1.0,
        ),
      ),
      child: isMobile
          ? SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: row,
            )
          : row,
    );

    return container;
  }

  Widget _buildTimeframeButton(String tf, bool isSelected, MarketThemeExtension mt) {
    return GestureDetector(
      onTap: () => onTimeframeChanged(tf),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
          decoration: BoxDecoration(
            color: isSelected ? mt.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 150),
            style: TextStyle(
              color: isSelected ? mt.accentText : mt.textMuted,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
            ),
            child: Text(tf),
          ),
        ),
      ),
    );
  }
}
