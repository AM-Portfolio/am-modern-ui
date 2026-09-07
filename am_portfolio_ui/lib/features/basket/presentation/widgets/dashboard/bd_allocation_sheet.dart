import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:intl/intl.dart';
import '../../../domain/models/basket_detail.dart';
import 'bd_dashboard_math.dart';

class BdAllocationSheet extends StatelessWidget {
  final List<BasketLineDetail> lines;
  final double totalCurrentValue;

  const BdAllocationSheet({
    super.key,
    required this.lines,
    required this.totalCurrentValue,
  });

  static Future<void> show(
    BuildContext context, {
    required List<BasketLineDetail> lines,
    required double totalCurrentValue,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => BdAllocationSheet(lines: lines, totalCurrentValue: totalCurrentValue),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final sorted = BdDashboardMath.sortedByWeight(lines, totalCurrentValue);
    final colors = [
      ModuleColors.portfolio,
      context.statusSuccess,
      Colors.orangeAccent,
      Colors.blueAccent,
      Colors.teal,
      Colors.amber,
      Colors.cyan,
      const Color(0xFFF472B6),
      const Color(0xFFA78BFA),
    ];

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.55,
      maxChildSize: 0.85,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.colors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text('Allocation Breakdown', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: sorted.length,
                  itemBuilder: (context, index) {
                    final line = sorted[index];
                    final weight = BdDashboardMath.basketWeightPercent(line, totalCurrentValue);
                    final value = BdDashboardMath.lineCurrentValue(line);
                    final color = colors[index % colors.length];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Row(
                        children: [
                          Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                          const SizedBox(width: 8),
                          Expanded(child: Text(line.symbol, style: const TextStyle(fontWeight: FontWeight.bold))),
                          Text('${weight.toStringAsFixed(1)}%'),
                          const SizedBox(width: 12),
                          Text(fmt.format(value), style: TextStyle(color: context.colors.textSecondary)),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
