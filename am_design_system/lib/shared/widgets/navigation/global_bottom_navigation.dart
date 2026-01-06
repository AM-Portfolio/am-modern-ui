
import 'package:flutter/material.dart';
import 'package:am_design_system/core/theme/app_glassmorphism_v2.dart';
import 'package:am_design_system/core/theme/app_colors.dart';
import 'package:am_design_system/shared/widgets/navigation/sidebar_item.dart';
import 'package:am_design_system/core/module/module_config.dart';

/// Global Bottom Navigation - Mobile Version of Global Sidebar
class GlobalBottomNavigation extends StatelessWidget {
  const GlobalBottomNavigation({
    required this.activeNavItem,
    required this.onNavigate,
    required this.items,
    super.key,
    this.onProfileTap,
    this.userName,
    this.isDarkMode = false,
  });

  final String activeNavItem;
  final Function(String) onNavigate;
  final List<SidebarItem> items;
  final VoidCallback? onProfileTap;
  final String? userName;
  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80, // Height for bottom bar
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1a1a2e).withOpacity(0.95) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ...items.map((item) {
              final isActive = activeNavItem == item.title;
              final accentColor = _getIconColor(item.title) ?? ModuleColors.portfolio;
              
              return GestureDetector(
                onTap: () => onNavigate(item.title),
                behavior: HitTestBehavior.opaque,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    isActive
                        ? Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: accentColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(item.icon, color: accentColor, size: 24),
                          )
                        : Icon(
                            item.icon,
                            color: isDarkMode ? Colors.white54 : Colors.grey,
                            size: 24,
                          ),
                    const SizedBox(height: 4),
                    Text(
                      item.title,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                        color: isActive
                            ? accentColor
                            : (isDarkMode ? Colors.white54 : Colors.grey),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            
            // Profile Item as last element
            GestureDetector(
              onTap: onProfileTap,
               behavior: HitTestBehavior.opaque,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: activeNavItem == 'Profile' 
                          ? ModuleColors.portfolio 
                          : (isDarkMode ? Colors.white24 : Colors.grey),
                         width: 2,
                      ),
                    ),
                     child: const Icon(Icons.person, size: 16, color: Colors.grey),
                  ),
                   const SizedBox(height: 4),
                   Text(
                    'Profile',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: activeNavItem == 'Profile' ? FontWeight.w600 : FontWeight.normal,
                      color: activeNavItem == 'Profile' 
                        ? ModuleColors.portfolio 
                        : (isDarkMode ? Colors.white54 : Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color? _getIconColor(String title) {
    switch (title.toLowerCase()) {
      case 'dashboard': return AppColors.primary;
      case 'market': return AppColors.marketAccent;
      case 'portfolio': return AppColors.portfolioAccent;
      case 'trade': return AppColors.tradeAccent;
      default: return null;
    }
  }
}
