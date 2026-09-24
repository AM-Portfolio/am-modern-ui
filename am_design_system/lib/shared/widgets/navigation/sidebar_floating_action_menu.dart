import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';

import 'floating_menu_action.dart';

class SidebarFloatingActionMenu extends StatefulWidget {
  const SidebarFloatingActionMenu({
    required this.actions,
    required this.triggerColor,
    super.key,
  });

  final List<FloatingMenuAction> actions;
  final Color triggerColor;

  @override
  State<SidebarFloatingActionMenu> createState() => _SidebarFloatingActionMenuState();
}

class _SidebarFloatingActionMenuState extends State<SidebarFloatingActionMenu> with SingleTickerProviderStateMixin {
  final _overlayController = OverlayPortalController();
  final _layerLink = LayerLink();
  bool _expanded = false;
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    if (_expanded) {
      setState(() {
        _expanded = false;
      });
      _controller.reverse().then((_) {
        if (mounted && !_expanded) {
          _overlayController.hide();
        }
      });
    } else {
      setState(() {
        _expanded = true;
      });
      _overlayController.show();
      _controller.forward(from: 0.0);
    }
  }

  Widget _buildOverlay(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorsTheme>() ?? AppColorsTheme.dark;

    return Stack(
      children: [
        // Invisible tap target to dismiss the menu when clicking anywhere else
        GestureDetector(
          onTap: () {
            if (_expanded) _toggle();
          },
          behavior: HitTestBehavior.opaque,
          child: const SizedBox(
            width: double.infinity,
            height: double.infinity,
          ),
        ),
        CompositedTransformFollower(
          link: _layerLink,
          targetAnchor: Alignment.topCenter,
          followerAnchor: Alignment.bottomCenter,
          offset: const Offset(0, -16),
          child: Material(
            type: MaterialType.transparency,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ...List.generate(widget.actions.length, (index) {
                  final action = widget.actions[index];
                  // 50ms stagger per item
                  final start = (index * 0.1).clamp(0.0, 1.0);
                  final end = (start + 0.6).clamp(0.0, 1.0);

                  final animation = CurvedAnimation(
                    parent: _controller,
                    curve: Interval(start, end, curve: Curves.easeOutBack),
                  );

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: _FloatingMenuPill(
                      action: action,
                      animation: animation,
                      colors: colors,
                      onTap: () {
                        _toggle();
                        action.onTap();
                      },
                    ),
                  );
                }),

                // Faint vertical connector line
                SizeTransition(
                  sizeFactor: _controller,
                  child: Container(
                    height: 16,
                    width: 1.5,
                    color: colors.border.withValues(alpha: 0.4),
                    margin: const EdgeInsets.only(bottom: 8.0),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorsTheme>() ?? AppColorsTheme.dark;

    return CompositedTransformTarget(
      link: _layerLink,
      child: OverlayPortal(
        controller: _overlayController,
        overlayChildBuilder: _buildOverlay,
        child: SizedBox(
          width: double.infinity,
          height: 44, // Fixed height for footer area
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // Extended FAB button (Perfectly centralized, handles text inside)
              GestureDetector(
                onTap: _toggle,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 280),
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    gradient: LinearGradient(
                      colors: [
                        widget.triggerColor,
                        widget.triggerColor.withValues(alpha: 0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: widget.triggerColor.withValues(alpha: 0.45),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedRotation(
                        turns: _expanded ? 0.125 : 0,
                        duration: const Duration(milliseconds: 280),
                        child: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
                      ),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeOutCubic,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!_expanded) ...[
                              const SizedBox(width: 8),
                              const Text(
                                'Sync portfolio',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ]
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FloatingMenuPill extends StatelessWidget {
  const _FloatingMenuPill({
    required this.action,
    required this.animation,
    required this.colors,
    required this.onTap,
  });

  final FloatingMenuAction action;
  final Animation<double> animation;
  final AppColorsTheme colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.3),
        end: Offset.zero,
      ).animate(animation),
      child: FadeTransition(
        opacity: animation,
        child: GestureDetector(
          onTap: onTap,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                // Fixed a fixed width to ensure the pills look uniformly wide and professional
                width: 220, 
                decoration: BoxDecoration(
                  color: colors.surface.withValues(alpha: 0.25), // Higher transparency for true glass effect
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: colors.border.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    // Icon circle
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(colors: [
                          action.iconColor,
                          action.iconColor.withValues(alpha: 0.35),
                        ]),
                      ),
                      child: Icon(action.icon, color: colors.actionPrimaryFg, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            action.title,
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            action.subtitle,
                            style: TextStyle(
                              color: colors.textTertiary,
                              fontStyle: FontStyle.italic,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
