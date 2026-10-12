import 'package:flutter/material.dart';

import 'chart_draw_models.dart';

/// Single workspace drawing rail (TradingView-style left strip).
class ChartDrawToolsRail extends StatelessWidget {
  const ChartDrawToolsRail({
    super.key,
    required this.expanded,
    required this.activeTool,
    required this.onToggleExpanded,
    required this.onSelectTool,
    required this.onClearAll,
    this.drawingCount = 0,
  });

  final bool expanded;
  final ChartDrawTool activeTool;
  final VoidCallback onToggleExpanded;
  final ValueChanged<ChartDrawTool> onSelectTool;
  final VoidCallback onClearAll;
  final int drawingCount;

  static const _tools = <ChartDrawTool>[
    ChartDrawTool.none,
    ChartDrawTool.trendLine,
    ChartDrawTool.hLine,
    ChartDrawTool.vLine,
    ChartDrawTool.ray,
    ChartDrawTool.channel,
    ChartDrawTool.fibRetrace,
    ChartDrawTool.note,
    ChartDrawTool.measure,
  ];

  static const double _expandedWidth = 52;
  static const double _collapsedWidth = 28;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = theme.brightness == Brightness.dark
        ? const Color(0xFF131722)
        : theme.colorScheme.surfaceContainerHighest;
    final iconColor = theme.brightness == Brightness.dark
        ? const Color(0xFFD1D4DC)
        : theme.iconTheme.color;
    final activeBg = theme.colorScheme.primary.withValues(alpha: 0.28);
    final activeFg = theme.colorScheme.primary;
    final edge = theme.dividerColor.withValues(alpha: 0.55);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      width: expanded ? _expandedWidth : _collapsedWidth,
      decoration: BoxDecoration(
        color: bg,
        border: Border(right: BorderSide(color: edge)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 6),
          _RailIcon(
            tooltip: expanded ? 'Collapse tools' : 'Expand tools',
            icon: Icons.menu,
            iconColor: iconColor,
            onTap: onToggleExpanded,
          ),
          if (!expanded)
            Expanded(
              child: Center(
                child: RotatedBox(
                  quarterTurns: 3,
                  child: Text(
                    'Tools',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: theme.hintColor,
                    ),
                  ),
                ),
              ),
            )
          else ...[
            const SizedBox(height: 4),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 2),
                children: [
                  for (final t in _tools)
                    _RailIcon(
                      tooltip: t.label,
                      icon: t.icon,
                      selected: activeTool == t,
                      iconColor: activeTool == t ? activeFg : iconColor,
                      selectedBg: activeBg,
                      onTap: () => onSelectTool(t),
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    child: Divider(height: 1, color: edge),
                  ),
                  _RailIcon(
                    tooltip: ChartDrawTool.eraser.label,
                    icon: ChartDrawTool.eraser.icon,
                    selected: activeTool == ChartDrawTool.eraser,
                    iconColor: activeTool == ChartDrawTool.eraser
                        ? activeFg
                        : iconColor,
                    selectedBg: activeBg,
                    onTap: () => onSelectTool(ChartDrawTool.eraser),
                  ),
                  _RailIcon(
                    tooltip: drawingCount > 0
                        ? 'Clear all drawings ($drawingCount)'
                        : 'No drawings',
                    icon: Icons.delete_outline,
                    iconColor: iconColor,
                    enabled: drawingCount > 0,
                    onTap: onClearAll,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RailIcon extends StatelessWidget {
  const _RailIcon({
    required this.tooltip,
    required this.icon,
    required this.onTap,
    this.iconColor,
    this.selected = false,
    this.selectedBg,
    this.enabled = true,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;
  final Color? iconColor;
  final bool selected;
  final Color? selectedBg;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 400),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Material(
          color: selected
              ? (selectedBg ??
                    Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.22))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          child: InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: enabled ? onTap : null,
            child: SizedBox(
              height: 38,
              width: double.infinity,
              child: Icon(
                icon,
                size: 20,
                color: enabled
                    ? iconColor
                    : (iconColor ?? Colors.grey).withValues(alpha: 0.35),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
