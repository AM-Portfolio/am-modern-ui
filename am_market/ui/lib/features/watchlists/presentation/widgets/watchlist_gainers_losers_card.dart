import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';

class WatchlistGainersLosersCard extends StatelessWidget {
  final int gainers;
  final int losers;
  final int unchanged;

  const WatchlistGainersLosersCard({
    super.key,
    required this.gainers,
    required this.losers,
    required this.unchanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border.withValues(alpha: 0.5)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      child: Row(
        children: [
          Expanded(
            child: _buildColumn(
              title: 'Gainers',
              count: gainers,
              countColor: colors.marketPositiveIndicator,
              colors: colors,
            ),
          ),
          Container(
            height: 36,
            width: 1,
            color: colors.border.withValues(alpha: 0.4),
          ),
          Expanded(
            child: _buildColumn(
              title: 'Losers',
              count: losers,
              countColor: colors.marketNegativeIndicator,
              colors: colors,
            ),
          ),
          Container(
            height: 36,
            width: 1,
            color: colors.border.withValues(alpha: 0.4),
          ),
          Expanded(
            child: _buildColumn(
              title: 'Unchanged',
              count: unchanged,
              countColor: colors.textSecondary,
              colors: colors,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColumn({
    required String title,
    required int count,
    required Color countColor,
    required dynamic colors,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '$count',
          style: TextStyle(
            color: countColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
