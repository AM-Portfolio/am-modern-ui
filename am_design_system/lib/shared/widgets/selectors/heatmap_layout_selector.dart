import 'package:flutter/material.dart';

import '../../../core/utils/common_logger.dart';

/// Enum for different heatmap layout types
enum HeatmapLayoutType { treemap, grid, list }

/// Extension to provide display properties for HeatmapLayoutType
extension HeatmapLayoutTypeExtension on HeatmapLayoutType {
  /// Display name for the layout type
  String get displayName {
    switch (this) {
      case HeatmapLayoutType.treemap:
        return 'Treemap';
      case HeatmapLayoutType.grid:
        return 'Grid';
      case HeatmapLayoutType.list:
        return 'List';
    }
  }

  /// Icon for the layout type
  IconData get icon {
    switch (this) {
      case HeatmapLayoutType.treemap:
        return Icons.view_module_outlined;
      case HeatmapLayoutType.grid:
        return Icons.grid_view_outlined;
      case HeatmapLayoutType.list:
        return Icons.view_list_outlined;
    }
  }

  /// Short name/code for the layout type
  String get code {
    switch (this) {
      case HeatmapLayoutType.treemap:
        return 'treemap';
      case HeatmapLayoutType.grid:
        return 'grid';
      case HeatmapLayoutType.list:
        return 'list';
    }
  }
}

/// Layout selector widget for choosing heatmap display layout
class HeatmapLayoutSelector extends StatefulWidget {
  const HeatmapLayoutSelector({
    required this.selectedLayout,
    required this.onLayoutChanged,
    super.key,
    this.availableLayouts = const [
      HeatmapLayoutType.treemap,
      HeatmapLayoutType.grid,
      HeatmapLayoutType.list,
    ],
    this.showLabel = true,
    this.isCompact = false,
  });

  /// Currently selected layout type
  final HeatmapLayoutType selectedLayout;

  /// Callback when layout selection changes
  final ValueChanged<HeatmapLayoutType> onLayoutChanged;

  /// Available layout options to show
  final List<HeatmapLayoutType> availableLayouts;

  /// Whether to show the "Layout" label
  final bool showLabel;

  /// Whether to use compact display
  final bool isCompact;

  @override
  State<HeatmapLayoutSelector> createState() => _HeatmapLayoutSelectorState();
}

class _HeatmapLayoutSelectorState extends State<HeatmapLayoutSelector> {
  @override
  Widget build(BuildContext context) {
    CommonLogger.debug(
      'LayoutSelector: current=${widget.selectedLayout.code}, '
      'available=${widget.availableLayouts.map((l) => l.code).join(',')}',
      tag: 'Selector.Layout',
    );

    if (widget.isCompact) {
      return _buildCompactSelector();
    } else {
      return _buildStandardSelector();
    }
  }

  Widget _buildStandardSelector() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (widget.showLabel)
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            children: [
              Icon(
                Icons.view_comfy_outlined,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                'Layout',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: widget.availableLayouts.map((layout) {
            final isSelected = layout == widget.selectedLayout;
            return _buildLayoutOption(layout, isSelected);
          }).toList(),
        ),
      ),
    ],
  );

  Widget _buildCompactSelector() => DropdownButton<HeatmapLayoutType>(
    value: widget.selectedLayout,
    onChanged: (newLayout) {
      if (newLayout != null) {
        _handleLayoutChange(newLayout);
      }
    },
    items: widget.availableLayouts
        .map(
          (layout) => DropdownMenuItem<HeatmapLayoutType>(
            value: layout,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(layout.icon, size: 16),
                const SizedBox(width: 8),
                Text(layout.displayName),
              ],
            ),
          ),
        )
        .toList(),
    icon: Icon(
      Icons.keyboard_arrow_down,
      size: 16,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    ),
    underline: Container(),
    isDense: true,
  );

  Widget _buildLayoutOption(HeatmapLayoutType layout, bool isSelected) =>
      GestureDetector(
        onTap: () => _handleLayoutChange(layout),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.primaryContainer
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                layout.icon,
                size: 16,
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimaryContainer
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                layout.displayName,
                style: TextStyle(
                  color: isSelected
                      ? Theme.of(context).colorScheme.onPrimaryContainer
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );

  void _handleLayoutChange(HeatmapLayoutType newLayout) {
    if (newLayout != widget.selectedLayout) {
      CommonLogger.debug(
        'Layout changed: ${widget.selectedLayout.code} → ${newLayout.code}',
        tag: 'Selector.Layout',
      );

      widget.onLayoutChanged(newLayout);
    }
  }
}
