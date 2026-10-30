import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';

import '../../web/widgets/journal/utils/journal_field_decoration.dart';

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
    /// Put [label] on the outline border (mobile). Default stacks label above.
    this.floatingLabel = false,
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
  final bool compact;
  final bool floatingLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent =
        ModuleColorProvider.maybeOf(context) ?? ModuleColors.trade;
    // CustomDropdown takes a double radius (md matches AppRadii.input).
    const radius = AppRadii.md;
    final hPad = AppSpacing.sm + AppSpacing.xs;
    final useFloating =
        floatingLabel && label != null && label!.trim().isNotEmpty;
    // Match JournalFieldDecoration fill — not opaque white cardSurface.
    final fieldFill = colors.surface.withValues(alpha: 0.45);
    final clear = colors.cardSurface.withValues(alpha: 0);

    Widget buildDropdown({double? resolvedMenuWidth}) {
      return CustomDropdown<T>(
        value: value,
        hint: hint,
        items: items,
        onChanged: enabled ? onChanged : null,
        enabled: enabled,
        height: useFloating ? (height - AppSpacing.xs) : height,
        isExpanded: true,
        fontSize: fontSize,
        iconSize: AppSpacing.md,
        borderRadius: radius,
        primaryColor: accent,
        // Trigger clear inside floating outline; menu stays opaque.
        backgroundColor: useFloating ? clear : fieldFill,
        menuBackgroundColor: colors.cardSurface,
        borderColor: useFloating
            ? clear
            : colors.border.withValues(alpha: 0.4),
        textColor: colors.textPrimary,
        menuMaxHeight: menuMaxHeight,
        menuMaxWidth: menuMaxWidth ?? resolvedMenuWidth,
        contentPadding: EdgeInsets.symmetric(horizontal: hPad),
        icon: Icons.keyboard_arrow_down_rounded,
      );
    }

    Widget labeled(Widget dropdown) {
      if (label == null || label!.trim().isEmpty) return dropdown;
      if (useFloating) {
        return InputDecorator(
          isEmpty: value == null,
          decoration: JournalFieldDecoration.borderLabel(
            context,
            label: label!,
            // Keep inner trigger flush so hint/value stay vertically centered.
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
              vertical: AppSpacing.xxs,
            ),
          ),
          child: dropdown,
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label!,
            style: context.text.body(compact: true).copyWith(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: AppSpacing.sm - AppSpacing.xxs),
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
