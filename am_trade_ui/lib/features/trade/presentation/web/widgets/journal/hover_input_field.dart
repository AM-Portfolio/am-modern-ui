import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';

/// Hover input field with purple border effect
class HoverInputField extends StatefulWidget {
  const HoverInputField({required this.child, super.key});

  final Widget child;

  @override
  State<HoverInputField> createState() => _HoverInputFieldState();
}

class _HoverInputFieldState extends State<HoverInputField> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          border: Border.all(
            color: _isHovered
                ? ModuleColors.trade // Purple color
                : theme.dividerColor.withOpacity(0.5),
            width: _isHovered ? 2.0 : 1.0,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: widget.child,
      ),
    );
  }
}
