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

    return PopupMenuButton<String>(
      tooltip: 'Family',
      offset: const Offset(0, 40),
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
                      color: o.key == selectedKey ? accent : colors.textPrimary,
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
      child: Container(
        height: height,
        constraints: BoxConstraints(
          minWidth: compact ? 96 : 132,
          maxWidth: compact ? 140 : 220,
        ),
        padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 12),
        decoration: BoxDecoration(
          color: colors.cardSurface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: accent.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Icon(Icons.groups_outlined, size: iconSize, color: accent),
            SizedBox(width: compact ? 4 : 8),
            Expanded(
              child: Text(
                current.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: fontSize,
                  color: colors.textPrimary,
                ),
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: compact ? 16 : 18,
              color: colors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
