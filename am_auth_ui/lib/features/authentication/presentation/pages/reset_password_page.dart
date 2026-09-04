import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:am_design_system/core/theme/color_extensions.dart';
import 'package:am_design_system/core/utils/validators.dart';

import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import '../widgets/auth_flow_shell.dart';
import '../widgets/auth_primary_button.dart';
import '../widgets/email_login_form_widget.dart';

class ResetPasswordPage extends StatelessWidget {
  const ResetPasswordPage({super.key, this.resetToken, this.resetCode});

  final String? resetToken;
  final String? resetCode;

  @override
  Widget build(BuildContext context) {
    return AuthFlowShell(
      showBack: true,
      onBack: () => context.go('/login'),
      brandingTitle: 'Choose a new password',
      brandingSubtitle:
          'Set a strong password so you can get back into your account securely.',
      form: ResetPasswordPageForm(
        resetToken: resetToken,
        resetCode: resetCode,
      ),
    );
  }
}

class ResetPasswordPageForm extends StatefulWidget {
  const ResetPasswordPageForm({super.key, this.resetToken, this.resetCode});

  final String? resetToken;
  final String? resetCode;

  @override
  State<ResetPasswordPageForm> createState() => _ResetPasswordPageFormState();
}

class _ResetPasswordPageFormState extends State<ResetPasswordPageForm> {
  final _formKey = GlobalKey<FormState>();
  final _tokenController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  String? get _linkCode {
    final c = widget.resetCode?.trim();
    return (c != null && c.isNotEmpty) ? c : null;
  }

  String? get _linkToken {
    final t = widget.resetToken?.trim();
    return (t != null && t.isNotEmpty) ? t : null;
  }

  bool get _hasDeepLink => _linkCode != null || _linkToken != null;

  @override
  void initState() {
    super.initState();
    if (_linkToken != null && _linkCode == null) {
      _tokenController.text = _linkToken!;
    }
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthCubit>().resetPassword(
            resetToken: _linkCode == null ? _tokenController.text : null,
            resetCode: _linkCode,
            newPassword: _passwordController.text,
            confirmPassword: _confirmPasswordController.text,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 600;
    final primary = context.colors.actionPrimaryBg;
    final gap = isCompact ? 12.0 : 16.0;

    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is PasswordResetSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Password reset successfully. Please sign in with your new password.',
              ),
              backgroundColor: context.colors.statusSuccess,
            ),
          );
          context.go('/login');
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: context.colors.statusError,
            ),
          );
        }
      },
      builder: (context, state) {
        final loading = state is AuthLoading;

        return Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Reset password',
                style: TextStyle(
                  fontSize: isCompact ? 18 : 22,
                  fontWeight: FontWeight.w700,
                  color: context.colors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Enter a new password for your account.',
                style: TextStyle(
                  fontSize: isCompact ? 12 : 13,
                  color: context.colors.textSecondary,
                ),
              ),
              SizedBox(height: isCompact ? 16 : 20),
              if (!_hasDeepLink) ...[
                LiquidTextField(
                  controller: _tokenController,
                  enabled: !loading,
                  textInputAction: TextInputAction.next,
                  labelText: 'Reset token',
                  hintText: 'Paste your reset token',
                  prefixIcon: Icons.vpn_key_outlined,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Reset token is required';
                    }
                    return null;
                  },
                ),
                SizedBox(height: gap),
              ],
              LiquidTextField(
                controller: _passwordController,
                enabled: !loading,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newPassword],
                labelText: 'New password',
                hintText: 'Create a new password',
                prefixIcon: Icons.lock_outline,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off
                        : Icons.visibility,
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
                enabled: !loading,
                obscureText: _obscureConfirmPassword,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.newPassword],
                onFieldSubmitted: (_) => _handleSubmit(),
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
                    () =>
                        _obscureConfirmPassword = !_obscureConfirmPassword,
                  ),
                ),
                validator: (value) => Validators.validatePasswordMatch(
                  value,
                  _passwordController.text,
                ),
              ),
              SizedBox(height: isCompact ? 16 : 20),
              AuthPrimaryButton(
                label: 'Reset Password',
                loading: loading,
                onPressed: _handleSubmit,
              ),
              SizedBox(height: isCompact ? 12 : 16),
              TextButton(
                onPressed: loading ? null : () => context.go('/login'),
                style: TextButton.styleFrom(foregroundColor: primary),
                child: Text(
                  'Back to Sign In',
                  style: TextStyle(
                    fontSize: isCompact ? 12 : 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
