import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';

/// Shared card chrome for journal form sections (matches landing metric/filter surfaces).
class JournalFormSurface extends StatelessWidget {
  const JournalFormSurface({
    required this.child,
    this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.padding,
    this.fillHeight = false,
    this.centerHeader = false,
    super.key,
  });

  final Widget child;
  final String? title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final EdgeInsetsGeometry? padding;

  /// Stretch to a bounded parent (e.g. [Expanded]) so column cards match height.
  final bool fillHeight;

  /// Center badge + title as a group (journal Pre/Execute/Post cards).
  final bool centerHeader;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;

    final titleBlock = Column(
      crossAxisAlignment:
          centerHeader ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (title != null)
          Text(
            title!,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ],
      ],
    );

    final header = (title != null || trailing != null || leading != null)
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: centerHeader
                    ? MainAxisAlignment.center
                    : MainAxisAlignment.start,
                children: [
                  if (leading != null) ...[
                    leading!,
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  if (centerHeader)
                    titleBlock
                  else
                    Expanded(child: titleBlock),
                  if (trailing != null) trailing!,
                ],
              ),
              // Extra room so the first field's floating border label is not tight.
              const SizedBox(height: AppSpacing.md + AppSpacing.xs),
            ],
          )
        : null;

    // Design-system card on hub background (mockup: white card / themed surface).
    // clipBehavior keeps tall form content from painting outside rounded edges.
    return Container(
      width: double.infinity,
      height: fillHeight ? double.infinity : null,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.cardSurface,
        borderRadius: AppRadii.card,
        border: Border.all(color: colors.border.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: colors.textPrimary.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: padding ?? const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (header != null) header,
          // Scrollables must be Expanded when [fillHeight] stretches this card.
          if (fillHeight) Expanded(child: child) else child,
        ],
      ),
    );
  }
}
