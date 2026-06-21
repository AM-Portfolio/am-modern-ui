import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:am_design_system/core/theme/app_colors.dart';
import 'package:am_design_system/shared/widgets/navigation/sidebar_item.dart';
import 'package:am_design_system/core/module/module_config.dart';

/// Premium floating bottom navigation bar with glassmorphism effect.
///
/// Displays only the core navigation items (max 5) as a floating pill.
/// The last item is expected to be a "Menu" item that triggers [onMenuTap].
class GlobalBottomNavigation extends StatelessWidget {
  const GlobalBottomNavigation({
    required this.activeNavItem,
    required this.onNavigate,
    required this.items,
    super.key,
    this.onMenuTap,
    this.onProfileTap,
    this.userName,
    this.isDarkMode = false,
  });

  final String activeNavItem;
  final Function(String) onNavigate;
  final List<SidebarItem> items;
  final VoidCallback? onMenuTap;
  final VoidCallback? onProfileTap;
  final String? userName;
  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    return Container(
      // Outer padding to make the bar "float" above the screen edge
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      color: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 68,
            decoration: BoxDecoration(
              color: isDarkMode
                  ? const Color(0xFF1a1a2e).withOpacity(0.85)
                  : Colors.white.withOpacity(0.85),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: isDarkMode
                    ? Colors.white.withOpacity(0.08)
                    : Colors.black.withOpacity(0.06),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDarkMode ? 0.35 : 0.12),
                  blurRadius: 24,
                  spreadRadius: 0,
                  offset: const Offset(0, 4),
                ),
                if (isDarkMode)
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.08),
                    blurRadius: 40,
                    spreadRadius: -4,
                    offset: const Offset(0, 2),
                  ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: items.map((item) {
                  final isActive = activeNavItem == item.title;
                  final accentColor =
                      _getIconColor(item.title) ?? AppColors.primary;
                  final isMenuButton = item.title == 'Menu';

                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        if (isMenuButton && onMenuTap != null) {
                          onMenuTap!();
                        } else {
                          onNavigate(item.title);
                        }
                      },
                      behavior: HitTestBehavior.opaque,
                      child: _NavItem(
                        icon: item.icon,
                        label: item.title,
                        isActive: isActive,
                        accentColor: accentColor,
                        isDarkMode: isDarkMode,
                        isMenuButton: isMenuButton,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color? _getIconColor(String title) {
    switch (title.toLowerCase()) {
      case 'dashboard':
        return AppColors.primary;
      case 'market':
        return AppColors.marketAccent;
      case 'portfolio':
        return AppColors.portfolioAccent;
      case 'trade':
        return AppColors.tradeAccent;
      case 'menu':
        return AppColors.primary;
      default:
        return null;
    }
  }
}

/// Individual navigation item with active indicator animation.
class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.accentColor,
    required this.isDarkMode,
    this.isMenuButton = false,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final Color accentColor;
  final bool isDarkMode;
  final bool isMenuButton;

  @override
  Widget build(BuildContext context) {
    final inactiveColor =
        isDarkMode ? Colors.white.withOpacity(0.45) : Colors.grey.shade500;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Active indicator dot
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            height: 3,
            width: isActive ? 20 : 0,
            margin: const EdgeInsets.only(bottom: 4),
            decoration: BoxDecoration(
              color: isActive ? accentColor : Colors.transparent,
              borderRadius: BorderRadius.circular(2),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: accentColor.withOpacity(0.5),
                        blurRadius: 6,
                        spreadRadius: 0,
                      ),
                    ]
                  : [],
            ),
          ),

          // Icon with glow effect when active
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isActive
                  ? accentColor.withOpacity(isDarkMode ? 0.15 : 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: isActive ? accentColor : inactiveColor,
              size: isActive ? 24 : 22,
            ),
          ),

          // Label: always show but emphasize when active
          const SizedBox(height: 2),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              fontSize: isActive ? 10 : 9,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
              color: isActive ? accentColor : inactiveColor,
              letterSpacing: isActive ? 0.3 : 0,
            ),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
