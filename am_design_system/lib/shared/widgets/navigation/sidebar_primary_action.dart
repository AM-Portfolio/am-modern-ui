import 'package:flutter/material.dart';
import 'package:am_design_system/core/utils/conditional_mouse_region.dart';


/// Standardized Primary Action Button for Sidebars (e.g., "Add Trade", "New Portfolio")
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
  final bool isCompact;

  @override
  State<SidebarPrimaryAction> createState() => _SidebarPrimaryActionState();
}

class _SidebarPrimaryActionState extends State<SidebarPrimaryAction> with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
       duration: const Duration(milliseconds: 200),
       vsync: this
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut)
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: ConditionalMouseRegion(
        onEnter: (_) {
          setState(() => _isHovered = true);
          _controller.forward();
        },
        onExit: (_) {
          setState(() => _isHovered = false);
          _controller.reverse();
        },
        child: GestureDetector(
          onTap: widget.onTap,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: widget.isCompact 
                ? _buildCompact(color)
                : _buildFull(color),
          ),
        ),
      ),
    );
  }

  Widget _buildFull(Color color) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
          if (_isHovered)
             BoxShadow(
              color: color.withOpacity(0.3),
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
          Text(
            widget.title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompact(Color color) {
    return Container(
      height: 48,
      width: 48,
       decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Icon(widget.icon, color: Colors.white, size: 24),
      ),
    );
  }
}
