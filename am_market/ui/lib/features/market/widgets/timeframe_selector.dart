import 'package:flutter/material.dart';
import 'market_header.dart';

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

    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: ['1D', '1W', '1M', '3M', '6M', '1Y', '5Y'].map((tf) {
        final isSelected = tf == selectedTimeframe;
        return _buildTimeframeButton(tf, isSelected);
      }).toList(),
    );

    final container = Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: MarketColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: MarketColors.border,
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

  Widget _buildTimeframeButton(String tf, bool isSelected) {
    return GestureDetector(
      onTap: () => onTimeframeChanged(tf),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
          decoration: BoxDecoration(
            color: isSelected ? MarketColors.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 150),
            style: TextStyle(
              color: isSelected ? MarketColors.accentText : MarketColors.textMuted,
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
