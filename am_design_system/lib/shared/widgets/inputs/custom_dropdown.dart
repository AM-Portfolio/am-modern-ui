import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dropdown_styles.dart';
import '../../../core/theme/app_glassmorphism.dart';


/// A customizable dropdown widget that provides consistent styling and behavior
/// across the application. Supports icons, hints, and custom styling.
class CustomDropdown<T> extends StatefulWidget {
  const CustomDropdown({
    required this.items,
    required this.onChanged,
    this.value,
    super.key,
    this.hint,
    this.label,
    this.icon,
    this.primaryColor,
    this.height = 40,
    this.isExpanded = true,
    this.fontSize = 14,
    this.iconSize = 18,
    this.borderRadius = 12,
    this.contentPadding = const EdgeInsets.symmetric(horizontal: 12),
    this.backgroundColor,
    this.borderColor,
    this.textColor,
    this.enabled = true,
    this.enableGlass = false,
    this.menuMaxHeight = 300,
  });

  /// Current selected value
  final T? value;

  /// List of dropdown items
  final List<DropdownMenuItem<T>> items;

  /// Callback when value changes
  final ValueChanged<T?>? onChanged;

  /// Hint text when no value is selected
  final String? hint;

  /// Label for the dropdown
  final String? label;

  /// Icon to show at the end of dropdown
  final IconData? icon;

  /// Primary color for styling
  final Color? primaryColor;

  /// Height of the dropdown container
  final double height;

  /// Whether dropdown should expand to fill available width
  final bool isExpanded;

  /// Font size for text
  final double fontSize;

  /// Size of the dropdown icon
  final double iconSize;

  /// Border radius for the container
  final double borderRadius;

  /// Padding inside the container
  final EdgeInsets contentPadding;

  /// Background color override
  final Color? backgroundColor;

  /// Border color override
  final Color? borderColor;

  /// Text color override
  final Color? textColor;

  /// Whether the dropdown is enabled
  final bool enabled;

  /// Whether to use glassmorphic styling
  final bool enableGlass;

  /// Max height of the open menu; remaining options scroll.
  final double menuMaxHeight;

  @override
  State<CustomDropdown<T>> createState() => _CustomDropdownState<T>();
}

