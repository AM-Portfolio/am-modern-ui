import 'package:am_dashboard_ui/domain/models/allocation_response.dart';
import 'package:am_design_system/am_design_system.dart' as ds;
import 'package:flutter/material.dart';

class DashboardAllocationWidget extends StatelessWidget {
  final AllocationResponse allocation;

  const DashboardAllocationWidget({super.key, required this.allocation});

  @override
  Widget build(BuildContext context) {
    if (allocation.sectors.isEmpty) return const SizedBox.shrink();

    // Map backend DomainAllocationItem to design system AllocationItem
    final allocations = allocation.sectors.map((item) {
      return ds.AllocationItem(
        label: item.name,
        value: item.value,
        percentage: item.percentage,
        count: item.count,
      );
    }).toList();
    
    // Sort by value desc
    allocations.sort((a, b) => b.value.compareTo(a.value));

    return ds.AppCard(
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
              child: ds.AnimatedSectorDonutChart(
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
