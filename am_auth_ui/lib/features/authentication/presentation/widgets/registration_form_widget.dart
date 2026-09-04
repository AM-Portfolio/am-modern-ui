import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:am_design_system/core/theme/color_extensions.dart';
import 'package:am_design_system/core/utils/validators.dart';

import '../cubit/auth_cubit.dart';
import 'auth_primary_button.dart';
import 'email_login_form_widget.dart';

/// Modern registration fields matching login LiquidTextField chrome.
class RegistrationFormWidget extends StatefulWidget {
  const RegistrationFormWidget({
    super.key,
    this.isCompact = false,
    this.isLoading = false,
  });

  final bool isCompact;
  final bool isLoading;

  @override
  State<RegistrationFormWidget> createState() => _RegistrationFormWidgetState();
}

class _RegistrationFormWidgetState extends State<RegistrationFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _handleRegister() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthCubit>().register(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text,
            confirmPassword: _confirmPasswordController.text,
            phone: _phoneController.text.trim().isNotEmpty
                ? _phoneController.text.trim()
                : null,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final gap = widget.isCompact ? 12.0 : 16.0;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LiquidTextField(
            controller: _nameController,
            enabled: !widget.isLoading,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.name],
            labelText: 'Full name',
            hintText: 'Enter your full name',
            prefixIcon: Icons.person_outline,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your full name';
              }
              return null;
            },
          ),
          SizedBox(height: gap),
          LiquidTextField(
            controller: _emailController,
            enabled: !widget.isLoading,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            labelText: 'Email address',
            hintText: 'Enter your email',
            prefixIcon: Icons.email_outlined,
            validator: Validators.validateEmail,
          ),
          SizedBox(height: gap),
          LiquidTextField(
            controller: _phoneController,
            enabled: !widget.isLoading,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.telephoneNumber],
            labelText: 'Phone number',
            hintText: 'Optional',
            prefixIcon: Icons.phone_outlined,
            validator: Validators.validatePhone,
          ),
          SizedBox(height: gap),
          LiquidTextField(
            controller: _passwordController,
            enabled: !widget.isLoading,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.newPassword],
            labelText: 'Password',
            hintText: 'Create a password',
            prefixIcon: Icons.lock_outline,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: context.colors.textSecondary,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
            validator: Validators.validatePassword,
          ),
          SizedBox(height: gap),
          LiquidTextField(
            controller: _confirmPasswordController,
            enabled: !widget.isLoading,
            obscureText: _obscureConfirmPassword,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.newPassword],
            onFieldSubmitted: (_) => _handleRegister(),
            labelText: 'Confirm password',
            hintText: 'Re-enter your password',
            prefixIcon: Icons.lock_outline,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword
                    ? Icons.visibility_off
                    : Icons.visibility,
                color: context.colors.textSecondary,
              ),
              onPressed: () => setState(
                () => _obscureConfirmPassword = !_obscureConfirmPassword,
              ),
            ),
            validator: (value) => Validators.validatePasswordMatch(
              value,
              _passwordController.text,
            ),
          ),
          SizedBox(height: widget.isCompact ? 16 : 20),
          AuthPrimaryButton(
            label: 'Create Account',
            loading: widget.isLoading,
            onPressed: _handleRegister,
          ),
        ],
      ),
    );
  }
}
