import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';

/// Row emphasis for Top Movers. Default [value] leads with ₹ amounts.
enum MoversDisplayMode { value, percentage }

String moversDisplayModeLabel(
  MoversDisplayMode mode, {
  bool compact = false,
}) {
  switch (mode) {
    case MoversDisplayMode.value:
      return 'Value';
    case MoversDisplayMode.percentage:
      return compact ? '%' : 'Percentage';
  }
}

/// Shared Gainers / Losers chrome for Overview and See Top 10.
class MoversGainersLosersTabs extends StatelessWidget {
  const MoversGainersLosersTabs({
    super.key,
    required this.showGainers,
    required this.onSelectGainers,
    required this.onSelectLosers,
  });

  final bool showGainers;
  final VoidCallback onSelectGainers;
  final VoidCallback onSelectLosers;

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
          Expanded(
            child: _Tab(
              label: 'Gainers',
              selected: showGainers,
              onTap: onSelectGainers,
            ),
          ),
          Expanded(
            child: _Tab(
              label: 'Losers',
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
    final scheme = Theme.of(context).colorScheme;
    final selectedFg = scheme.onPrimary;
    final muted = scheme.onSurfaceVariant;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          constraints: const BoxConstraints(minHeight: 32),
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: selected ? ModuleColors.portfolio : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? selectedFg : muted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact Value | Percentage segmented control for card trailing / modal.
class MoversDisplayModeToggle extends StatelessWidget {
  const MoversDisplayModeToggle({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  final MoversDisplayMode selected;
  final ValueChanged<MoversDisplayMode> onSelect;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Trailing slot on ~380px cards is often <180px — prefer short labels
        // before scaling so the control stays readable.
        final maxW = constraints.maxWidth;
        final narrow = !maxW.isFinite || maxW <= 0 || maxW < 180;
        final track = Container(
          height: 32,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: context.colors.marketBorderDefault.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context)
                  .colorScheme
                  .outline
                  .withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final mode in MoversDisplayMode.values)
                _ModeChip(
                  label: moversDisplayModeLabel(mode, compact: narrow),
                  selected: selected == mode,
                  onTap: () => onSelect(mode),
                ),
            ],
          ),
        );
        return Align(
          alignment: Alignment.centerRight,
          child: maxW.isFinite && maxW > 0
              ? FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: track,
                )
              : track,
        );
      },
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final selectedFg = scheme.onPrimary;
    final muted = scheme.onSurfaceVariant;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 26,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: selected ? ModuleColors.portfolio : Colors.transparent,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              height: 1.1,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? selectedFg : muted,
            ),
          ),
        ),
      ),
    );
  }
}
