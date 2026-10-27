import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';

/// Journal-hub [CustomDropdown] styled from [AppColorsTheme] (card / border / text)
/// with trade accent for chevron and selection — matches [JournalFormSurface].
class JournalThemedDropdown<T> extends StatelessWidget {
  const JournalThemedDropdown({
    super.key,
    required this.items,
    required this.onChanged,
    this.value,
    this.hint,
    this.label,
    this.height = 44,
    this.fontSize = 14,
    this.width,
    this.menuMaxWidth,
    this.menuMaxHeight = 280,
    this.enabled = true,
    this.compact = false,
  });

  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String? hint;
  final String? label;
  final double height;
  final double fontSize;
  final double? width;
  final double? menuMaxWidth;
  final double menuMaxHeight;
  final bool enabled;

  /// Tighter padding / radius for list-rail filter pills.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final radius = compact ? AppRadii.sm : AppRadii.md;
    final hPad = compact ? 10.0 : 12.0;

    Widget buildDropdown({double? resolvedMenuWidth}) {
      return CustomDropdown<T>(
        value: value,
        hint: hint,
        items: items,
        onChanged: enabled ? onChanged : null,
        enabled: enabled,
        height: height,
        isExpanded: true,
        fontSize: fontSize,
        iconSize: compact ? 16 : 18,
        borderRadius: radius,
        primaryColor: ModuleColors.trade,
        backgroundColor: colors.cardSurface,
        borderColor: colors.border.withValues(alpha: compact ? 0.55 : 0.45),
        textColor: colors.textPrimary,
        menuMaxHeight: menuMaxHeight,
        menuMaxWidth: menuMaxWidth ?? resolvedMenuWidth,
        contentPadding: EdgeInsets.symmetric(horizontal: hPad),
        icon: Icons.keyboard_arrow_down_rounded,
      );
    }

    Widget labeled(Widget dropdown) {
      if (label == null || label!.trim().isEmpty) return dropdown;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          dropdown,
        ],
      );
    }

    final child = width != null
        ? labeled(
            SizedBox(
              width: width,
              child: buildDropdown(resolvedMenuWidth: width),
            ),
          )
        : LayoutBuilder(
            builder: (context, constraints) {
              final w =
                  constraints.maxWidth.isFinite && constraints.maxWidth > 0
                      ? constraints.maxWidth
                      : null;
              return labeled(buildDropdown(resolvedMenuWidth: w));
            },
          );

    return child;
  }
}