class _CustomDropdownState<T> extends State<CustomDropdown<T>> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;

  void _toggleDropdown() {
    if (!widget.enabled) return;
    if (_isOpen) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  void _openDropdown() {
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _isOpen = true);
  }

  void _closeDropdown() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) {
      setState(() => _isOpen = false);
    }
  }

  OverlayEntry _createOverlayEntry() {
    final renderBox = context.findRenderObject()! as RenderBox;
    final size = renderBox.size;
    final theme = Theme.of(context);

    return OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: _closeDropdown,
              behavior: HitTestBehavior.translucent,
            ),
          ),
          Positioned(
            width: widget.isExpanded ? size.width : null,
            child: CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: Offset(0, size.height + 4),
              child: Material(
                elevation: widget.enableGlass ? 0 : 8,
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(widget.borderRadius),
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: widget.menuMaxHeight,
                    minWidth: widget.isExpanded ? size.width : math.max(size.width, 160.0),
                  ),
                  decoration: widget.enableGlass
                      ? AppGlassmorphism.dropdownDecoration(context).copyWith(
                          borderRadius: BorderRadius.circular(widget.borderRadius),
                        )
                      : BoxDecoration(
                          color: widget.backgroundColor ?? theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(widget.borderRadius),
                          border: Border.all(
                            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 24,
                              spreadRadius: 2,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(widget.borderRadius),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(8),
                      child: IntrinsicWidth(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: widget.items.map((item) {
                            final isSelected = item.value == widget.value;
                            return InkWell(
                              onTap: () {
                                widget.onChanged?.call(item.value);
                                _closeDropdown();
                              },
                              hoverColor: Colors.transparent,
                              splashColor: Colors.transparent,
                              highlightColor: Colors.transparent,
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: _HoverableDropdownItemChild(
                                  isSelected: isSelected,
                                  child: DefaultTextStyle(
                                    style: DropdownStyles.createTextStyle(
                                      context,
                                      primaryColor: widget.primaryColor,
                                      textColor: widget.textColor,
                                      fontSize: widget.fontSize,
                                      enabled: true,
                                    ).copyWith(
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                    ),
                                    child: Stack(
                                      alignment: Alignment.centerLeft,
                                      children: [
                                        item.child,
                                        if (isSelected)
                                          Positioned(
                                            right: 12,
                                            child: Icon(
                                              Icons.check_circle_rounded, 
                                              size: 16, 
                                              color: widget.primaryColor ?? theme.primaryColor,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    if (_isOpen) {
      _overlayEntry?.remove();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectivePrimaryColor = widget.primaryColor ?? theme.primaryColor;

    Widget? displayWidget;
    if (widget.value != null) {
      final selectedItem = widget.items.cast<DropdownMenuItem<T>?>().firstWhere(
        (item) => item?.value == widget.value,
        orElse: () => null,
      );
      if (selectedItem != null) {
        displayWidget = selectedItem.child;
      }
    }

    if (displayWidget == null && widget.hint != null) {
      displayWidget = Text(
        widget.hint!,
        style: DropdownStyles.createTextStyle(
          context,
          primaryColor: effectivePrimaryColor,
          fontSize: widget.fontSize,
          isPlaceholder: true,
          enabled: widget.enabled,
        ),
      );
    }

    Widget dropdownBody = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (displayWidget != null)
          widget.isExpanded ? Expanded(child: displayWidget) : displayWidget,
        Icon(
          widget.icon ?? (_isOpen ? Icons.expand_less : Icons.expand_more),
          color: DropdownStyles.getIconColor(
            context,
            primaryColor: effectivePrimaryColor,
            enabled: widget.enabled,
          ),
          size: widget.iconSize,
        ),
      ],
    );

    Widget container;
    if (widget.enableGlass) {
      container = Container(
        height: widget.height,
        decoration: AppGlassmorphism.dropdownDecoration(context),
        padding: widget.contentPadding,
        child: dropdownBody,
      );
    } else {
      container = Container(
        height: widget.height,
        padding: widget.contentPadding,
        decoration: DropdownStyles.createDecoration(
          context,
          primaryColor: effectivePrimaryColor,
          backgroundColor: widget.backgroundColor,
          borderColor: widget.borderColor,
          borderRadius: widget.borderRadius,
          enabled: widget.enabled,
        ),
        child: dropdownBody,
      );
    }

    return CompositedTransformTarget(
      link: _layerLink,
      child: MouseRegion(
        cursor: widget.enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: GestureDetector(
          onTap: _toggleDropdown,
          behavior: HitTestBehavior.opaque,
          child: container,
        ),
      ),
    );
  }
}

/// Extension to help create dropdown items with consistent styling
extension DropdownItemHelper<T> on T {
  /// Creates a dropdown item with icon and text
  DropdownMenuItem<T> toDropdownItem({
    required String text,
    IconData? icon,
    Color? iconColor,
    double iconSize = 16,
    double fontSize = 14,
    bool expandText = true,
  }) => DropdownMenuItem<T>(
    value: this,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: iconSize, color: iconColor),
          const SizedBox(width: 8),
        ],
        if (expandText)
          Flexible(
            child: Text(
              text,
              style: TextStyle(fontSize: fontSize),
              overflow: TextOverflow.ellipsis,
            ),
          )
        else
          Text(text, style: TextStyle(fontSize: fontSize)),
      ],
    ),
  );

  /// Creates a simple dropdown item with just text
  DropdownMenuItem<T> toSimpleDropdownItem({
    required String text,
    double fontSize = 14,
  }) => DropdownMenuItem<T>(
    value: this,
    child: Text(text, style: TextStyle(fontSize: fontSize)),
  );
}

class _HoverableDropdownItemChild extends StatefulWidget {
  final Widget child;
  final bool isSelected;

  const _HoverableDropdownItemChild({required this.child, this.isSelected = false});

  @override
  State<_HoverableDropdownItemChild> createState() => _HoverableDropdownItemChildState();
}

class _HoverableDropdownItemChildState extends State<_HoverableDropdownItemChild> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        // Use padding to shift content instead of transform to avoid overflow clipping
        padding: EdgeInsets.only(
          left: _isHovered ? 12.0 : 8.0, 
          right: _isHovered ? 4.0 : 8.0, 
          top: 10.0, 
          bottom: 10.0
        ),
        decoration: BoxDecoration(
          color: _isHovered 
              ? theme.primaryColor.withValues(alpha: 0.15) 
              : (widget.isSelected ? theme.primaryColor.withValues(alpha: 0.05) : Colors.transparent),
          borderRadius: BorderRadius.circular(8),
        ),
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          style: TextStyle(
            color: _isHovered ? theme.primaryColor : theme.colorScheme.onSurface,
            fontWeight: _isHovered ? FontWeight.w600 : FontWeight.w500,
          ),
          child: IconTheme(
            data: IconThemeData(
              color: _isHovered ? theme.primaryColor : theme.iconTheme.color,
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
