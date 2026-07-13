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
    final isDark = theme.brightness == Brightness.dark;

    return SegmentedButton<T>(
      segments: children.entries.map((e) => 
        ButtonSegment<T>(value: e.key, label: Text(e.value, maxLines: 1, softWrap: false))
      ).toList(),
      showSelectedIcon: false,
      selected: {selectedValue},
      onSelectionChanged: (Set<T> newSelection) {
        if (newSelection.isNotEmpty) {
          onValueChanged(newSelection.first);
        }
      },
      style: ButtonStyle(
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
        padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 10, vertical: 4)),
        backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) {
            return color;
          }
          return isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05);
        }),
        foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return isDark ? Colors.white70 : Colors.black87;
        }),
        side: WidgetStateProperty.all(
          BorderSide(
            color: isDark ? Colors.white.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}
