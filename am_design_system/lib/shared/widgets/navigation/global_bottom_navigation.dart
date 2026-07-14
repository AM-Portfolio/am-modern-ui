import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:am_design_system/core/theme/app_colors.dart';
import 'package:am_design_system/shared/widgets/navigation/sidebar_item.dart';

/// Premium floating bottom navigation bar with glassmorphism effect.
///
/// Shows exactly [visibleCount] destinations at a time; extra items are
/// reached by horizontal scroll, and the active item is scrolled into view.
class GlobalBottomNavigation extends StatefulWidget {
  const GlobalBottomNavigation({
    required this.activeNavItem,
    required this.onNavigate,
    required this.items,
    super.key,
    this.onProfileTap,
    this.userName,
    this.isDarkMode = false,
    this.visibleCount = 4,
  });

  final String activeNavItem;
  final Function(String) onNavigate;
  final List<SidebarItem> items;
  final VoidCallback? onProfileTap;
  final String? userName;
  final bool isDarkMode;

  /// How many destinations fit in the visible bar (default 4).
  final int visibleCount;

  @override
  State<GlobalBottomNavigation> createState() => _GlobalBottomNavigationState();
}

class _GlobalBottomNavigationState extends State<GlobalBottomNavigation> {
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _itemKeys = {};

  static const double _horizontalPadding = 6;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollActiveIntoView());
  }

  @override
  void didUpdateWidget(covariant GlobalBottomNavigation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeNavItem != widget.activeNavItem ||
        oldWidget.items.length != widget.items.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollActiveIntoView());
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  GlobalKey _keyFor(String title) =>
      _itemKeys.putIfAbsent(title, GlobalKey.new);

  void _scrollActiveIntoView() {
    if (!mounted || widget.activeNavItem.isEmpty) return;
    final ctx = _keyFor(widget.activeNavItem).currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      alignment: 0.5,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleCount =
        widget.visibleCount.clamp(1, widget.items.isEmpty ? 1 : widget.items.length);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      color: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 68,
            decoration: BoxDecoration(
              color: widget.isDarkMode
                  ? const Color(0xFF1a1a2e).withValues(alpha: 0.85)
                  : Colors.white.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: widget.isDarkMode
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.06),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: widget.isDarkMode ? 0.35 : 0.12,
                  ),
                  blurRadius: 24,
                  offset: const Offset(0, 4),
                ),
                if (widget.isDarkMode)
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    blurRadius: 40,
                    spreadRadius: -4,
                    offset: const Offset(0, 2),
                  ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final viewportWidth =
                      constraints.maxWidth - (_horizontalPadding * 2);
                  final itemWidth = viewportWidth / visibleCount;

                  return ListView.builder(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: _horizontalPadding,
                    ),
                    itemCount: widget.items.length,
                    itemBuilder: (context, index) {
                      final item = widget.items[index];
                      final isActive = widget.activeNavItem == item.title;
                      final accentColor =
                          _getIconColor(item.title) ?? AppColors.primary;

                      return KeyedSubtree(
                        key: _keyFor(item.title),
                        child: GestureDetector(
                          onTap: () => widget.onNavigate(item.title),
                          behavior: HitTestBehavior.opaque,
                          child: SizedBox(
                            width: itemWidth,
                            child: _NavItem(
                              icon: item.icon,
                              label: item.title,
                              isActive: isActive,
                              accentColor: accentColor,
                              isDarkMode: widget.isDarkMode,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
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
      case 'doc intel':
        return const Color(0xFF00D2D3);
      case 'subscription':
        return const Color(0xFFFF9F43);
      case 'profile':
        return const Color(0xFF8B7EE0);
      case 'ai chat':
        return const Color(0xFF6C5DD3);
      case 'analysis':
        return const Color(0xFF0984E3);
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
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final Color accentColor;
  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    final inactiveColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.45)
        : Colors.grey.shade500;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
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
                        color: accentColor.withValues(alpha: 0.5),
                        blurRadius: 6,
                      ),
                    ]
                  : [],
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isActive
                  ? accentColor.withValues(alpha: isDarkMode ? 0.15 : 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: isActive ? accentColor : inactiveColor,
              size: isActive ? 24 : 22,
            ),
          ),
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
