import 'package:flutter/material.dart';
import 'package:am_design_system/core/utils/conditional_mouse_region.dart';


class SidebarNavItem<T> extends StatefulWidget {
  const SidebarNavItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    this.isEnabled = true,
    this.isCompact = false,
    this.isCondensed = false,
    this.accentColor = const Color(0xFF06b6d4), // Default Cyan
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final T value;
  final T groupValue;
  final ValueChanged<T> onChanged;
  final bool isEnabled;
  final bool isCompact;
  final bool isCondensed;
  final Color accentColor;

  @override
  State<SidebarNavItem<T>> createState() => _SidebarNavItemState<T>();
}

class _SidebarNavItemState<T> extends State<SidebarNavItem<T>> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.groupValue == widget.value;
    final theme = Theme.of(context);
    final activeColor = widget.accentColor;

    // Compact mode: Icon only with enhanced styling
    if (widget.isCompact) {
      return Tooltip(
        message: widget.title,
        child: _buildInteractiveWrapper(
          isSelected: isSelected,
          child: Container(
            padding: const EdgeInsets.all(12),
            child: Icon(
              widget.icon,
              size: 24,
              color: widget.isEnabled
                  ? (isSelected ? activeColor : Colors.white.withValues(alpha: _isHovered ? 0.9 : 0.6))
                  : Colors.white.withValues(alpha: 0.2),
            ),
          ),
        ),
      );
    }

    // Condensed mode: Icon + abbreviated text
    if (widget.isCondensed) {
      return Tooltip(
        message: widget.subtitle,
        child: _buildInteractiveWrapper(
          isSelected: isSelected,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.icon,
                  size: 20,
                  color: widget.isEnabled
                      ? (isSelected ? activeColor : Colors.white.withValues(alpha: _isHovered ? 0.9 : 0.6))
                      : Colors.white.withValues(alpha: 0.2),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.title.split(' ').first,
                  style: TextStyle(
                    color: widget.isEnabled
                        ? (isSelected ? Colors.white : Colors.white.withValues(alpha: _isHovered ? 0.9 : 0.6))
                        : Colors.white.withValues(alpha: 0.2),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 10,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Full mode: Premium Design
    return _buildInteractiveWrapper(
      isSelected: isSelected,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              widget.icon,
              size: 20,
              color: widget.isEnabled
                  ? (isSelected ? activeColor : Colors.white.withValues(alpha: _isHovered ? 0.9 : 0.6))
                  : Colors.white.withValues(alpha: 0.2),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.title,
                    style: TextStyle(
                      color: widget.isEnabled
                          ? (isSelected ? Colors.white : Colors.white.withValues(alpha: _isHovered ? 0.9 : 0.7))
                          : Colors.white.withValues(alpha: 0.2),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  if (widget.subtitle.isNotEmpty && !widget.isCondensed) ...[
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: isSelected ? 0.7 : (_isHovered ? 0.5 : 0.4)),
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            if (isSelected)
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 300),
                builder: (context, value, child) => Opacity(
                  opacity: value,
                  child: Container(
                    width: 4,
                    height: 16,
                    decoration: BoxDecoration(
                      color: activeColor,
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [
                        BoxShadow(
                          color: activeColor.withValues(alpha: 0.5),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (!widget.isEnabled)
              Icon(Icons.lock_outline, size: 14, color: Colors.white.withValues(alpha: 0.3)),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractiveWrapper({required bool isSelected, required Widget child}) {
    final activeColor = widget.accentColor;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ConditionalMouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.isEnabled ? () => widget.onChanged(widget.value) : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOutCubic,
            decoration: BoxDecoration(
              color: isSelected
                  ? activeColor.withValues(alpha: 0.15)
                  : (_isHovered ? Colors.white.withValues(alpha: 0.05) : Colors.transparent),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? activeColor.withValues(alpha: 0.5)
                    : (_isHovered ? Colors.white.withValues(alpha: 0.1) : Colors.transparent),
                width: 1.5,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: activeColor.withValues(alpha: 0.15),
                        blurRadius: 12,
                        spreadRadius: 2,
                      )
                    ]
                  : _isHovered
                      ? [
                          BoxShadow(
                            color: activeColor.withValues(alpha: 0.08),
                            blurRadius: 8,
                            spreadRadius: 1,
                          )
                        ]
                      : null,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

