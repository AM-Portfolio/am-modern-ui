import 'package:am_dashboard_ui/domain/models/allocation_response.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'glass_card.dart';

/// Pixel-perfect Lumina allocation widget based on image.
/// Donut chart top (perfectly centered), scrollable vertical legend below it.
/// Supports Dark Mode and Glassmorphism.
class DashboardAllocationWidget extends StatelessWidget {
  final AllocationResponse allocation;

  const DashboardAllocationWidget({
    super.key,
    required this.allocation,
  });

  @override
  Widget build(BuildContext context) {
    if (allocation.sectors.isEmpty) return const SizedBox.shrink();

    // Sort by value
    final sortedSectors = List.of(allocation.sectors)
      ..sort((a, b) => b.value.compareTo(a.value));

    // Calculate total assets correctly
    final totalAssets = allocation.sectors.fold<int>(0, (sum, s) => sum + s.count);
    final totalValue = allocation.sectors.fold<double>(0.0, (sum, s) => sum + s.value);

    // Mapping colors for legend matching standard palette
    final colors = [
      const Color(0xFF2C2F8A), // Dark blue
      const Color(0xFF00E5FF), // Cyan
      const Color(0xFFFF9100), // Orange
      const Color(0xFFD50000), // Red
      const Color(0xFF00C853), // Green
      const Color(0xFFAA00FF), // Purple
      const Color(0xFFFFD600), // Yellow
    ];

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = isDark ? Colors.white : const Color(0xFF111827);
    final onSurfaceVariant = isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280);

    return AmGlassCard(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Allocation',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: onSurface,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 32),
          
          // Donut area using fl_chart directly for perfect alignment
          Center(
            child: SizedBox(
              height: 160,
              width: 160,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      sectionsSpace: 0,
                      centerSpaceRadius: 60,
                      startDegreeOffset: -90,
                      sections: totalValue == 0 
                          ? [
                              PieChartSectionData(
                                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                value: 1,
                                title: '',
                                radius: 20,
                              )
                            ]
                          : sortedSectors.asMap().entries.map((entry) {
                              final index = entry.key;
                              final item = entry.value;
                              final color = colors[index % colors.length];
                              return PieChartSectionData(
                                color: color,
                                value: item.value > 0 ? item.value : 0.01, 
                                title: '', // No title on sections
                                radius: 20,
                              );
                            }).toList(),
                    ),
                  ),
                  // Center text perfectly aligned in the Stack
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        totalAssets.toString(),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: onSurface,
                          fontFamily: 'Inter',
                        ),
                      ),
                      Text(
                        'ASSETS',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: onSurfaceVariant,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Legend list - Wrap in Expanded/ListView for scrollability
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 180),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: sortedSectors.length,
              itemBuilder: (context, index) {
                final item = sortedSectors[index];
                final color = colors[index % colors.length];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item.name,
                          style: TextStyle(
                            fontSize: 12,
                            color: onSurfaceVariant,
                            fontFamily: 'Inter',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${item.percentage.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: onSurface,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
