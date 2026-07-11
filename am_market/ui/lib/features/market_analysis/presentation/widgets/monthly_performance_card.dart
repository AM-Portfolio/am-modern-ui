import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:am_market_common/models/indices_performance_model.dart';
import 'package:am_market_ui/features/market_analysis/presentation/widgets/performance_ranking_dialog.dart';
import 'package:am_market_ui/core/styles/am_text_styles.dart';

class MonthlyPerformanceCard extends StatefulWidget {
  final MonthlyIndicesPerformance data;
  final bool isCompactTable;

  const MonthlyPerformanceCard({Key? key, required this.data, this.isCompactTable = false}) : super(key: key);

  @override
  State<MonthlyPerformanceCard> createState() => _MonthlyPerformanceCardState();
}

class _MonthlyPerformanceCardState extends State<MonthlyPerformanceCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Table Mode: Single Line (Top Performer Only)
    if (widget.isCompactTable) {
       final perf = widget.data.topPerformer;
       if (perf == null) return const SizedBox();

       final isPositive = perf.returnPercentage >= 0;
       final bgColor = isDark
           ? (isPositive 
                ? const Color(0xFF1B5E20).withOpacity(0.3) 
                : const Color(0xFFB71C1C).withOpacity(0.3))
           : (isPositive 
                ? const Color(0xFFE8F5E9) 
                : const Color(0xFFFFEBEE));
       final textColor = isDark
           ? (isPositive ? const Color(0xFF69F0AE) : const Color(0xFFFF5252))
           : (isPositive ? const Color(0xFF2E7D32) : const Color(0xFFC62828));

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
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8), // More internal padding
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: textColor.withOpacity(0.3)),
              boxShadow: _isHovered ? [
                BoxShadow(
                  color: textColor.withOpacity(0.6),
                  blurRadius: 12,
                  spreadRadius: 1,
                )
              ] : [],
            ),
            child: Row(
              children: [
                // Full Index Name
                Expanded(
                  child: Text(
                    perf.symbol,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 11, 
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.visible, // Wrapping allowed if needed, but expanded width should help
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
                 Icon(Icons.open_in_new, size: 10, color: isDark ? Colors.white.withOpacity(0.5) : Colors.black.withOpacity(0.4))
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
           color: isDark ? AppColors.darkCard : AppColors.lightCard,
           borderRadius: BorderRadius.circular(8),
           border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
           boxShadow: isDark
               ? []
               : [
                   BoxShadow(
                     color: Colors.black.withOpacity(0.04),
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
                     color: isDark ? Colors.white54 : Colors.black54,
                     fontWeight: FontWeight.bold,
                   ),
                 ),
                 Icon(Icons.remove_red_eye_outlined, size: 12, color: isDark ? Colors.white24 : Colors.black26),
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

  Widget _buildCompactRow(BuildContext context, String label, IndexPerformance perf) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPositive = perf.returnPercentage >= 0;
    // Darker Green/Red for background, brighter for text
    final bgColor = isDark
        ? (isPositive 
            ? const Color(0xFF1B5E20).withOpacity(0.4) // Dark Green
            : const Color(0xFFB71C1C).withOpacity(0.4)) // Dark Red
        : (isPositive 
            ? const Color(0xFFE8F5E9) 
            : const Color(0xFFFFEBEE));
    final textColor = isDark
        ? (isPositive ? const Color(0xFF69F0AE) : const Color(0xFFFF5252))
        : (isPositive ? const Color(0xFF2E7D32) : const Color(0xFFC62828));

    return Row(
      children: [
        // Label (Top/Bot)
        SizedBox(
          width: 24,
          child: Text(
            label,
            style: TextStyle(color: isDark ? Colors.white38 : Colors.black45, fontSize: 10),
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
                      color: isDark ? Colors.white.withOpacity(0.9) : Colors.black87,
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
    showDialog(
      context: context,
      builder: (ctx) => PerformanceRankingDialog(data: widget.data),
    );
  }
}
