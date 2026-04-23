import 'package:am_dashboard_ui/domain/models/portfolio_overview.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';

class DashboardAllocationWidget extends StatelessWidget {
  final List<PortfolioOverview> overviews;

  const DashboardAllocationWidget({super.key, required this.overviews});

  @override
  Widget build(BuildContext context) {
    if (overviews.isEmpty) return const SizedBox.shrink();

    final totalValue = overviews.fold<double>(0, (sum, item) => sum + item.totalValue);
    
    // Convert to AllocationItem
    final allocations = overviews.map((overview) {
      double percentage = totalValue > 0 ? (overview.totalValue / totalValue) * 100 : 0;
      return AllocationItem(
        label: overview.type,
        value: overview.totalValue,
        percentage: percentage,
        count: overview.portfolioCount,
      );
    }).toList();
    
    // Sort by value desc
    allocations.sort((a, b) => b.value.compareTo(a.value));

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Text(
              'Portfolio Allocation',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: AnimatedSectorDonutChart(
                allocations: allocations,
                showAnimation: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
