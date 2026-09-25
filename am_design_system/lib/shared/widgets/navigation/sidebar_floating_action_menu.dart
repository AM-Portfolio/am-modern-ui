import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';

/// A floating action button that expands into a menu of actions.
///
/// Two visual modes:
/// - [compact] = false (default): Full-width pill button. Use in sidebar footer (desktop).
/// - [compact] = true:            Small 40×40 circle icon button. Use in AppBar.actions (web/top-nav).
///
/// [direction] controls which way the popup opens:
/// - [AxisDirection.up]   (default): Menu pops upward from the trigger (sidebar footer).
/// - [AxisDirection.down]:           Menu pops downward from the trigger (AppBar top-nav).
class SidebarFloatingActionMenu extends StatefulWidget {
  const SidebarFloatingActionMenu({
    required this.actions,
    required this.triggerColor,
    this.direction = AxisDirection.up,
    this.compact = false,
    super.key,
  });

  final List<FloatingMenuAction> actions;
  final Color triggerColor;
  final AxisDirection direction;

  /// When true, renders a compact 40×40 circle icon button instead of the
  /// full-width sidebar pill. Use this when placing the button in AppBar.actions.
  final bool compact;

  @override
  State<SidebarFloatingActionMenu> createState() => _SidebarFloatingActionMenuState();
}

class _SidebarFloatingActionMenuState extends State<SidebarFloatingActionMenu>
    with SingleTickerProviderStateMixin {
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
    final isUp = widget.direction == AxisDirection.up;

    return Stack(
      children: [
        // Invisible full-screen tap target to dismiss when clicking outside
        GestureDetector(
          onTap: () {
            if (_expanded) _toggle();
          },
          behavior: HitTestBehavior.opaque,
          child: const SizedBox(width: double.infinity, height: double.infinity),
        ),
        CompositedTransformFollower(
          link: _layerLink,
          targetAnchor: isUp ? Alignment.topCenter : Alignment.bottomCenter,
          followerAnchor: isUp ? Alignment.bottomCenter : Alignment.topCenter,
          offset: isUp ? const Offset(0, -12) : const Offset(0, 12),
          child: Material(
            type: MaterialType.transparency,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Connector line (between trigger and first item)
                if (!isUp)
                  SizeTransition(
                    sizeFactor: _controller,
                    child: Container(
                      height: 12,
                      width: 1.5,
                      color: colors.border.withValues(alpha: 0.4),
                      margin: const EdgeInsets.only(bottom: 6.0),
                    ),
                  ),

                ...List.generate(widget.actions.length, (index) {
                  final action = widget.actions[index];
                  final start = (index * 0.1).clamp(0.0, 1.0);
                  final end = (start + 0.6).clamp(0.0, 1.0);

                  final animation = CurvedAnimation(
                    parent: _controller,
                    curve: Interval(start, end, curve: Curves.easeOutBack),
                  );

                  return Padding(
                    padding: isUp
                        ? const EdgeInsets.only(bottom: 8.0)
                        : const EdgeInsets.only(top: 8.0),
                    child: _FloatingMenuPill(
                      action: action,
                      animation: animation,
                      direction: widget.direction,
                      colors: colors,
                      onTap: () {
                        // Close menu first, then fire action after 180ms so the
                        // close animation completes before any navigation/rebuild.
                        _toggle();
                        Future.delayed(
                          const Duration(milliseconds: 180),
                          action.onTap,
                        );
                      },
                    ),
                  );
                }),

                // Connector line (between last item and trigger for up-direction)
                if (isUp)
                  SizeTransition(
                    sizeFactor: _controller,
                    child: Container(
                      height: 12,
                      width: 1.5,
                      color: colors.border.withValues(alpha: 0.4),
                      margin: const EdgeInsets.only(top: 6.0),
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
    return CompositedTransformTarget(
      link: _layerLink,
      child: OverlayPortal(
        controller: _overlayController,
        overlayChildBuilder: _buildOverlay,
        child: widget.compact ? _buildCompactTrigger() : _buildFullPillTrigger(),
      ),
    );
  }

  /// Compact 40×40 circle button — for use in AppBar.actions (top nav bar).
  Widget _buildCompactTrigger() {
    return Tooltip(
      message: _expanded ? 'Close' : 'Quick Actions',
      child: GestureDetector(
        onTap: _toggle,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _expanded
                ? widget.triggerColor.withValues(alpha: 0.85)
                : widget.triggerColor,
            boxShadow: [
              BoxShadow(
                color: widget.triggerColor.withValues(alpha: _expanded ? 0.55 : 0.35),
                blurRadius: _expanded ? 18 : 10,
                spreadRadius: _expanded ? 2 : 0,
              ),
            ],
          ),
          child: Center(
            child: AnimatedRotation(
              turns: _expanded ? 0.125 : 0,
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeInOutCubic,
              child: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
            ),
          ),
        ),
      ),
    );
  }

  /// Full-width pill button — for use in sidebar footer (desktop/web sidebar).
  Widget _buildFullPillTrigger() {
    return Align(
      alignment: Alignment.center,
      child: SizedBox(
        height: 44,
        child: GestureDetector(
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
    this.direction = AxisDirection.up,
  });

  final FloatingMenuAction action;
  final Animation<double> animation;
  final AppColorsTheme colors;
  final VoidCallback onTap;
  final AxisDirection direction;

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: direction == AxisDirection.up
            ? const Offset(0, 0.3)
            : const Offset(0, -0.3),
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
                width: 220,
                decoration: BoxDecoration(
                  color: colors.surface.withValues(alpha: 0.25),
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
