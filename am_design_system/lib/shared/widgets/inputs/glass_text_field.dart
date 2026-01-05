
import 'package:flutter/material.dart';
import 'package:am_design_system/core/config/design_system_provider.dart';
import 'package:am_design_system/core/utils/conditional_mouse_region.dart';



/// A premium text field with glassmorphic styling, hover effects, and animations.
class GlassTextField extends StatefulWidget {
  const GlassTextField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.prefixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.onFieldSubmitted,
    this.textInputAction,
    this.suffixIcon,
  });

  final TextEditingController controller;
  final String hintText;
  final IconData prefixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onFieldSubmitted;
  final TextInputAction? textInputAction;
  final Widget? suffixIcon;

  @override
  State<GlassTextField> createState() => _GlassTextFieldState();
}

class _GlassTextFieldState extends State<GlassTextField> {
  bool _isHovering = false;
  bool _isFocused = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    final config = DesignSystemProvider.of(context);
    final primaryColor = config.primaryColor;
    final borderRadius = config.defaultRadius;

    return ConditionalMouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: _isFocused
              ? Colors.white.withValues(alpha: 0.95)
              : _isHovering
                  ? Colors.white.withValues(alpha: 0.85)
                  : Colors.white.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: _isFocused
                ? primaryColor
                : _isHovering
                    ? primaryColor.withValues(alpha: 0.5)
                    : Colors.transparent,
            width: _isFocused ? 2 : 1.5,
          ),
          boxShadow: [
            if (_isFocused || _isHovering)
              BoxShadow(
                color: primaryColor.withValues(alpha: 0.2),
                blurRadius: 15,
                spreadRadius: 2,
              )
          ],
        ),
        child: TextFormField(
          controller: widget.controller,
          focusNode: _focusNode,
          obscureText: widget.obscureText,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          onFieldSubmitted: widget.onFieldSubmitted,
          style: TextStyle(
            color: Colors.black87,
            fontWeight: _isFocused ? FontWeight.w600 : FontWeight.normal,
            fontSize: 16,
          ),
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: TextStyle(
              color: Colors.black54,
              fontWeight: FontWeight.normal,
            ),
            prefixIcon: Icon(
              widget.prefixIcon,
              color: _isFocused
                  ? primaryColor
                  : Colors.black54,
            ),
            suffixIcon: widget.suffixIcon,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
            errorStyle: const TextStyle(
              color: Colors.redAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
          validator: widget.validator,
        ),
      ),
    );
  }
}
