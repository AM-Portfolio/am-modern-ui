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
    this.height = 40,
    this.fontSize = 13,
    this.width,
    this.menuMaxWidth,
    this.menuMaxHeight = 280,
    this.enabled = true,
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

  /// Match [AppRadii.input] / form fields in the journal hub.
  static double get _radius => AppRadii.md;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);

    final dropdown = CustomDropdown<T>(
      value: value,
      hint: hint,
      items: items,
      onChanged: enabled ? onChanged : null,
      enabled: enabled,
      height: height,
      isExpanded: true,
      fontSize: fontSize,
      iconSize: 18,
      borderRadius: _radius,
      primaryColor: ModuleColors.trade,
      backgroundColor: colors.cardSurface.withValues(alpha: 0.65),
      borderColor: colors.border.withValues(alpha: 0.35),
      textColor: colors.textPrimary,
      menuMaxHeight: menuMaxHeight,
      menuMaxWidth: menuMaxWidth ?? width,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      icon: Icons.keyboard_arrow_down_rounded,
    );

    Widget child = dropdown;
    if (label != null && label!.trim().isNotEmpty) {
      child = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label!,
            style: theme.textTheme.labelMedium?.copyWith(
              color: colors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          dropdown,
        ],
      );
    }

    if (width != null) {
      return SizedBox(width: width, child: child);
    }
    return child;
  }
}
