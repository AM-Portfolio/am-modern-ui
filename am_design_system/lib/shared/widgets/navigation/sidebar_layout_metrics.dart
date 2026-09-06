import 'package:flutter/material.dart';

import 'package:am_design_system/core/theme/app_glassmorphism_v2.dart';

/// Shared vertical rhythm for [GlobalSidebar] + [SecondarySidebar].
class SidebarLayoutMetrics {
  SidebarLayoutMetrics._();

  /// Space above the logo / collapse toggle band.
  static const double topInset = 48;

  /// Height of the logo / toggle band (primary logo centered inside).
  static const double headerBandHeight = 56;

  static const double logoWidth = 64;
  static const double logoHeight = 40;

  /// Primary + compact secondary nav tile size.
  static const double navTileSize = 56;

  /// Gap below each nav tile (primary already uses this).
  static const double navTileGap = 32;

  /// Gap between header band and first nav item (primary logo → Dashboard).
  static const double afterHeaderGap = 48;

  /// Shared left/right inset for expanded secondary sidebar content
  /// (header, Current Portfolio, nav rows, footer).
  static const double contentInset = 16;

  static const double leftAccentWidth = 3;
  static const double leftAccentInset = 8;
}

/// FinDash square tile with optional left accent bar (mock active state).
class SidebarFinDashTile extends StatelessWidget {
  const SidebarFinDashTile({
    super.key,
    required this.isActive,
    required this.isDark,
    required this.accentColor,
    required this.child,
    this.size = SidebarLayoutMetrics.navTileSize,
    this.onTap,
    this.tooltip,
  });

  final bool isActive;
  final bool isDark;
  final Color accentColor;
  final Widget child;
  final double size;
  final VoidCallback? onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final tile = SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: size,
            height: size,
            decoration: isActive
                ? AppGlassmorphismV2.finDashActiveItem(
                    accentColor: accentColor,
                    isDark: isDark,
                  )
                : AppGlassmorphismV2.finDashInactiveItem(isDark: isDark),
            child: Center(child: child),
          ),
          if (isActive)
            Positioned(
              left: 0,
              top: SidebarLayoutMetrics.leftAccentInset,
              bottom: SidebarLayoutMetrics.leftAccentInset,
              child: Container(
                width: SidebarLayoutMetrics.leftAccentWidth,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
        ],
      ),
    );

    Widget result = tile;
    if (onTap != null) {
      result = MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(onTap: onTap, child: result),
      );
    }
    if (tooltip != null && tooltip!.isNotEmpty) {
      result = Tooltip(message: tooltip!, preferBelow: false, child: result);
    }
    return result;
  }
}
