import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:am_design_system/core/navigation/app_web_navigation.dart';
import 'package:am_design_system/core/theme/app_glassmorphism_v2.dart';
import 'package:am_design_system/core/theme/app_colors.dart';
import 'package:am_design_system/core/theme/app_colors_theme.dart';
import 'package:am_design_system/core/theme/color_extensions.dart';
import 'package:am_design_system/shared/widgets/navigation/sidebar_item.dart';
import 'package:am_design_system/core/utils/conditional_mouse_region.dart';
import 'package:am_design_system/core/module/module_config.dart';
import 'package:am_design_system/shared/widgets/share/share_link_button.dart';

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
    this.onProfileTap,
    this.userName,
    this.userEmail,
    this.userAvatarUrl,
    this.isDarkMode = false,
    this.moduleShareUrls,
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
  final Map<String, String>? moduleShareUrls;

  @override
  Widget build(BuildContext context) {
    // Thin strip width
    const double width = 80.0; // Slightly wider for better spacing
    final surface = Theme.of(context).extension<AppColorsTheme>()?.surface ??
        (isDarkMode ? const Color(0xFF1a1a2e) : Colors.white);

    return AppGlassmorphismV2.glassPrism(
      isDark: isDarkMode,
      surfaceColor: surface,
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
                        navPath: moduleShareUrls?[item.title],
                        onTap: () => onNavigate(item.title),
                        onLongPress: moduleShareUrls?[item.title] == null
                            ? null
                            : () => copyShareLink(
                                  context,
                                  _fullShareUrl(context, moduleShareUrls![item.title]!),
                                ),
                        longPressTooltip: 'Copy link to ${item.title}',
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
                  // Theme picker (full catalog — same as Profile)
                  if (onThemeToggle != null) ...[
                    _buildActionButton(
                      icon: Icons.palette_rounded,
                      onTap: onThemeToggle!,
                      isDarkMode: isDarkMode,
                      tooltip: 'Select Theme',
                      color: Theme.of(context).colorScheme.primary,
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
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => onNavigate('Dashboard'),
        child: Container(
          width: 64,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: isDarkMode ? const Color(0xFF0A0F1A) : Colors.white,
            border: Border.all(
              color: isDarkMode
                  ? Colors.white.withOpacity(0.08)
                  : Colors.black.withOpacity(0.06),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Image.asset(
            'assets/images/app_icon_new.jpg',
            fit: BoxFit.contain,
            alignment: Alignment.center,
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
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
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
      ),
    );
  }

  Widget _buildUserProfile() {
    return Builder(
      builder: (context) {
        final themeColors = context.colors;
        final accent = Theme.of(context).colorScheme.primary;
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: PopupMenuButton<String>(
            offset: const Offset(60, -120),
            tooltip: 'Profile Options',
            color: themeColors.cardSurface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: themeColors.border.withValues(alpha: 0.35),
              ),
            ),
            onSelected: (value) {
              if (value == 'profile') {
                onProfileTap?.call();
              } else if (value == 'logout') {
                onLogout?.call();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(
                      Icons.person_outline_rounded,
                      color: themeColors.textPrimary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Profile & Settings',
                      style: TextStyle(
                        color: themeColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(
                      Icons.logout_rounded,
                      color: themeColors.statusError,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Logout',
                      style: TextStyle(
                        color: themeColors.statusError,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: accent.withValues(alpha: 0.5),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.2),
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
          ),
        );
      },
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
    switch (title.toLowerCase()) {
      case 'dashboard':
        return ModuleColors.dashboard;
      case 'market':
        return ModuleColors.market;
      case 'portfolio':
        return ModuleColors.portfolio;
      case 'trade':
        return ModuleColors.trade;
      case 'analysis':
        return ModuleColors.portfolio;
      case 'ai chat':
        return ModuleColors.aiChat;
      default:
        return null;
    }
  }

  String _fullShareUrl(BuildContext context, String path) {
    final base = Uri.base;
    if (base.hasScheme && base.host.isNotEmpty) {
      return base.replace(path: path, query: '', fragment: '').toString();
    }
    return path;
  }
}

class _GlobalSidebarItem extends StatefulWidget {
  final SidebarItem item;
  final bool isDark;
  final bool isActive;
  final Color accentColor;
  final String? navPath;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final String? longPressTooltip;

  const _GlobalSidebarItem({
    required this.item,
    required this.isDark,
    required this.isActive,
    required this.accentColor,
    this.navPath,
    required this.onTap,
    this.onLongPress,
    this.longPressTooltip,
  });

  @override
  State<_GlobalSidebarItem> createState() => _GlobalSidebarItemState();
}

class _GlobalSidebarItemState extends State<_GlobalSidebarItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.isActive;
    final tooltip = kIsWeb && widget.navPath != null
        ? '${widget.item.title}\nCtrl+click to open in new tab'
        : widget.item.title;

    return Tooltip(
      message: tooltip,
      preferBelow: false,
      child: Listener(
        onPointerDown: (event) {
          final path = widget.navPath;
          if (path == null) return;
          if (event.buttons == kMiddleMouseButton) {
            AppWebNavigation.navigate(
              context: context,
              path: path,
              onSameTab: widget.onTap,
              pointerDown: event,
            );
          }
        },
        child: GestureDetector(
          onTap: () {
            final path = widget.navPath;
            if (path == null) {
              widget.onTap();
              return;
            }
            AppWebNavigation.navigate(
              context: context,
              path: path,
              onSameTab: widget.onTap,
            );
          },
          onLongPress: widget.onLongPress,
          child: ConditionalMouseRegion(
          cursor: SystemMouseCursors.click,
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
      ),
    );
  }
}


