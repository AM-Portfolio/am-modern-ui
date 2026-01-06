
import 'package:flutter/material.dart';
import 'dart:ui';
import '../../../core/theme/app_glassmorphism_v2.dart';
import '../../../core/module/module_color_provider.dart';
import '../../../core/module/module_type.dart';
import '../../../core/theme/app_glassmorphism.dart'; // For GradientBorderPainter



import '../navigation/secondary_sidebar.dart';
import '../navigation/module_bottom_navigation.dart';

/// A unified scaffold that handles the responsive sidebar logic for all AM modules.
///
/// This component automatically manages:
/// 1. **Response Widths**: Switches between Mobile (Drawer), Tablet (Compact), and Desktop (Full).
/// 2. **Animations**: Smoothly transitions sidebar width.
/// 3. **Theming**: Applies the correct glassmorphic theme and accent colors.
///
/// Usage:
/// ```dart
/// UnifiedSidebarScaffold(
///   title: "Market Data",
///   icon: Icons.trending_up,
///   accentColor: Colors.cyan,
///   body: YourPageContent(),
///   items: sidebarItems, // List of SecondarySidebarItem
///   // OR
///   sections: sidebarSections, // List of SecondarySidebarSection
/// )
/// ```
class UnifiedSidebarScaffold extends StatefulWidget {
  /// Callback to navigate back to global context (for Mobile Bottom Nav "Menu" or "Back" action)
  final VoidCallback? onBackToGlobal;
  final VoidCallback? onThemeToggle;
  final VoidCallback? onProfileTap;
  final VoidCallback? onLogout;

  const UnifiedSidebarScaffold({
    required this.body,
    super.key,
    this.module,
    this.title,
    this.subtitle,
    this.icon,
    this.accentColor = Colors.blue,
    this.items,
    this.sections,
    this.header,
    this.isDark = true,
    this.desktopBreakpoint = 1200,
    this.tabletBreakpoint = 800,
    this.fullWidth = 280,
    this.compactWidth = 72,
    this.condensedWidth = 200,
    this.forceCompact = false,
    this.floatingActionButton,
    this.onBackToGlobal,
    this.onThemeToggle,
    this.onProfileTap,
    this.onLogout,

    this.footer,
    this.enableGlass = false,
  }) : assert((items != null) != (sections != null), 'Provide either items or sections, not both.');

  /// The main content of the page
  final Widget body;

  /// The module this scaffold represents (optional, provides defaults)
  final ModuleType? module;

  /// Sidebar Title (e.g. "Market Data")
  final String? title;

  /// Sidebar Subtitle (e.g. "Real-time Analytics")
  final String? subtitle;

  /// Sidebar Icon
  final IconData? icon;

  /// Primary accent color for the sidebar elements
  final Color accentColor;

  /// List of flat items (Launcher Style)
  final List<SecondarySidebarItem>? items;

  /// List of grouped sections (Workspace Style)
  final List<SecondarySidebarSection>? sections;

  /// Custom footer widget
  final Widget? footer;

  /// Custom header widget (overrides default title/icon)
  final Widget? header;

  /// Whether to render in dark mode (default true)
  final bool isDark;

  /// Width above which sidebar is fully expanded
  final double desktopBreakpoint;

  /// Width below which sidebar becomes a drawer (Mobile)
  final double tabletBreakpoint;

  /// Width of full sidebar
  final double fullWidth;

  /// Width of compact sidebar (Icon only)
  final double compactWidth;

  /// Width of condensed sidebar
  final double condensedWidth;

  /// Force compact mode regardless of screen width
  final bool forceCompact;

  /// Floating Action Button to display on the scaffold
  final Widget? floatingActionButton;

  /// Enable full-screen glassmorphism background
  final bool enableGlass;

  @override
  State<UnifiedSidebarScaffold> createState() => _UnifiedSidebarScaffoldState();
}

