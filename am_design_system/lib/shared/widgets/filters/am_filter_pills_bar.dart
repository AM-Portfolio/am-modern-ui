import 'package:flutter/material.dart';
import 'package:am_design_system/core/theme/color_extensions.dart';

/// Standardized, theme-aware horizontal filter pill bar.
class AMFilterPillsBar<T> extends StatelessWidget {
  const AMFilterPillsBar({
    super.key,
    required this.options,
    required this.selectedOption,
    required this.onSelected,
    this.labelBuilder,
    this.activeColor,
    this.showCheckmark = true,
  });

  final List<T> options;
  final T selectedOption;
  final ValueChanged<T> onSelected;
  final String Function(T item)? labelBuilder;
  final Color? activeColor;
  final bool showCheckmark;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final selectedBg = activeColor ?? const Color(0xFFD4AF37); // Market Gold default

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: options.map((option) {
          final isSelected = option == selectedOption;
          final label = labelBuilder != null ? labelBuilder!(option) : option.toString();

          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => onSelected(option),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? selectedBg : colors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? selectedBg : colors.border.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSelected && showCheckmark) ...[
                      const Icon(Icons.check_rounded, size: 14, color: Colors.black),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      label,
                      style: TextStyle(
                        color: isSelected ? Colors.black : colors.textSecondary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
