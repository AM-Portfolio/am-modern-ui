import 'package:flutter/material.dart';

import 'package:am_design_system/core/theme/app_radii.dart';
import 'package:am_design_system/core/theme/app_type_scale.dart';
import 'package:am_design_system/core/theme/color_extensions.dart';

/// Compact nested navigation for a feature surface.
///
/// The caller owns routing. The final item is always rendered as the current
/// location and is not interactive.
class AmNavigationTrailItem {
  const AmNavigationTrailItem({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;
}

class AmNavigationTrail extends StatelessWidget {
  const AmNavigationTrail({
    super.key,
    required this.items,
    this.separator = Icons.chevron_right_rounded,
  });

  final List<AmNavigationTrailItem> items;
  final IconData separator;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Semantics(
      container: true,
      label: 'Navigation path',
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var index = 0; index < items.length; index++) ...[
              if (index > 0)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    separator,
                    size: 15,
                    color: context.textTertiary,
                  ),
                ),
              _TrailItem(
                  item: items[index], isCurrent: index == items.length - 1),
            ],
          ],
        ),
      ),
    );
  }
}

class _TrailItem extends StatelessWidget {
  const _TrailItem({required this.item, required this.isCurrent});

  final AmNavigationTrailItem item;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final text = Text(
      item.label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: AppTypeScale.md,
        fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w600,
        color: isCurrent ? context.textPrimary : context.textSecondary,
      ),
    );

    if (isCurrent || item.onTap == null) return text;

    return Semantics(
      button: true,
      label: 'Open ${item.label}',
      child: Material(
        color: context.surfaceColor.withValues(alpha: 0),
        child: InkWell(
          onTap: item.onTap,
          borderRadius: BorderRadius.circular(AppRadii.sm),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
            child: text,
          ),
        ),
      ),
    );
  }
}
