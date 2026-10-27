import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';

/// Grouped tile view. Default [today] is LTP + day ₹ + %.
enum MoverMetric { today, pnl, cost }

const kMoverMetrics = [MoverMetric.today, MoverMetric.pnl, MoverMetric.cost];

String moverMetricLabel(MoverMetric metric) {
  switch (metric) {
    case MoverMetric.today:
      return 'Today';
    case MoverMetric.pnl:
      return 'P&L';
    case MoverMetric.cost:
      return 'Cost';
  }
}

/// Shared Gainers / Losers chrome for Overview and See Top 10.
class MoversGainersLosersTabs extends StatelessWidget {
  const MoversGainersLosersTabs({
    super.key,
    required this.showGainers,
    required this.gainersCount,
    required this.losersCount,
    required this.onSelectGainers,
    required this.onSelectLosers,
  });

  final bool showGainers;
  final int gainersCount;
  final int losersCount;
  final VoidCallback onSelectGainers;
  final VoidCallback onSelectLosers;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.colors.marketBorderDefault.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _Tab(
              label: 'Gainers ($gainersCount)',
              selected: showGainers,
              onTap: onSelectGainers,
            ),
          ),
          Expanded(
            child: _Tab(
              label: 'Losers ($losersCount)',
              selected: !showGainers,
              onTap: onSelectLosers,
            ),
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context)
        .textTheme
        .bodyMedium
        ?.color
        ?.withValues(alpha: 0.5);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          constraints: const BoxConstraints(minHeight: 40),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? ModuleColors.portfolio : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? Colors.white : muted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Smaller pills under Gainers/Losers. Default selection is Today.
class MoversMetricChips extends StatelessWidget {
  const MoversMetricChips({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  final MoverMetric selected;
  final ValueChanged<MoverMetric> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: context.colors.marketBorderDefault.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          for (final m in kMoverMetrics)
            Expanded(
              child: _MetricChip(
                label: moverMetricLabel(m),
                selected: selected == m,
                onTap: () => onSelect(m),
              ),
            ),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context)
        .textTheme
        .bodyMedium
        ?.color
        ?.withValues(alpha: 0.5);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          constraints: const BoxConstraints(minHeight: 28),
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          decoration: BoxDecoration(
            color: selected ? ModuleColors.portfolio : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? Colors.white : muted,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
