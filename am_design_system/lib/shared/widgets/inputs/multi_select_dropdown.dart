import 'package:flutter/material.dart';
import 'dropdown_styles.dart';

/// Reusable multi-select dropdown widget with consistent styling
class MultiSelectDropdown<T> extends StatefulWidget {
  const MultiSelectDropdown({
    required this.label,
    required this.selectedValues,
    required this.allValues,
    required this.formatter,
    required this.onChanged,
    super.key,
    this.height = DropdownStyles.defaultHeight,
    this.fontSize = DropdownStyles.defaultFontSize,
    this.iconSize = DropdownStyles.defaultIconSize,
    this.borderRadius = DropdownStyles.defaultBorderRadius,
    this.contentPadding = DropdownStyles.defaultContentPadding,
    this.primaryColor,
    this.backgroundColor,
    this.borderColor,
  });

  final String label;
  final List<T> selectedValues;
  final List<T> allValues;
  final String Function(T) formatter;
  final Function(List<T>) onChanged;
  final double height;
  final double fontSize;
  final double iconSize;
  final double borderRadius;
  final EdgeInsets contentPadding;
  final Color? primaryColor;
  final Color? backgroundColor;
  final Color? borderColor;

  @override
  State<MultiSelectDropdown<T>> createState() => _MultiSelectDropdownState<T>();
}

class _MultiSelectDropdownState<T> extends State<MultiSelectDropdown<T>> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;
  bool _isDisposing = false;
  late List<T> _tempSelected;

  @override
  void initState() {
    super.initState();
    _tempSelected = List<T>.from(widget.selectedValues);
  }

  @override
  void didUpdateWidget(MultiSelectDropdown<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isOpen) {
      _tempSelected = List<T>.from(widget.selectedValues);
    }
  }

  void _toggleDropdown() {
    if (_isOpen) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  void _openDropdown() {
    _tempSelected = List<T>.from(widget.selectedValues);
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _isOpen = true);
  }

  void _closeDropdown({bool applyChanges = true}) {
    // Apply selections when closing (unless we're disposing)
    if (applyChanges && !_isDisposing) {
      widget.onChanged(_tempSelected);
    }
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (!_isDisposing && mounted) {
      setState(() => _isOpen = false);
    } else {
      _isOpen = false;
    }
  }

  OverlayEntry _createOverlayEntry() {
    final renderBox = context.findRenderObject()! as RenderBox;
    final size = renderBox.size;

    return OverlayEntry(
      builder: (context) => StatefulBuilder(
        builder: (context, setOverlayState) => Stack(
          children: [
            _buildBackgroundDismiss(),
            _buildDropdownContent(size, setOverlayState),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundDismiss() => Positioned.fill(
    child: GestureDetector(
      onTap: _closeDropdown,
      behavior: HitTestBehavior.translucent,
    ),
  );

  Widget _buildDropdownContent(Size size, StateSetter setOverlayState) =>
      Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, size.height + 4),
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(4),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 250),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(4),
                color: Theme.of(context).scaffoldBackgroundColor,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDropdownHeader(setOverlayState),
                  _buildOptionsList(setOverlayState),
                ],
              ),
            ),
          ),
        ),
      );

  Widget _buildDropdownHeader(StateSetter setOverlayState) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.grey.shade100,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          widget.label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        _buildHeaderActions(setOverlayState),
      ],
    ),
  );

  Widget _buildHeaderActions(StateSetter setOverlayState) {
    if (_tempSelected.isEmpty) {
      return const SizedBox.shrink();
    }

    return TextButton(
      onPressed: () => setOverlayState(() => _tempSelected.clear()),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        minimumSize: const Size(0, 24),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: const Text('Clear', style: TextStyle(fontSize: 11)),
    );
  }

  Widget _buildOptionsList(StateSetter setOverlayState) => Flexible(
    child: ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: 4),
      children: widget.allValues
          .map((value) => _buildOptionItem(value, setOverlayState))
          .toList(),
    ),
  );

  Widget _buildOptionItem(T value, StateSetter setOverlayState) {
    final isSelected = _tempSelected.contains(value);
    return CheckboxListTile(
      title: Text(
        widget.formatter(value),
        style: const TextStyle(fontSize: 12),
      ),
      value: isSelected,
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      visualDensity: VisualDensity.compact,
      onChanged: (checked) {
        setOverlayState(() {
          if (checked == true) {
            _tempSelected.add(value);
          } else {
            _tempSelected.remove(value);
          }
        });
      },
    );
  }

  @override
  void dispose() {
    _isDisposing = true;
    _closeDropdown(applyChanges: false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tooltipMessage = _buildTooltipMessage();

    return CompositedTransformTarget(
      link: _layerLink,
      child: Tooltip(
        message: tooltipMessage,
        preferBelow: false,
        waitDuration: const Duration(milliseconds: 500),
        child: InkWell(
          onTap: _toggleDropdown,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: Container(
            height: widget.height,
            padding: widget.contentPadding,
            decoration: DropdownStyles.createDecoration(
              context,
              primaryColor: widget.primaryColor,
              backgroundColor: widget.backgroundColor,
              borderColor: widget.borderColor,
              borderRadius: widget.borderRadius,
            ),
            child: Row(
              children: [
                Expanded(child: _buildDisplayText()),
                const SizedBox(width: 8),
                _buildSuffixIcon(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _buildTooltipMessage() {
    if (widget.selectedValues.isEmpty) {
      return 'No items selected';
    }
    if (widget.selectedValues.length == 1) {
      return widget.formatter(widget.selectedValues.first);
    }
    // Show all selected values separated by commas
    return widget.selectedValues.map(widget.formatter).join(', ');
  }

  Widget _buildSuffixIcon() {
    final iconColor = DropdownStyles.getIconColor(
      context,
      primaryColor: widget.primaryColor,
    );

    if (widget.selectedValues.isNotEmpty) {
      return InkWell(
        onTap: () {
          widget.onChanged([]);
          if (_isOpen) _closeDropdown(applyChanges: false);
        },
        child: Icon(Icons.clear, size: widget.iconSize, color: iconColor),
      );
    }
    return Icon(
      _isOpen ? Icons.expand_less : Icons.expand_more,
      size: widget.iconSize,
      color: iconColor,
    );
  }

  Widget _buildDisplayText() {
    final String displayText;
    final bool isPlaceholder;

    if (widget.selectedValues.isEmpty) {
      displayText = widget.label;
      isPlaceholder = true;
    } else if (widget.selectedValues.length == 1) {
      displayText = widget.formatter(widget.selectedValues.first);
      isPlaceholder = false;
    } else {
      displayText = '${widget.selectedValues.length} selected';
      isPlaceholder = false;
    }

    return Text(
      displayText,
      style: DropdownStyles.createTextStyle(
        context,
        primaryColor: widget.primaryColor,
        fontSize: widget.fontSize,
        isPlaceholder: isPlaceholder,
      ),
      overflow: TextOverflow.ellipsis,
    );
  }
}
