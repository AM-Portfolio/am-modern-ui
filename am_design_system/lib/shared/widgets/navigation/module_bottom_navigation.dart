
import 'package:flutter/material.dart';
import 'package:am_design_system/core/module/module_config.dart';

class ModuleBottomNavigation extends StatelessWidget {
  const ModuleBottomNavigation({
    required this.items,
    required this.currentIndex,
    required this.onTap,
    this.onBackToGlobal,
    this.fabIcon,
    this.onFabTap,
    this.accentColor,
    super.key,
  });

  final List<BottomNavigationBarItem> items;
  final int currentIndex;
  final Function(int) onTap;
  final VoidCallback? onBackToGlobal;
  final IconData? fabIcon;
  final VoidCallback? onFabTap;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final activeColor = accentColor ?? theme.primaryColor;

    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1a1a2e) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Items Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Back/Global Button (Left-most)
                if (onBackToGlobal != null)
                  _buildNavItem(
                    icon: Icons.apps_rounded,
                    label: 'Apps',
                    isSelected: false,
                    isDark: isDark,
                    activeColor: activeColor,
                    onTap: onBackToGlobal!,
                  ),

                // Map items, but skip the middle index if FAB is present
                 ...items.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  
                  // Simple logic: If we have a FAB, we might want to split items around it.
                  // For now, let's just render them.
                  // If we want accurate styling like the image (FAB in center), we need to ensure space.
                  
                  return _buildNavItem(
                    icon: (item.icon as Icon).icon!,
                    label: item.label ?? '',
                    isSelected: currentIndex == index,
                    isDark: isDark,
                    activeColor: activeColor,
                    onTap: () => onTap(index),
                  );
                }).toList(),
              ],
            ),
            
            // FAB (Floating Center)
            if (fabIcon != null)
              Positioned(
                top: -24,
                child: GestureDetector(
                  onTap: onFabTap,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: activeColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: activeColor.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(
                        color: isDark ? const Color(0xFF1a1a2e) : Colors.white,
                        width: 4,
                      ),
                    ),
                    child: Icon(fabIcon, color: Colors.white, size: 28),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required bool isDark,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? activeColor : (isDark ? Colors.white54 : Colors.grey),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? activeColor : (isDark ? Colors.white54 : Colors.grey),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
