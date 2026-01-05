import 'package:flutter/material.dart';
import 'package:am_design_system/core/theme/app_colors.dart';


class AppSegmentedControl<T> extends StatelessWidget {
  final T selectedValue;
  final Map<T, String> children;
  final ValueChanged<T> onValueChanged;
  final Color? primaryColor;
  final bool enableGlass; // V2 Prop

  const AppSegmentedControl({
    required this.selectedValue,
    required this.children,
    required this.onValueChanged,
    super.key,
    this.primaryColor,
    this.enableGlass = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = primaryColor ?? AppColors.primary;

    return SegmentedButton<T>(
      segments: children.entries.map((e) => 
        ButtonSegment<T>(value: e.key, label: Text(e.value))
      ).toList(),
      selected: {selectedValue},
      onSelectionChanged: (Set<T> newSelection) {
        if (newSelection.isNotEmpty) {
          onValueChanged(newSelection.first);
        }
      },
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) {
            return color;
          }
          return enableGlass ? Colors.white.withOpacity(0.05) : Colors.transparent;
        }),
        foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return enableGlass ? Colors.white70 : color;
        }),
        side: enableGlass ? WidgetStateProperty.all(
          BorderSide(color: Colors.white.withOpacity(0.1)),
        ) : null,
      ),
    );
  }
}
