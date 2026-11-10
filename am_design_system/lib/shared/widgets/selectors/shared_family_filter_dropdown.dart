import 'package:am_common/am_common.dart';
import 'package:am_design_system/core/module/module_config.dart';
import 'package:am_design_system/core/theme/color_extensions.dart';
import 'package:flutter/material.dart';

/// Compact All Users | You | family-member dropdown for portfolio filtering.
class SharedFamilyFilterDropdown extends StatelessWidget {
  const SharedFamilyFilterDropdown({
    super.key,
    required this.selectedKey,
    required this.primaryLabel,
    required this.members,
    required this.onSelected,
    this.accentColor,
    this.compact = false,
    this.allLabel = 'All Users',
  });

  /// [FavoritePersonaStore.kAll], [FavoritePersonaStore.kYou], or member id.
  final String selectedKey;
  final String primaryLabel;
  final List<({String id, String name})> members;
  final ValueChanged<String> onSelected;
  final Color? accentColor;
  final bool compact;

  /// Display label for the household / All option.
  final String allLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = accentColor ?? ModuleColors.portfolio;
    final options = <({String key, String label})>[
      (key: FavoritePersonaStore.kAll, label: allLabel),
      (key: FavoritePersonaStore.kYou, label: primaryLabel),
      for (final m in members) (key: m.id, label: m.name),
    ];
    final current = options.cast<({String key, String label})?>().firstWhere(
          (o) => o!.key == selectedKey,
          orElse: () => options.first,
        )!;

    final height = compact ? 36.0 : 40.0;
    final fontSize = compact ? 12.0 : 13.0;
    final iconSize = compact ? 14.0 : 16.0;
    final fieldBorder = compact
        ? accent.withValues(alpha: 0.35)
        : colors.border.withValues(alpha: 0.45);
    final radius = compact ? 999.0 : 8.0;

    Widget trigger({required double width}) {
      return Container(
        width: width,
        height: height,
        padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 12),
        decoration: BoxDecoration(
          color: colors.cardSurface,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: fieldBorder),
        ),
        child: Row(
          children: [
            if (compact) ...[
              Icon(Icons.groups_outlined, size: iconSize, color: accent),
              const SizedBox(width: 4),
            ],
            Expanded(
              child: Text(
                current.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: compact ? FontWeight.w600 : FontWeight.w500,
                  fontSize: fontSize,
                  color: colors.textPrimary,
                ),
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: compact ? 16 : 18,
              color: compact
                  ? colors.textSecondary
                  : accent.withValues(alpha: 0.85),
            ),
          ],
        ),
      );
    }

    Widget menu({required double menuWidth}) {
      return PopupMenuButton<String>(
        tooltip: 'Family',
        offset: Offset(0, height + 4),
        padding: EdgeInsets.zero,
        // Menu width only — never cap height to the trigger (clips items).
        constraints: BoxConstraints(
          minWidth: menuWidth,
          maxWidth: menuWidth,
        ),
        onSelected: onSelected,
        color: colors.cardSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: accent.withValues(alpha: 0.35)),
        ),
        itemBuilder: (ctx) => [
          for (final o in options)
            PopupMenuItem<String>(
              value: o.key,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      o.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: o.key == selectedKey
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color:
                            o.key == selectedKey ? accent : colors.textPrimary,
                        fontSize: fontSize,
                      ),
                    ),
                  ),
                  if (o.key == selectedKey)
                    Icon(Icons.check_rounded, size: 16, color: accent),
                ],
              ),
            ),
        ],
        child: trigger(width: menuWidth),
      );
    }

    if (compact) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final bounded =
              constraints.maxWidth.isFinite && constraints.maxWidth > 0;
          final width = bounded
              ? constraints.maxWidth.clamp(96.0, 140.0)
              : 120.0;
          return menu(menuWidth: width);
        },
      );
    }

    // Sidebar stack: mirror Current Portfolio field (label + full-width rect).
    return LayoutBuilder(
      builder: (context, constraints) {
        final bounded =
            constraints.maxWidth.isFinite && constraints.maxWidth > 0;
        final width = bounded ? constraints.maxWidth : 280.0;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Family',
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            menu(menuWidth: width),
          ],
        );
      },
    );
  }
}
