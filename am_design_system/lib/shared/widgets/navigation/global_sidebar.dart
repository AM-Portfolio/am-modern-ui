
import 'dart:ui';
import 'package:flutter/material.dart';



import 'package:am_design_system/core/theme/app_glassmorphism_v2.dart';
import 'package:am_design_system/core/theme/app_colors.dart';
import 'package:am_design_system/shared/widgets/navigation/sidebar_item.dart';
import 'package:am_design_system/core/utils/conditional_mouse_region.dart';
import 'package:am_design_system/core/module/module_config.dart';

/// Global Sidebar - Enhanced Glassmorphism Version
/// Incorporates Glass Prism design, module-specific colors, and vertical layout.
class GlobalSidebar extends StatelessWidget {
  const GlobalSidebar({
    required this.activeNavItem,
    required this.onNavigate,
    required this.items,
    super.key,
    this.onLogout,
    this.onThemeToggle,
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
  final String? userName;
  final String? userEmail;
  final String? userAvatarUrl;
  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80, // Slightly wider to accommodate text
      height: double.infinity,
      child: AppGlassmorphismV2.glassPrism(
        isDark: isDarkMode,
        child: Column(
          children: [
            const SizedBox(height: 24),
            // App Logo
            _buildAppLogo(),

            const SizedBox(height: 32),

            // Main Navigation Items
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center, // Center vertically
                  children: items.asMap().entries.map((entry) {
                    final item = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16), // Spacing between items
                      child: _buildNavItem(
                        item,
                        isDarkMode,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            // Bottom Actions
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                children: [
                  // Theme Toggle Button
                  if (onThemeToggle != null) ...[
                    _buildThemeToggle(),
                    const SizedBox(height: 16),
                  ],

                  // User Profile
                  if (userName != null || userEmail != null)
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
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667eea).withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Icon(Icons.show_chart, color: Colors.white, size: 28),
    );
  }

  Widget _buildNavItem(
    SidebarItem item,
    bool isDark,
  ) {
    final isSelected = activeNavItem == item.title;
    final accentColor = _getIconColor(item.title) ?? Colors.blue;

    return GestureDetector(
      onTap: () => onNavigate(item.title),
      child: ConditionalMouseRegion(
        onEnter: (event) {}, // Hover handling if needed in future
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon Container (Pill/Circle)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected ? accentColor : Colors.transparent,
                borderRadius: BorderRadius.circular(16), // Rounded square/pill
                border: isSelected
                    ? null
                    : Border.all(
                        color: isDark
                            ? Colors.white.withOpacity(0.1)
                            : Colors.black.withOpacity(0.1),
                        width: 1,
                      ),
              ),
              child: Icon(
                item.icon,
                color: isSelected
                    ? Colors.white
                    : isDark
                        ? Colors.white70
                        : Colors.black54,
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            // Label
            Text(
              item.title,
              style: TextStyle(
                color: isSelected
                    ? (isDark ? Colors.white : Colors.black87)
                    : (isDark ? Colors.white54 : Colors.black45),
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeToggle() {
    return GestureDetector(
      onTap: onThemeToggle,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDarkMode
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.1),
          ),
          color: isDarkMode
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.02),
        ),
        child: Icon(
          isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
          color: isDarkMode ? const Color(0xFFfbbf24) : const Color(0xFF6366f1),
          size: 20,
        ),
      ),
    );
  }

  Widget _buildUserProfile() {
    return GestureDetector(
      onTap: onLogout,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF667eea).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipOval(
          child: userAvatarUrl != null
              ? Image.network(
                  userAvatarUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Text(
                        (userName ?? userEmail ?? 'U')[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    );
                  },
                )
              : Center(
                  child: Text(
                    (userName ?? userEmail ?? 'U')[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
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
        return ModuleColors.dashboard;
      case 'market':
        return ModuleColors.market;
      case 'trade':
        return ModuleColors.trade;
      case 'portfolio':
        // Using Amber/Orange as per user's preference/image, mapped to 'reports' color
        // or hardcoded if necessary. ModuleColors.reports is Amber (0xFFf59e0b).
        return ModuleColors.reports; 
      case 'profile':
        return ModuleColors.analytics;
      default:
        return ModuleColors.dashboard;
    }
  }
}


