import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:am_market_common/models/indices_performance_model.dart';
import 'package:am_market_ui/features/market_analysis/presentation/widgets/performance_ranking_dialog.dart';
import 'package:am_market_ui/core/styles/am_text_styles.dart';
import 'package:am_market_ui/core/styles/market_theme_extension.dart';

class MonthlyPerformanceCard extends StatefulWidget {
  final MonthlyIndicesPerformance data;
  final bool isCompactTable;
  final String? focusSymbol;

  const MonthlyPerformanceCard({
    Key? key,
    required this.data,
    this.isCompactTable = false,
    this.focusSymbol,
  }) : super(key: key);

  @override
  State<MonthlyPerformanceCard> createState() => _MonthlyPerformanceCardState();
}

class _MonthlyPerformanceCardState extends State<MonthlyPerformanceCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final marketTheme = context.marketTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Table Mode: Single Line (Top Performer Only)
    if (widget.isCompactTable) {
      final perf = widget.data.resolvedTopPerformer;
      if (perf == null) return const SizedBox();

      final isPositive = perf.returnPercentage >= 0;
      final textColor =
          isPositive ? marketTheme.positive : marketTheme.negative;
      final bgColor = textColor.withValues(alpha: isDark ? 0.20 : 0.10);

      return MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedScale(
          scale: _isHovered ? 1.12 : 1.0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          child: InkWell(
            onTap: () => _showRanking(context),
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 8), // More internal padding
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(6),
              border: Border.all(color: textColor.withValues(alpha: 0.3)),
                boxShadow: _isHovered
                    ? [
                        BoxShadow(
                          color: textColor.withValues(alpha: 0.6),
                          blurRadius: 12,
                          spreadRadius: 1,
                        )
                      ]
                    : [],
              ),
              child: Row(
                children: [
                  // Full Index Name
                  Expanded(
                    child: Text(
                      perf.symbol,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Percentage
                  Text(
                    '${isPositive ? '+' : ''}${perf.returnPercentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 6),
                  // View Icon
                  Icon(Icons.open_in_new, size: 10, color: colors.textTertiary)
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Default Card Mode
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? 1.02 : 1.0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        child: InkWell(
          onTap: () => _showRanking(context),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: colors.cardSurface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: colors.border.withValues(alpha: 0.35)),
              boxShadow: isDark
                  ? []
                  : [
                      BoxShadow(
                        color: context.shadow(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${widget.data.monthName.substring(0, 3)} ${widget.data.year}',
                      style: AmTextStyles.caption.copyWith(
                        color: colors.textSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Icon(Icons.remove_red_eye_outlined,
                        size: 12,
                        color: colors.textTertiary),
                  ],
                ),

                const Spacer(),

                if (widget.data.topPerformer != null)
                  _buildCompactRow(context, "Top", widget.data.topPerformer!),

                const SizedBox(height: 4),

                if (widget.data.worstPerformer != null)
                  _buildCompactRow(context, "Bot", widget.data.worstPerformer!),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactRow(
      BuildContext context, String label, IndexPerformance perf) {
    final isPositive = perf.returnPercentage >= 0;
    final colors = context.colors;
    final marketTheme = context.marketTheme;
    final textColor = isPositive ? marketTheme.positive : marketTheme.negative;
    final bgColor = textColor.withValues(alpha: 0.14);

    return Row(
      children: [
        // Label (Top/Bot)
        SizedBox(
          width: 24,
          child: Text(
            label,
            style: TextStyle(
                color: colors.textTertiary, fontSize: 10),
          ),
        ),
        // Badge
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    perf.symbol,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                Text(
                  '${isPositive ? '+' : ''}${perf.returnPercentage.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showRanking(BuildContext context) {
    // Mobile: bottom sheet; desktop: dialog (see PerformanceRankingDialog.show).
    PerformanceRankingDialog.show(
      context,
      widget.data,
      focusSymbol: widget.focusSymbol,
    );
  }
}
