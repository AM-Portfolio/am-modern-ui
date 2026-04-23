import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import '../../internal/domain/entities/portfolio_analytics.dart';
import 'package:am_common/am_common.dart';

/// Widget displaying sectorial allocation of the portfolio
/// Shows distribution of investments across different sectors using bars
class SectorialAllocationWidget extends StatelessWidget {
  const SectorialAllocationWidget({
    super.key,
    this.sectorAllocation,
    this.isLoading = false,
    this.error,
  });
  final SectorAllocation? sectorAllocation;
  final bool isLoading;
  final String? error;

  @override
  Widget build(BuildContext context) => Card(
    elevation: 4,
    margin: const EdgeInsets.all(8.0),
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.donut_small,
                color: Theme.of(context).primaryColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Sector Allocation',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(height: 300, child: _buildContent(context)),
        ],
      ),
    ),
  );

  Widget _buildContent(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.error,
              size: 48,
            ),
            const SizedBox(height: 8),
            Text(
              'Failed to load sector data',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              error!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    CommonLogger.debug(
      '🔍 SectorialAllocationWidget: sectorAllocation=${sectorAllocation != null ? 'not null' : 'null'}, '
      'sectorWeights count=${sectorAllocation?.sectorWeights.length ?? 0}',
      tag: 'SectorialAllocationWidget',
    );

    // Let's inspect the actual data structure
    if (sectorAllocation != null) {
      CommonLogger.debug(
        '🔍 SectorialAllocationWidget: Full sectorAllocation object: $sectorAllocation',
        tag: 'SectorialAllocationWidget',
      );
      CommonLogger.debug(
        '🔍 SectorialAllocationWidget: sectorWeights details: ${sectorAllocation!.sectorWeights}',
        tag: 'SectorialAllocationWidget',
      );
    }

    if (sectorAllocation == null || sectorAllocation!.sectorWeights.isEmpty) {
      CommonLogger.debug(
        '🔍 SectorialAllocationWidget: Showing no data message - sectorAllocation is ${sectorAllocation == null ? 'null' : 'empty'}',
        tag: 'SectorialAllocationWidget',
      );
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.data_usage_outlined,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              size: 48,
            ),
            const SizedBox(height: 8),
            Text(
              'No sector data available',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return _buildSectorBars(context);
  }

  Widget _buildSectorBars(BuildContext context) {
    final sectorWeights = sectorAllocation!.sectorWeights;
    final colors = _generateColors(sectorWeights.length);

    return SingleChildScrollView(
      child: Column(
        children: sectorWeights.asMap().entries.map((entry) {
          final index = entry.key;
          final sectorWeight = entry.value;

          return Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        sectorWeight.sectorName,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${sectorWeight.weightPercentage.toStringAsFixed(1)}%',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colors[index],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: sectorWeight.weightPercentage / 100,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(colors[index]),
                ),
                const SizedBox(height: 4),
                Text(
                  '₹${_formatCurrency(sectorWeight.marketCap)} • ${sectorWeight.topStocks.take(2).join(', ')}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  List<Color> _generateColors(int count) {
    final baseColors = [
      const Color(0xFF2196F3), // Blue
      const Color(0xFF4CAF50), // Green
      const Color(0xFFFF9800), // Orange
      const Color(0xFF9C27B0), // Purple
      const Color(0xFFF44336), // Red
      const Color(0xFF00BCD4), // Cyan
      const Color(0xFFFFEB3B), // Yellow
      const Color(0xFF795548), // Brown
      const Color(0xFF607D8B), // Blue Grey
      const Color(0xFFE91E63), // Pink
    ];

    final colors = <Color>[];
    for (var i = 0; i < count; i++) {
      colors.add(baseColors[i % baseColors.length]);
    }
    return colors;
  }

  String _formatCurrency(double value) {
    if (value >= 10000000) {
      return '${(value / 10000000).toStringAsFixed(1)}Cr';
    } else if (value >= 100000) {
      return '${(value / 100000).toStringAsFixed(1)}L';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    } else {
      return value.toStringAsFixed(0);
    }
  }
}

