import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:am_design_system/core/theme/app_spacing.dart';
import 'package:am_design_system/core/theme/app_text_styles.dart';
import 'package:am_design_system/core/theme/color_extensions.dart';
import 'package:am_design_system/core/utils/validators.dart';

import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';

class EmailLoginFormWidget extends StatefulWidget {
  const EmailLoginFormWidget({
    super.key,
    this.isCompact = false,
    this.isLoading = false,
    this.showTitle = true,
  });

  final bool isCompact;
  final bool isLoading;
  final bool showTitle;

  @override
  State<EmailLoginFormWidget> createState() => _EmailLoginFormWidgetState();
}

class _EmailLoginFormWidgetState extends State<EmailLoginFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isHoveringBtn = false;
  bool _rememberMe = true;

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
    final primary = context.colors.actionPrimaryBg;

    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is Authenticated && kIsWeb) {
          TextInput.finishAutofillContext(shouldSave: true);
        }
      },
      child: Form(
        key: _formKey,
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.showTitle) ...[
                Text(
                  'Sign in to your account',
                  style: context.text
                      .pageTitle(compact: widget.isCompact)
                      .copyWith(color: context.colors.textPrimary),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Choose a sign in method and continue.',
                  style: context.text
                      .bodyMuted(compact: widget.isCompact)
                      .copyWith(color: context.colors.textSecondary),
                ),
                SizedBox(
                  height: widget.isCompact ? AppSpacing.md : AppSpacing.md + 4,
                ),
              ],
              LiquidTextField(
                controller: _emailController,
                enabled: !widget.isLoading,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email, AutofillHints.username],
                labelText: 'Email address',
                hintText: 'Enter your email',
                prefixIcon: Icons.email_outlined,
                validator: (value) => Validators.validateEmail(value),
              ),
              const SizedBox(height: 16),
              LiquidTextField(
                controller: _passwordController,
                enabled: !widget.isLoading,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                onFieldSubmitted: (_) => _handleLogin(),
                labelText: 'Password',
                hintText: 'Enter your password',
                prefixIcon: Icons.lock_outline,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: context.colors.textSecondary,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Password is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  SizedBox(
                    height: 24,
                    width: 24,
                    child: Checkbox(
                      value: _rememberMe,
                      activeColor: primary,
                      onChanged: widget.isLoading
                          ? null
                          : (value) =>
                              setState(() => _rememberMe = value ?? false),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Remember Me',
                      style: TextStyle(
                        fontSize: widget.isCompact ? 12 : 13,
                        color: context.colors.textSecondary,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: widget.isLoading
                        ? null
                        : () => context.push('/forgot-password'),
                    style: TextButton.styleFrom(
                      foregroundColor: primary,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Forgot Password?',
                      style: TextStyle(
                        fontSize: widget.isCompact ? 12 : 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              MouseRegion(
                onEnter: (_) => setState(() => _isHoveringBtn = true),
                onExit: (_) => setState(() => _isHoveringBtn = false),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  curve: Curves.easeOutQuad,
                  transform:
                      Matrix4.translationValues(0, _isHoveringBtn ? -2 : 0, 0),
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 1.2,
                    ),
                    gradient: LinearGradient(
                      colors: [
                        primary.withValues(alpha: 0.95),
                        primary.withValues(alpha: 0.85),
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
                      elevation: 0,
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
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
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
            ],
          ),
        ),
      ),
    );
  }
}

class LiquidTextField extends StatefulWidget {
  const LiquidTextField({
    super.key,
    required this.controller,
    this.enabled = true,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction,
    this.autofillHints = const [],
    this.onFieldSubmitted,
    required this.labelText,
    required this.hintText,
    required this.prefixIcon,
    this.suffixIcon,
    this.validator,
  });

  final TextEditingController controller;
  final bool enabled;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String> autofillHints;
  final ValueChanged<String>? onFieldSubmitted;
  final String labelText;
  final String hintText;
  final IconData prefixIcon;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

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

    final baseBgColor = isDark
        ? Colors.white.withValues(alpha: (_isHovering || _isFocused) ? 0.17 : 0.12)
        : Colors.white.withValues(alpha: (_isHovering || _isFocused) ? 0.15 : 0.05);

    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.35)
        : Colors.white.withValues(alpha: 0.45);

    final textColor = context.colors.textPrimary;
    final labelColor = context.colors.textSecondary;
    final hintColor = context.colors.textTertiary;
    final iconColor = context.colors.textSecondary;

    final outlineBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: borderColor, width: 1.2),
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: baseBgColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: TextFormField(
          controller: widget.controller,
          enabled: widget.enabled,
          obscureText: widget.obscureText,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          autofillHints: widget.autofillHints,
          onFieldSubmitted: widget.onFieldSubmitted,
          focusNode: _focusNode,
          enableSuggestions: !widget.obscureText,
          autocorrect: false,
          style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            filled: false,
            labelText: widget.labelText,
            labelStyle: TextStyle(color: labelColor, fontSize: 13),
            floatingLabelBehavior: FloatingLabelBehavior.auto,
            floatingLabelStyle: TextStyle(
              color: labelColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            hintText: widget.hintText,
            hintStyle: TextStyle(color: hintColor, fontSize: 13),
            prefixIcon: Icon(widget.prefixIcon, color: iconColor, size: 20),
            suffixIcon: widget.suffixIcon,
            border: outlineBorder,
            enabledBorder: outlineBorder,
            focusedBorder: outlineBorder,
            disabledBorder: outlineBorder,
            errorBorder: outlineBorder.copyWith(
              borderSide: BorderSide(
                color: context.colors.statusError,
                width: 1.2,
              ),
            ),
            focusedErrorBorder: outlineBorder.copyWith(
              borderSide: BorderSide(
                color: context.colors.statusError,
                width: 1.2,
              ),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            errorStyle: TextStyle(color: context.colors.statusError),
          ),
          validator: widget.validator,
        ),
      ),
    );
  }
}
