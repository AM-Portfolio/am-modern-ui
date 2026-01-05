import 'package:flutter/material.dart';

import 'filter_group.dart';

/// Modern collapsible filter group card with smooth animations
class FilterGroupCard extends StatefulWidget {
  const FilterGroupCard({required this.filterGroup, super.key, this.onRemove, this.canRemove = true});
  final FilterGroup filterGroup;
  final VoidCallback? onRemove;
  final bool canRemove;

  @override
  State<FilterGroupCard> createState() => _FilterGroupCardState();
}

class _FilterGroupCardState extends State<FilterGroupCard> with SingleTickerProviderStateMixin {
  bool _isExpanded = true;
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 200), vsync: this);
    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 0.5,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    if (_isExpanded) _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? theme.cardColor.withOpacity(0.5) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: widget.filterGroup.hasActiveFilters
              ? theme.primaryColor.withOpacity(0.3)
              : theme.dividerColor.withOpacity(0.5),
          width: widget.filterGroup.hasActiveFilters ? 1.5 : 1,
        ),
        boxShadow: [
          if (widget.filterGroup.hasActiveFilters)
            BoxShadow(color: theme.primaryColor.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 1)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Modern Header
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() => _isExpanded = !_isExpanded);
                _isExpanded ? _controller.forward() : _controller.reverse();
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  gradient: widget.filterGroup.hasActiveFilters
                      ? LinearGradient(
                          colors: [theme.primaryColor.withOpacity(0.08), theme.primaryColor.withOpacity(0.03)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(widget.filterGroup.icon, size: 14, color: theme.primaryColor),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.filterGroup.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ),
                    if (widget.filterGroup.hasActiveFilters)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: theme.primaryColor,
                          borderRadius: BorderRadius.circular(5),
                          boxShadow: [
                            BoxShadow(
                              color: theme.primaryColor.withOpacity(0.3),
                              blurRadius: 2,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: const Text(
                          'Active',
                          style: TextStyle(
                            fontSize: 8,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    const SizedBox(width: 6),
                    if (widget.canRemove && widget.onRemove != null)
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: widget.onRemove,
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            child: Icon(Icons.close_rounded, size: 14, color: theme.hintColor),
                          ),
                        ),
                      ),
                    const SizedBox(width: 4),
                    RotationTransition(
                      turns: _rotationAnimation,
                      child: Icon(Icons.expand_more_rounded, size: 18, color: theme.hintColor),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Animated Content
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: _isExpanded
                ? Container(
                    padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
                    decoration: BoxDecoration(
                      color: isDark ? null : theme.primaryColor.withOpacity(0.01),
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10)),
                    ),
                    child: widget.filterGroup.buildContent(context),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
