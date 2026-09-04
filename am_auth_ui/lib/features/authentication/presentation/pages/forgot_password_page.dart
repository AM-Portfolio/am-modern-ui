import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:am_design_system/core/constants/app_config.dart';
import 'package:am_design_system/core/theme/color_extensions.dart';
import 'package:am_design_system/core/utils/validators.dart';

import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import '../widgets/auth_flow_shell.dart';
import '../widgets/auth_primary_button.dart';
import '../widgets/email_login_form_widget.dart';

class ForgotPasswordPage extends StatelessWidget {
  const ForgotPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    final appName = AppConfig.getAppName();

    return AuthFlowShell(
      showBack: true,
      onBack: () => Navigator.of(context).pop(),
      brandingTitle: 'Reset access',
      brandingSubtitle:
          'We will email you a secure link to reset your $appName password.',
      form: ForgotPasswordForm(
        onLogin: () => Navigator.of(context).pop(),
      ),
    );
  }
}

class ForgotPasswordForm extends StatelessWidget {
  const ForgotPasswordForm({
    super.key,
    required this.onLogin,
  });

  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 600;
    final primary = context.colors.actionPrimaryBg;

    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is PasswordResetEmailSent) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Password reset instructions sent to your email',
              ),
              backgroundColor: context.colors.statusSuccess,
            ),
          );
          onLogin();
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

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Forgot password?',
              style: TextStyle(
                fontSize: isCompact ? 18 : 22,
                fontWeight: FontWeight.w700,
                color: context.colors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Enter your email and we will send reset instructions.',
              style: TextStyle(
                fontSize: isCompact ? 12 : 13,
                color: context.colors.textSecondary,
              ),
            ),
            SizedBox(height: isCompact ? 16 : 20),
            if (loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              _ForgotPasswordFormContent(isCompact: isCompact),
            SizedBox(height: isCompact ? 12 : 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Remember your password?',
                  style: TextStyle(
                    fontSize: isCompact ? 12 : 13,
                    color: context.colors.textSecondary,
                  ),
                ),
                TextButton(
                  onPressed: loading ? null : onLogin,
                  style: TextButton.styleFrom(
                    foregroundColor: primary,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Sign In',
                    style: TextStyle(
                      fontSize: isCompact ? 12 : 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _ForgotPasswordFormContent extends StatefulWidget {
  const _ForgotPasswordFormContent({required this.isCompact});

  final bool isCompact;

  @override
  State<_ForgotPasswordFormContent> createState() =>
      _ForgotPasswordFormContentState();
}

class _ForgotPasswordFormContentState
    extends State<_ForgotPasswordFormContent> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthCubit>().forgotPassword(_emailController.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LiquidTextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.email],
            onFieldSubmitted: (_) => _handleSubmit(),
            labelText: 'Email address',
            hintText: 'Enter your email',
            prefixIcon: Icons.email_outlined,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your email';
              }
              if (!Validators.isValidEmail(value.trim())) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          SizedBox(height: widget.isCompact ? 16 : 20),
          AuthPrimaryButton(
            label: 'Send Reset Link',
            onPressed: _handleSubmit,
          ),
        ],
      ),
    );
  }
}
