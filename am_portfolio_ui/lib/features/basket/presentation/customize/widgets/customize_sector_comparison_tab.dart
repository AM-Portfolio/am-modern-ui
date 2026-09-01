import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';

import '../../../domain/models/basket_opportunity.dart';

class CustomizeSectorComparisonTab extends StatelessWidget {
  final BasketOpportunity originalOpportunity;
  final List<BasketItem> myBasketItems;
  final bool hasCalculated;
  final bool includeHeld;

  const CustomizeSectorComparisonTab({
    super.key,
    required this.originalOpportunity,
    required this.myBasketItems,
    required this.hasCalculated,
    required this.includeHeld,
  });

  Color _getColorForSector(String sector) {
    return ComparisonChartColors.forIndex(sector.hashCode.abs());
  }

  @override
  Widget build(BuildContext context) {
    if (!hasCalculated) {
      return const Center(
        child: Text('Please calculate the basket to see the sector analysis.'),
      );
    }
    final activeItems = includeHeld
        ? myBasketItems
        : myBasketItems.where((i) => i.status != ItemStatus.held).toList();

    final Map<String, double> etfSectorWeights = {};
    final Map<String, double> mySectorWeights = {};
    double myTotalWeight = 0;

    for (var item in originalOpportunity.composition) {
      etfSectorWeights[item.sector] =
          (etfSectorWeights[item.sector] ?? 0) + item.etfWeight;
    }
    for (var item in activeItems) {
      double weight = 0;
      if (item.lastPrice != null && (item.buyQuantity ?? 0.0) > 0) {
        weight = item.lastPrice! * (item.buyQuantity ?? 0.0);
      }
      mySectorWeights[item.sector] =
          (mySectorWeights[item.sector] ?? 0) + weight;
      myTotalWeight += weight;
    }
    if (myTotalWeight > 0) {
      mySectorWeights
          .updateAll((key, value) => (value / myTotalWeight) * 100);
    }

    final allSectors =
        {...etfSectorWeights.keys, ...mySectorWeights.keys}.toList();
    allSectors.sort(
        (a, b) => (etfSectorWeights[b] ?? 0).compareTo(etfSectorWeights[a] ?? 0));

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: allSectors.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final sector = allSectors[index];
        final etfPct = etfSectorWeights[sector] ?? 0.0;
        final myPct = mySectorWeights[sector] ?? 0.0;
        final color = _getColorForSector(sector);

        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  sector,
                  style:
                      const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'ETF: ${etfPct.toStringAsFixed(1)}% | My: ${myPct.toStringAsFixed(1)}%',
                style: TextStyle(fontSize: 10, color: context.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(children: [
            Expanded(
              child: LinearProgressIndicator(
                value: etfPct / 100,
                backgroundColor: context.dividerColor,
                color: context.textTertiary,
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: LinearProgressIndicator(
                value: myPct / 100,
                backgroundColor: color.withValues(alpha: 0.2),
                color: color,
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ]),
        ]);
      },
    );
  }
}
