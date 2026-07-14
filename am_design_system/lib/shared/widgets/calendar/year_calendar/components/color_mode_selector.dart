import 'package:flutter/material.dart';

import '../models/calendar_color_mode.dart';

/// Widget for selecting calendar color mode
class ColorModeSelector extends StatelessWidget {
  const ColorModeSelector({
    required this.currentMode,
    required this.onModeChanged,
    super.key,
    this.compact = false,
    this.dense = false,
  });

  final CalendarColorMode currentMode;
  final Function(CalendarColorMode) onModeChanged;
  final bool compact;
  /// Even tighter chips for the mobile calendar header row.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _buildCompactSelector(context);
    }
    return _buildFullSelector(context);
  }

  Widget _buildCompactSelector(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(
      horizontal: dense ? 6 : 8,
      vertical: dense ? 2 : 4,
    ),
    decoration: BoxDecoration(
      border: Border.all(
        color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
      ),
      borderRadius: BorderRadius.circular(8),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<CalendarColorMode>(
        value: currentMode,
        isDense: true,
        icon: Icon(Icons.arrow_drop_down, size: dense ? 16 : 18),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: dense ? 11 : null,
            ),
        items: CalendarColorMode.values
            .map(
              (mode) => DropdownMenuItem(
                value: mode,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_getIconForMode(mode), size: dense ? 12 : 14),
                    SizedBox(width: dense ? 4 : 6),
                    Text(
                      dense ? mode.shortDisplayName : mode.displayName,
                      style: TextStyle(fontSize: dense ? 11 : null),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
        onChanged: (mode) {
          if (mode != null) onModeChanged(mode);
        },
      ),
    ),
  );

  Widget _buildFullSelector(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.3)),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.palette_outlined, size: 16, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        DropdownButton<CalendarColorMode>(
          value: currentMode,
          underline: const SizedBox(),
          isDense: true,
          style: Theme.of(context).textTheme.bodyMedium,
          items: CalendarColorMode.values
              .map(
                (mode) => DropdownMenuItem(
                  value: mode,
                  child: Row(
                    children: [
                      Icon(_getIconForMode(mode), size: 16),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(mode.displayName, style: const TextStyle(fontWeight: FontWeight.w600)),
                          Text(mode.description, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10)),
                        ],
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
          onChanged: (mode) {
            if (mode != null) onModeChanged(mode);
          },
        ),
      ],
    ),
  );

  IconData _getIconForMode(CalendarColorMode mode) {
    switch (mode) {
      case CalendarColorMode.winLoss:
        return Icons.check_circle_outline;
      case CalendarColorMode.profitIntensity:
        return Icons.gradient;
    }
  }
}
