import 'package:flutter/material.dart';

import '../config.dart';
import '../types.dart';

/// Layout template handles the overall structure and presentation
class CalendarLayoutTemplate extends StatefulWidget {
  const CalendarLayoutTemplate({
    required this.config,
    required this.currentSelection,
    required this.onSelectionChanged,
    required this.child,
    super.key,
    this.customHeader,
    this.customFooter,
  });

  final LayoutConfig config;
  final DateSelection currentSelection;
  final Function(DateSelection) onSelectionChanged;
  final Widget child;
  final Widget? customHeader;
  final Widget? customFooter;

  @override
  State<CalendarLayoutTemplate> createState() => _CalendarLayoutTemplateState();
}

class _CalendarLayoutTemplateState extends State<CalendarLayoutTemplate> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  bool _isExpanded = true;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.config.initiallyExpanded;
    _animationController = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);
    _expandAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeInOut);

    if (_isExpanded) {
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  void _clearSelection() {
    // Clear selection by setting empty DateSelection
    const selection = DateSelection(
      startDate: null,
      endDate: null,
      description: 'All Time',
      filterType: DateFilterMode.quick,
    );
    widget.onSelectionChanged(selection);
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.config.templateType) {
      case CalendarTemplateType.minimal:
        return _buildMinimalLayout();
      case CalendarTemplateType.compact:
        return _buildCompactLayout();
      case CalendarTemplateType.full:
        return _buildFullLayout();
      case CalendarTemplateType.dashboard:
        return _buildDashboardLayout();
      case CalendarTemplateType.adaptive:
        return _buildAdaptiveLayout();
    }
  }

  Widget _buildMinimalLayout() => Padding(padding: const EdgeInsets.all(4.0), child: widget.child);

  Widget _buildCompactLayout() => Card(
    elevation: widget.config.cardElevation,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(widget.config.borderRadius)),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.config.showHeader) _buildCompactHeader(),
        widget.child,
        if (widget.customFooter != null) widget.customFooter!,
      ],
    ),
  );

  Widget _buildFullLayout() => Card(
    elevation: widget.config.cardElevation,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(widget.config.borderRadius)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.config.showHeader) _buildFullHeader(),
        if (widget.config.collapsible)
          SizeTransition(sizeFactor: _expandAnimation, child: widget.child)
        else
          widget.child,
        if (widget.customFooter != null) widget.customFooter!,
      ],
    ),
  );

  Widget _buildDashboardLayout() => Container(
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(widget.config.borderRadius),
      border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.2)),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [if (widget.config.showHeader) _buildDashboardHeader(), widget.child],
    ),
  );

  Widget _buildAdaptiveLayout() {
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth < 600) {
      return _buildCompactLayout();
    } else if (screenWidth < 900) {
      return _buildFullLayout();
    } else {
      return _buildDashboardLayout();
    }
  }

  Widget _buildCompactHeader() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.vertical(top: Radius.circular(widget.config.borderRadius)),
    ),
    child: Row(
      children: [
        Icon(Icons.filter_list, size: 18, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        if (widget.config.headerTitle != null) ...[
          Text(
            widget.config.headerTitle!,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 8),
        ],
        Expanded(child: _buildSelectionDisplay(compact: true)),
        if (widget.config.showClearButton && widget.currentSelection.hasDateRange) _buildClearButton(size: 16),
      ],
    ),
  );

  Widget _buildFullHeader() => Container(
    padding: const EdgeInsets.all(16.0),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.vertical(top: Radius.circular(widget.config.borderRadius)),
      border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.date_range, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            if (widget.config.headerTitle != null)
              Text(
                widget.config.headerTitle!,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            const Spacer(),
            if (widget.config.collapsible)
              IconButton(
                icon: AnimatedRotation(
                  turns: _isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 300),
                  child: const Icon(Icons.expand_more),
                ),
                onPressed: _toggleExpanded,
              ),
            if (widget.config.showClearButton && widget.currentSelection.hasDateRange) _buildClearButton(),
          ],
        ),
        const SizedBox(height: 12),
        _buildSelectionDisplay(),
      ],
    ),
  );

  Widget _buildDashboardHeader() => Padding(
    padding: const EdgeInsets.all(12.0),
    child: Row(
      children: [
        Icon(Icons.schedule, size: 16, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 6),
        Expanded(child: _buildSelectionDisplay(compact: true)),
        if (widget.config.showClearButton && widget.currentSelection.hasDateRange) _buildClearButton(size: 14),
      ],
    ),
  );

  Widget _buildSelectionDisplay({bool compact = false}) => Container(
    padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 8, vertical: compact ? 2 : 4),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
      borderRadius: BorderRadius.circular(compact ? 4 : 6),
      border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.2)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.calendar_today, size: compact ? 12 : 14, color: Theme.of(context).colorScheme.primary),
        SizedBox(width: compact ? 4 : 6),
        Flexible(
          child: Text(
            widget.currentSelection.description,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.primary,
              fontSize: compact ? 11 : null,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );

  Widget _buildClearButton({double? size}) => IconButton(
    icon: Icon(Icons.clear, size: size ?? 18),
    onPressed: _clearSelection,
    tooltip: 'Clear Filter',
    padding: const EdgeInsets.all(4),
    constraints: BoxConstraints(minWidth: (size ?? 18) + 16, minHeight: (size ?? 18) + 16),
  );
}