class _UnifiedSidebarScaffoldState extends State<UnifiedSidebarScaffold> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _widthAnimation;
  bool _isManuallyCollapsed = false;
  int _mobileSelectedIndex = 0; // Track selected index for Bottom Nav

  // Resolved properties from ModuleType or direct overrides
  String? get _resolvedTitle => widget.title ?? widget.module?.title;
  String? get _resolvedSubtitle => widget.subtitle ?? widget.module?.subtitle;
  IconData? get _resolvedIcon => widget.icon ?? widget.module?.icon;
  Color get _resolvedColor => widget.module?.accentColor ?? widget.accentColor;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _widthAnimation = Tween<double>(begin: widget.compactWidth, end: widget.fullWidth)
        .animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOutCubic));
    
    // Default to open
    _animationController.value = 1.0;
  }

  // ... (Keep dispose and toggleSidebar)

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleSidebar() {
    setState(() {
      _isManuallyCollapsed = !_isManuallyCollapsed;
      if (_isManuallyCollapsed) {
        _animationController.reverse();
      } else {
        _animationController.forward();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isDesktop = width >= widget.desktopBreakpoint;
        final isTablet = width >= widget.tabletBreakpoint && width < widget.desktopBreakpoint;
        final isMobile = width < widget.tabletBreakpoint;

        // Mobile Layout: Bottom Navigation
        if (isMobile) {
          return Scaffold(
            appBar: AppBar(
              title: Text(_resolvedTitle ?? ''),
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
              leading: widget.onBackToGlobal != null 
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: widget.onBackToGlobal,
                    )
                  : null,
            ),
            body: widget.body,
            bottomNavigationBar: _buildBottomNavigationBar(context),
            floatingActionButton: widget.floatingActionButton,
          );
        }

        // Desktop / Tablet Layout
        bool isCompact = false;
        double targetWidth = widget.fullWidth; 

        if (widget.forceCompact || _isManuallyCollapsed) {
          isCompact = true;
          targetWidth = widget.compactWidth;
        } else if (isTablet) {
          isCompact = true;
          targetWidth = widget.compactWidth;
        } else {
          // Full Desktop
          isCompact = false;
          targetWidth = widget.fullWidth;
        }
        
        // Animate to new target
        if (targetWidth != _widthAnimation.value && !_animationController.isAnimating) {
             _animationController.animateTo(
                isCompact ? 0.0 : 1.0, 
                duration: const Duration(milliseconds: 300)
             );
        }

        // Background Decoration (Glass vs Solid)
        final bgDecoration = widget.enableGlass 
            ? AppGlassmorphismV2.techBackground(isDark: widget.isDark)
            : BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor);

        // Body Color (Transparent if Glass, else default)
        final bodyColor = widget.enableGlass 
            ? Colors.transparent 
            : Theme.of(context).scaffoldBackgroundColor;


        return Scaffold(
          resizeToAvoidBottomInset: false,
          floatingActionButton: widget.floatingActionButton,
          body: widget.module != null
              ? ModuleColorProvider(
                  module: widget.module!,
                  child: Container(
                    decoration: bgDecoration,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Main Content
                        Positioned(
                          left: widget.fullWidth, // Static width
                          top: 0,
                          right: 0,
                          bottom: 0,
                          child: Container(
                            clipBehavior: Clip.hardEdge,
                            decoration: BoxDecoration(
                              color: bodyColor,
                            ),
                            child: widget.body,
                          ),
                        ),

                        // Sidebar
                        Positioned(
                          left: 0,
                          top: 0,
                          bottom: 0,
                          width: widget.fullWidth,
                          child: Container(
                            color: Colors.transparent,
                            child: SizedBox(
                              width: widget.fullWidth,
                              child: _buildSidebarContent(
                                isFull: true,
                                isCondensed: false,
                                isCompact: false,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Container(
                  decoration: bgDecoration,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Main Content
                      Positioned(
                        left: widget.fullWidth, // Static width
                        top: 0,
                        right: 0,
                        bottom: 0,
                        child: Container(
                          clipBehavior: Clip.hardEdge,
                          decoration: BoxDecoration(
                            color: bodyColor,
                          ),
                          child: widget.body,
                        ),
                      ),

                      // Sidebar
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        width: widget.fullWidth,
                        child: Container(
                          color: Colors.transparent,
                          child: SizedBox(
                            width: widget.fullWidth,
                            child: _buildSidebarContent(
                              isFull: true,
                              isCondensed: false,
                              isCompact: false,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    // 1. Flatten items list
    List<SecondarySidebarItem> flatItems = [];
    if (widget.items != null) {
      flatItems = widget.items!;
    } else if (widget.sections != null) {
      for (var section in widget.sections!) {
        if (section.items != null) {
          flatItems.addAll(section.items!);
        }
      }
    }

    // Convert to BottomNavigationBarItems
    // Limit to 4 items + Global Back Button logic handled inside ModuleBottomNavigation
    final displayItems = flatItems.take(4).toList();
    
    // Check if we have a primary action (FAB) to show
    // We can infer this from the floatingActionButton widget if it's an Icon? 
    // Or we rely on the ModuleBottomNavigation's standard styling.
    // For now, let's just use the navigation items.
    
    final navItems = displayItems.map((item) => BottomNavigationBarItem(
      icon: Icon(item.icon),
      label: item.title,
    )).toList();

    return ModuleBottomNavigation(
      items: navItems,
      currentIndex: _mobileSelectedIndex < displayItems.length ? _mobileSelectedIndex : 0,
      onTap: (index) {
         if (index < displayItems.length) {
           setState(() {
             _mobileSelectedIndex = index;
           });
           displayItems[index].onTap?.call();
         }
      },
      onBackToGlobal: widget.onBackToGlobal,
      accentColor: _resolvedColor,
      // We can pass a FAB icon if we want the "Center +" look. 
      // This would ideally come from a property "primaryAction" or similar.
      // For now, we leave it layout-only, and let the Scaffold's FAB float above if set.
      // But ModuleBottomNavigation has layout for it.
      // Let's assume we want the specific visual from the image (embedded FAB).
      fabIcon: Icons.add, // Placeholder or passed prop? 
      onFabTap: () {
        // Trigger generic primary action?
        // Ideally we expose a callback "onPrimaryAction"
        // For now, if widget.floatingActionButton is meant to be the primary action...
      },
    );
  }

  void _showMobileMenu(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Menu',
      barrierColor: Colors.black.withOpacity(0.6),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) => const SizedBox(),
      transitionBuilder: (context, anim1, anim2, child) {
        final curve = CurvedAnimation(parent: anim1, curve: Curves.easeOutBack);
        
        return Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Positioned(
              bottom: 100, // Float above bottom nav
              left: 16,
              right: 16,
              child: ScaleTransition(
                scale: curve,
                child: FadeTransition(
                  opacity: anim1,
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.6,
                      ),
                      decoration: AppGlassmorphismV2.gradientBorderCard(
                        borderColors: [_resolvedColor, _resolvedColor.withOpacity(0.3)],
                        borderRadius: 24,
                        isDark: true, // Force dark premium look as per request
                        isGlowing: true,
                        borderWidth: 1.5,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Header
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: AppGlassmorphismV2.iconGlassContainer(
                                        color: _resolvedColor,
                                        size: 36,
                                        isDark: true,
                                      ),
                                      child: Icon(_resolvedIcon ?? Icons.menu, color: _resolvedColor, size: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _resolvedTitle ?? 'Menu',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        if (_resolvedSubtitle != null)
                                          Text(
                                            _resolvedSubtitle!,
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(0.6),
                                              fontSize: 12,
                                            ),
                                          ),
                                      ],
                                    ),
                                    const Spacer(),
                                    IconButton(
                                      icon: const Icon(Icons.close, color: Colors.white54),
                                      onPressed: () => Navigator.pop(context),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                const Divider(color: Colors.white10),
                                const SizedBox(height: 10),

                                // Actions & Custom Widgets
                                if (widget.sections != null)
                                  ...widget.sections!.where((s) => s.customWidget != null).map((section) {
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 16),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.03),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: Colors.white.withOpacity(0.05)),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          if (section.title.isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(bottom: 10, left: 4),
                                              child: Text(
                                                section.title.toUpperCase(),
                                                style: TextStyle(
                                                color: _resolvedColor.withOpacity(0.8),
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: 1.5,
                                                ),
                                              ),
                                            ),
                                          section.customWidget!,
                                        ],
                                      ),
                                    );
                                  }),

                                // Back to Dashboard Button
                                if (widget.onBackToGlobal != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: InkWell(
                                      onTap: () {
                                        Navigator.pop(context);
                                        widget.onBackToGlobal!();
                                      },
                                      borderRadius: BorderRadius.circular(16),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              const Color(0xFFFF6B6B).withOpacity(0.2),
                                              const Color(0xFFFF6B6B).withOpacity(0.05),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(
                                            color: const Color(0xFFFF6B6B).withOpacity(0.3),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Icon(Icons.logout_rounded, color: Color(0xFFFF6B6B), size: 20),
                                            const SizedBox(width: 10),
                                            const Text(
                                              'Back to Dashboard',
                                              style: TextStyle(
                                                color: Color(0xFFFF6B6B),
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                
                                // Theme Toggle Button
                                if (widget.onThemeToggle != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 12),
                                    child: InkWell(
                                      onTap: () {
                                        Navigator.pop(context);
                                        widget.onThemeToggle!();
                                      },
                                      borderRadius: BorderRadius.circular(16),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              _resolvedColor.withOpacity(0.2),
                                              _resolvedColor.withOpacity(0.05),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(
                                            color: _resolvedColor.withOpacity(0.3),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Theme.of(context).brightness == Brightness.dark
                                                  ? Icons.light_mode_rounded
                                                  : Icons.dark_mode_rounded,
                                              color: _resolvedColor,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 10),
                                            Text(
                                              Theme.of(context).brightness == Brightness.dark
                                                  ? 'Switch to Light Mode'
                                                  : 'Switch to Dark Mode',
                                              style: TextStyle(
                                                color: _resolvedColor,
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                
                                // Profile & Settings Button
                                if (widget.onProfileTap != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 12),
                                    child: InkWell(
                                      onTap: () {
                                        Navigator.pop(context);
                                        widget.onProfileTap!();
                                      },
                                      borderRadius: BorderRadius.circular(16),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              _resolvedColor.withOpacity(0.15),
                                              _resolvedColor.withOpacity(0.05),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(
                                            color: _resolvedColor.withOpacity(0.2),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.person_outline_rounded,
                                              color: _resolvedColor,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 10),
                                            Text(
                                              'Profile & Settings',
                                              style: TextStyle(
                                                color: _resolvedColor,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                
                                // Logout Button
                                if (widget.onLogout != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 12),
                                    child: InkWell(
                                      onTap: () {
                                        Navigator.pop(context);
                                        widget.onLogout!();
                                      },
                                      borderRadius: BorderRadius.circular(16),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                                        decoration: BoxDecoration(
                                          color: Colors.red.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(
                                            color: Colors.red.withOpacity(0.3),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.logout_rounded,
                                              color: Colors.red,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 10),
                                            Text(
                                              'Logout',
                                              style: TextStyle(
                                                color: Colors.red,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSidebarContent({
    required bool isFull,
    required bool isCondensed,
    required bool isCompact,
  }) {
    return Theme(
      data: Theme.of(context).copyWith(
        primaryColor: _resolvedColor,
        colorScheme: Theme.of(context).colorScheme.copyWith(
          primary: _resolvedColor,
          secondary: _resolvedColor,
        ),
      ),
      child: SecondarySidebar(
        title: _resolvedTitle,
        subtitle: _resolvedSubtitle,
        icon: _resolvedIcon ?? Icons.dashboard,
        accentColor: _resolvedColor,
        // isDark: widget.isDark, // Removed as it's not a valid parameter
        width: widget.fullWidth, // Internal width is handled by SecondarySidebar logic
        items: widget.items,
        sections: widget.sections,
        footer: widget.footer,
        header: widget.header,
      ),
    );
  }
}
