import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';

import '../../../domain/models/basket_opportunity.dart';

class CustomizeBasketComparisonTab extends StatelessWidget {
  final BasketOpportunity originalOpportunity;
  final List<BasketItem> myBasketItems;
  final bool hasCalculated;
  final bool includeHeld;

  const CustomizeBasketComparisonTab({
    super.key,
    required this.originalOpportunity,
    required this.myBasketItems,
    required this.hasCalculated,
    required this.includeHeld,
  });

  @override
  Widget build(BuildContext context) {
    if (!hasCalculated) {
      return const Center(
        child: Text('Please calculate the basket to see the comparison.'),
      );
    }
    final activeItems = includeHeld
        ? myBasketItems
        : myBasketItems.where((i) => i.status != ItemStatus.held).toList();

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 24,
          headingRowHeight: 40,
          dataRowMinHeight: 36,
          dataRowMaxHeight: 44,
          columns: const [
            DataColumn(
                label: Text('Constituent',
                    style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(
                label: Text('ETF Wt.',
                    style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(
                label: Text('Action',
                    style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(
                label: Text('My Basket',
                    style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: activeItems.map((item) {
            final isMissing = item.status == ItemStatus.missing;
            final isSubstitute = item.status == ItemStatus.substitute;
            double pct = 0;
            double totalActiveInvestment = 0;
            for (var i in activeItems) {
              if (i.lastPrice != null && i.buyQuantity != null) {
                totalActiveInvestment += i.lastPrice! * i.buyQuantity!;
              }
            }
            if (totalActiveInvestment > 0 && item.lastPrice != null) {
              pct = (item.lastPrice! * (item.buyQuantity ?? 0.0) /
                      totalActiveInvestment) *
                  100;
            }
            Widget actionWidget;
            if (isMissing) {
              actionWidget = Text('EXCLUDED',
                  style: TextStyle(
                      color: context.statusError,
                      fontSize: 10,
                      fontWeight: FontWeight.bold));
            } else if (isSubstitute) {
              actionWidget = Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                    color: ModuleColors.portfolio.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4)),
                child: Text('SUB: ${item.userHoldingSymbol}',
                    style: TextStyle(
                        color: ModuleColors.portfolio,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              );
            } else if (item.status == ItemStatus.held) {
              actionWidget = Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                    color: context.statusSuccess.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4)),
                child: Text('HELD',
                    style: TextStyle(
                        color: context.statusSuccess,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              );
            } else {
              actionWidget = Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                    color: context.statusSuccess.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4)),
                child: Text('BUY',
                    style: TextStyle(
                        color: context.statusSuccess,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              );
            }
            return DataRow(cells: [
              DataCell(Text(item.stockSymbol,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13))),
              DataCell(Text('${item.etfWeight.toStringAsFixed(1)}%',
                  style: const TextStyle(fontSize: 13))),
              DataCell(actionWidget),
              DataCell(Text(
                isMissing ? '-' : '${pct.toStringAsFixed(1)}%',
                style: TextStyle(
                    color: isMissing
                        ? context.textTertiary
                        : context.statusSuccess,
                    fontWeight: FontWeight.bold,
                    fontSize: 13),
              )),
            ]);
          }).toList(),
        ),
      ),
    );
  }
}
