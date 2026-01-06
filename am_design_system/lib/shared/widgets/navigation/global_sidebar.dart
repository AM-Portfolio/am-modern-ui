
import 'dart:ui';
import 'package:flutter/material.dart';

import 'package:am_design_system/core/theme/app_glassmorphism_v2.dart';
import 'package:am_design_system/core/theme/app_colors.dart';
import 'package:am_design_system/shared/widgets/navigation/sidebar_item.dart';
import 'package:am_design_system/core/utils/conditional_mouse_region.dart';
import 'package:am_design_system/core/module/module_config.dart';

/// Global Sidebar - Thin Glass Strip Version
///
/// A purely navigational strip (72px) that sits on the far left.
/// Contains main app modules (top) and global actions (bottom).
class GlobalSidebar extends StatelessWidget {
  const GlobalSidebar({
    required this.activeNavItem,
    required this.onNavigate,
    required this.items,
    super.key,
    this.onLogout,
    this.onThemeToggle,
    this.onProfileTap, // New action
    this.userName,
    this.userEmail,
    this.userAvatarUrl,
    this.isDarkMode = false,
  });

  final String activeNavItem;
  final Function(String) onNavigate;
  final List<SidebarItem> items;
  final VoidCallback? onLogout;
  final VoidCallback? onThemeToggle;
  final VoidCallback? onProfileTap;
  final String? userName;
  final String? userEmail;
  final String? userAvatarUrl;
  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    // Thin strip width
    const double width = 80.0; // Slightly wider for better spacing

    return AppGlassmorphismV2.glassPrism(
      isDark: isDarkMode,
      child: SizedBox(
        width: width,
        height: double.infinity,
        child: Column(
          children: [
            const SizedBox(height: 32),
            
            // 1. App Logo / Brand Icon
            _buildAppLogo(),

            const SizedBox(height: 40),

            // 2. Main Navigation Icons
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: items.map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: _buildNavItem(item, isDarkMode),
                    );
                  }).toList(),
                ),
              ),
            ),

            // 3. Bottom Actions (Theme, Profile)
            Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: Column(
                children: [
                  // Theme Toggle
                  if (onThemeToggle != null) ...[
                    _buildActionButton(
                      icon: isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                      onTap: onThemeToggle!,
                      isDarkMode: isDarkMode,
                      tooltip: 'Toggle Theme',
                      color: isDarkMode ? Colors.amber : const Color(0xFF6C5DD3),
                    ),
                    const SizedBox(height: 24),
                  ],
                  
                  // User Profile Avatar (At the very bottom)
                  _buildUserProfile(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppLogo() {
    return Container(
      width: 48,
      height: 48,
      decoration: AppGlassmorphismV2.iconGlassContainer(
        color: const Color(0xFF6C5DD3),
        size: 48,
        isDark: isDarkMode,
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.token, color: Colors.white, size: 28),
    );
  }

  Widget _buildNavItem(SidebarItem item, bool isDark) {
    final isSelected = activeNavItem == item.title;
    // Map specific module colors based on design or fallback to blue
    final accentColor = _getIconColor(item.title) ?? const Color(0xFF6C5DD3);

    return Tooltip(
      message: item.title,
      preferBelow: false,
      child: GestureDetector(
        onTap: () => onNavigate(item.title),
        child: ConditionalMouseRegion(
          onEnter: (_) {}, 
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 48,
            height: 48,
            decoration: isSelected
                ? AppGlassmorphismV2.finDashActiveItem(
                    accentColor: accentColor,
                    isDark: isDark,
                  )
                : AppGlassmorphismV2.finDashInactiveItem(isDark: isDark),
            child: Icon(
              item.icon,
              color: isSelected 
                  ? accentColor 
                  : (isDark ? Colors.white54 : Colors.black45),
              size: 24,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool isDarkMode,
    required Color color,
    String? tooltip,
  }) {
    return Tooltip(
      message: tooltip ?? '',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
      ),
    );
  }

  Widget _buildUserProfile() {
    return GestureDetector(
      onTap: onProfileTap ?? onLogout, // Use profile tap first, fallback to logout
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFF6C5DD3).withOpacity(0.5),
            width: 2,
          ),
          boxShadow: [
             BoxShadow(
                color: const Color(0xFF6C5DD3).withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
             ),
          ],
        ),
        child: ClipOval(
          child: userAvatarUrl != null
              ? Image.network(
                  userAvatarUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _buildUserInitials(),
                )
              : _buildUserInitials(),
        ),
      ),
    );
  }

  Widget _buildUserInitials() {
    return Container(
      color: const Color(0xFF2C2F36),
      alignment: Alignment.center,
      child: Text(
        (userName ?? userEmail ?? 'U')[0].toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  Color? _getIconColor(String title) {
    // Specific colors for modules
    switch (title.toLowerCase()) {
      case 'dashboard': return const Color(0xFF6C5DD3); // Purple
      case 'market': return const Color(0xFF00D1FF);    // Cyan
      case 'portfolio': return const Color(0xFFFFA500); // Orange/Amber
      case 'trade': return const Color(0xFF4ADE80);     // Green
      case 'analysis': return const Color(0xFFFF6B6B);  // Red
      default: return null;
    }
  }
}


