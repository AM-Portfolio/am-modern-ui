import 'package:flutter/material.dart';
import 'package:am_design_system/core/theme/app_glassmorphism_v2.dart';


/// Standardized Container for Sidebar Selectors (e.g., Portfolio Dropdown)
class SidebarSelector extends StatelessWidget {
  const SidebarSelector({
    required this.child,
    this.accentColor,
    this.isCompact = false,
    super.key,
  });

  final Widget child;
  final Color? accentColor;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (isCompact) {
       // In compact mode, we normally don't show full selectors, or might show a simplified icon
       // For now returning the child which is likely sized correctly by parent
       return const SizedBox.shrink(); 
    }

    return Container(
      decoration: AppGlassmorphismV2.gradientBorderCard(
        borderColors: [
          (accentColor ?? Colors.white).withOpacity(isDark ? 0.3 : 0.2), 
          (accentColor ?? Colors.white).withOpacity(isDark ? 0.1 : 0.05)
        ],
        borderRadius: 16,
        isDark: isDark,
        isGlowing: false,
      ),
      child: child, // The actual dropdown logic resides in the child
    );
  }
}
