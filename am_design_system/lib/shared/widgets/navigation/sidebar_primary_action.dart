import 'package:flutter/material.dart';
import 'package:am_design_system/core/utils/conditional_mouse_region.dart';

/// Standardized Primary Action Button for Sidebars (e.g., "Add Trade", "New Portfolio")
///
/// Auto-compacts to an icon-only 40×40 control when the footer slot is narrow
/// (`maxWidth < 120`), matching [SidebarFloatingActionMenu] collapsed behavior.
class SidebarPrimaryAction extends StatefulWidget {
  const SidebarPrimaryAction({
    required this.title,
    required this.onTap,
    this.icon = Icons.add,
    this.accentColor,
    this.isCompact = false,
    super.key,
  });

  final String title;
  final VoidCallback onTap;
  final IconData icon;
  final Color? accentColor;

  /// Force compact (icon-only). Also auto-enabled when layout width &lt; 120.
  final bool isCompact;

  @override
  State<SidebarPrimaryAction> createState() => _SidebarPrimaryActionState();
}

class _SidebarPrimaryActionState extends State<SidebarPrimaryAction>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  static const double _compactThreshold = 120;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.accentColor ?? Theme.of(context).primaryColor;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact =
            widget.isCompact || constraints.maxWidth < _compactThreshold;

        return Padding(
          // No horizontal padding in compact — footer slot is ~40px when
          // SecondarySidebar is collapsed (72 − 16 − 16).
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 0 : 16,
            vertical: isCompact ? 8 : 12,
          ),
          child: Align(
            alignment: Alignment.center,
            child: ConditionalMouseRegion(
              cursor: SystemMouseCursors.click,
              onEnter: (_) {
                setState(() => _isHovered = true);
                _controller.forward();
              },
              onExit: (_) {
                setState(() => _isHovered = false);
                _controller.reverse();
              },
              child: Tooltip(
                message: widget.title,
                child: GestureDetector(
                  onTap: widget.onTap,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: isCompact
                        ? _buildCompact(color)
                        : _buildFull(color),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFull(Color color) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
          if (_isHovered)
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(widget.icon, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              widget.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompact(Color color) {
    return Container(
      height: 40,
      width: 40,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Icon(widget.icon, color: Colors.white, size: 22),
      ),
    );
  }
}
