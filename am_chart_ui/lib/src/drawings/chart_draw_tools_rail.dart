import 'package:flutter/material.dart';

import 'chart_draw_models.dart';

/// Collapsible left rail: click chevron to show / hide drawing tools.
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
    ChartDrawTool.eraser,
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = theme.colorScheme.surfaceContainerHighest;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      width: expanded ? 48 : 28,
      decoration: BoxDecoration(
        color: bg.withValues(alpha: 0.95),
        border: Border(
          right: BorderSide(color: theme.dividerColor.withValues(alpha: 0.6)),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 4),
          IconButton(
            tooltip: expanded ? 'Hide drawing tools' : 'Show drawing tools',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 32),
            iconSize: 18,
            onPressed: onToggleExpanded,
            icon: Icon(
              expanded ? Icons.chevron_left : Icons.chevron_right,
            ),
          ),
          if (!expanded)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: RotatedBox(
                quarterTurns: 3,
                child: Text(
                  'Draw',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: theme.hintColor,
                  ),
                ),
              ),
            ),
          if (expanded) ...[
            const Divider(height: 8),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 2),
                children: [
                  for (final t in _tools)
                    Tooltip(
                      message: t.label,
                      child: InkWell(
                        onTap: () => onSelectTool(t),
                        child: Container(
                          height: 36,
                          alignment: Alignment.center,
                          color: activeTool == t
                              ? theme.colorScheme.primary.withValues(alpha: 0.22)
                              : null,
                          child: Icon(
                            t.icon,
                            size: 18,
                            color: activeTool == t
                                ? theme.colorScheme.primary
                                : theme.iconTheme.color,
                          ),
                        ),
                      ),
                    ),
                  const Divider(height: 12),
                  Tooltip(
                    message: drawingCount > 0
                        ? 'Clear all drawings ($drawingCount)'
                        : 'No drawings',
                    child: IconButton(
                      iconSize: 18,
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 36, minHeight: 36),
                      onPressed: drawingCount > 0 ? onClearAll : null,
                      icon: const Icon(Icons.delete_outline),
                    ),
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
