
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
            const SizedBox(height: 48),
            
            // 1. App Logo / Brand Icon
            _buildAppLogo(),

            const SizedBox(height: 48),

            // 2. Main Navigation Icons
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: items.map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 32),
                      child: _GlobalSidebarItem(
                        item: item,
                        isDark: isDarkMode,
                        isActive: activeNavItem == item.title,
                        accentColor: _getIconColor(item.title) ?? const Color(0xFF6C5DD3),
                        onTap: () => onNavigate(item.title),
                      ),
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
      child: Icon(
        Icons.token, 
        color: isDarkMode ? Colors.white : const Color(0xFF6C5DD3), 
        size: 28
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
              color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.transparent,
              border: Border.all(
                color: isDarkMode ? Colors.white.withOpacity(0.1) : const Color(0xFF6C5DD3).withOpacity(0.2)
              ),
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
      case 'dashboard': return AppColors.primary;
      case 'market': return AppColors.marketAccent;
      case 'portfolio': return AppColors.portfolioAccent;
      case 'trade': return AppColors.tradeAccent;
      case 'analysis': return AppColors.accentPink; // Analysis often uses red/pink
      default: return null;
    }
  }
}

class _GlobalSidebarItem extends StatefulWidget {
  final SidebarItem item;
  final bool isDark;
  final bool isActive;
  final Color accentColor;
  final VoidCallback onTap;

  const _GlobalSidebarItem({
    required this.item,
    required this.isDark,
    required this.isActive,
    required this.accentColor,
    required this.onTap,
  });

  @override
  State<_GlobalSidebarItem> createState() => _GlobalSidebarItemState();
}

class _GlobalSidebarItemState extends State<_GlobalSidebarItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.isActive;
    
    return Tooltip(
      message: widget.item.title,
      preferBelow: false,
      child: GestureDetector(
        onTap: widget.onTap,
        child: ConditionalMouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 56,
            height: 56,
            decoration: isSelected
                ? AppGlassmorphismV2.finDashActiveItem(
                    accentColor: widget.accentColor,
                    isDark: widget.isDark,
                  )
                : AppGlassmorphismV2.finDashInactiveItem(isDark: widget.isDark),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  widget.item.icon,
                  // Color Logic: If selected OR hovered, use accent color. Else use inactive color.
                  color: (isSelected || _isHovered)
                      ? widget.accentColor 
                      : (widget.isDark ? Colors.white54 : Colors.black87),
                  size: 24,
                ),
                const SizedBox(height: 4),
                Text(
                  widget.item.title,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: (isSelected || _isHovered)
                      ? widget.accentColor 
                      : (widget.isDark ? Colors.white54 : Colors.black87),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.visible,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


