import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';

/// Floating border label around interactive children that must not live inside
/// [InputDecorator] (Quill, file pickers — web focus / pointer issues).
///
/// Visual contract matches [JournalFieldDecoration.borderLabel].
class JournalBorderLabeledPanel extends StatelessWidget {
  const JournalBorderLabeledPanel({
    required this.label,
    required this.child,
    this.padding,
    this.readOnly = false,
    super.key,
  });

  final String label;
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final fill = readOnly
        ? colors.cardSurface.withValues(alpha: 0.55)
        : colors.surface.withValues(alpha: 0.45);
    final borderColor =
        colors.border.withValues(alpha: readOnly ? 0.25 : 0.4);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: AppRadii.input,
            border: Border.all(color: borderColor),
          ),
          padding: padding ??
              const EdgeInsets.fromLTRB(
                AppSpacing.sm + AppSpacing.xs,
                AppSpacing.md,
                AppSpacing.sm + AppSpacing.xs,
                AppSpacing.sm,
              ),
          child: child,
        ),
        Positioned(
          left: AppSpacing.md,
          top: -AppSpacing.sm,
          child: ColoredBox(
            color: fill,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              child: Text(
                label,
                style: context.text.label(compact: true).copyWith(
                      color: colors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
