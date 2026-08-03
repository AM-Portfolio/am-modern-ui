import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/auth_cubit.dart';
import 'package:am_design_system/core/utils/validators.dart';

/// Email login form widget
class EmailLoginFormWidget extends StatefulWidget {
  final bool isCompact;
  final bool isLoading;

  const EmailLoginFormWidget({
    super.key,
    this.isCompact = false,
    this.isLoading = false,
  });

  @override
  State<EmailLoginFormWidget> createState() => _EmailLoginFormWidgetState();
}

class _EmailLoginFormWidgetState extends State<EmailLoginFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isHoveringBtn = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthCubit>().loginWithEmail(
            _emailController.text.trim(),
            _passwordController.text,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Email field
          LiquidTextField(
            controller: _emailController,
            enabled: !widget.isLoading,
            keyboardType: TextInputType.emailAddress,
            labelText: 'Email',
            hintText: 'Enter your email',
            prefixIcon: Icons.email_outlined,
            validator: (value) => Validators.validateEmail(value),
          ),
          const SizedBox(height: 20),

          // Password field
          LiquidTextField(
            controller: _passwordController,
            enabled: !widget.isLoading,
            obscureText: _obscurePassword,
            labelText: 'Password',
            hintText: 'Enter your password',
            prefixIcon: Icons.lock_outline,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white70
                    : const Color(0xFF475569),
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Password is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 32),

          // Login button
          MouseRegion(
            onEnter: (_) => setState(() => _isHoveringBtn = true),
            onExit: (_) => setState(() => _isHoveringBtn = false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOutQuad,
              transform: Matrix4.translationValues(0, _isHoveringBtn ? -2 : 0, 0),
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withValues(alpha: _isHoveringBtn ? 0.35 : 0.20),
                    blurRadius: _isHoveringBtn ? 25 : 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1.2,
                      ),
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF6366F1).withValues(alpha: 0.75),
                          const Color(0xFF7C3AED).withValues(alpha: 0.65)
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                    child: ElevatedButton(
                      onPressed: widget.isLoading ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: widget.isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Sign In',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
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
}

class LiquidTextField extends StatefulWidget {
  final TextEditingController controller;
  final bool enabled;
  final bool obscureText;
  final TextInputType keyboardType;
  final String labelText;
  final String hintText;
  final IconData prefixIcon;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  const LiquidTextField({
    super.key,
    required this.controller,
    this.enabled = true,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    required this.labelText,
    required this.hintText,
    required this.prefixIcon,
    this.suffixIcon,
    this.validator,
  });

  @override
  State<LiquidTextField> createState() => _LiquidTextFieldState();
}

class _LiquidTextFieldState extends State<LiquidTextField> {
  bool _isHovering = false;
  bool _isFocused = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    
    // Liquid glass background
    final baseBgColor = isDark
        ? Colors.white.withValues(alpha: (_isHovering || _isFocused) ? 0.17 : 0.12)
        : Colors.white.withValues(alpha: (_isHovering || _isFocused) ? 0.15 : 0.05); // Make it highly transparent in light mode

    final borderColor = _isFocused
        ? primaryColor.withValues(alpha: 0.7)
        : (isDark
            ? Colors.white.withValues(alpha: 0.35)
            : Colors.white.withValues(alpha: 0.45)); // Make border more visible in light mode for glass effect

    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final labelColor = isDark ? Colors.white.withValues(alpha: 0.8) : const Color(0xFF475569);
    final hintColor = isDark ? Colors.white.withValues(alpha: 0.5) : const Color(0xFF64748B);
    final iconColor = isDark ? Colors.white70 : const Color(0xFF334155);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                if (_isFocused)
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.3),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: baseBgColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: borderColor,
                      width: 1.2,
                    ),
                  ),
                  child: TextFormField(
                    controller: widget.controller,
                    enabled: widget.enabled,
                    obscureText: widget.obscureText,
                    keyboardType: widget.keyboardType,
                    focusNode: _focusNode,
                    style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      filled: false,
                      labelText: widget.labelText,
                      labelStyle: TextStyle(color: labelColor, fontSize: 13),
                      hintText: widget.hintText,
                      hintStyle: TextStyle(color: hintColor, fontSize: 13),
                      prefixIcon: Icon(widget.prefixIcon, color: iconColor, size: 20),
                      suffixIcon: widget.suffixIcon,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      errorStyle: const TextStyle(color: Color(0xFFFF6B6B)),
                    ),
                    validator: widget.validator,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
