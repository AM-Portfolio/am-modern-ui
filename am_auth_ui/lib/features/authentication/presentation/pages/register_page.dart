import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:am_design_system/core/constants/app_config.dart';
import 'package:am_design_system/core/theme/color_extensions.dart';

import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import '../widgets/auth_flow_shell.dart';
import '../widgets/registration_form_widget.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final appName = AppConfig.getAppName();

    return AuthFlowShell(
      showBack: true,
      onBack: () => Navigator.of(context).pop(),
      brandingTitle: 'Join $appName',
      brandingSubtitle:
          'Create your account and start managing your portfolio with confidence.',
      form: RegisterPageForm(
        onLogin: () => Navigator.of(context).pop(),
      ),
    );
  }
}

class RegisterPageForm extends StatelessWidget {
  const RegisterPageForm({super.key, required this.onLogin});

  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 600;
    final primary = context.colors.actionPrimaryBg;

    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is RegisterPendingVerification) {
          showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (dialogContext) => AlertDialog(
              title: const Text('Check your email'),
              content: Text(
                'Account created for ${state.email}. Verify your Asrax account from the email we sent, then sign in.\n\n'
                'If you do not see the email, check spam or tap Resend.',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    context.read<AuthCubit>().resendVerifyEmail(state.email);
                  },
                  child: const Text('Resend'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    onLogin();
                  },
                  child: const Text('Go to sign in'),
                ),
              ],
            ),
          );
        } else if (state is Authenticated) {
          Navigator.of(context).pushReplacementNamed('/home');
        } else if (state is AuthError) {
          if (state.message.contains('User ID:')) {
            final uuidMatch = RegExp(
              r'User ID: ([a-f0-9-]+)',
            ).firstMatch(state.message);
            final userId = uuidMatch?.group(1) ?? '';

            showDialog<void>(
              context: context,
              builder: (context) => AlertDialog(
                title: Row(
                  children: [
                    Icon(Icons.check_circle,
                        color: context.colors.statusSuccess),
                    const SizedBox(width: 8),
                    const Text('Account Created!'),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your account has been created successfully.',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Copy your User ID to activate:',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: context.colors.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: context.colors.border),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: SelectableText(
                              userId,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy, size: 18),
                            tooltip: 'Copy to clipboard',
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: userId));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content:
                                      const Text('UUID copied to clipboard!'),
                                  duration: const Duration(seconds: 2),
                                  backgroundColor:
                                      context.colors.statusSuccess,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Open Developer Controls on the login screen to activate your account.',
                      style: TextStyle(
                          fontSize: 12, color: context.textTertiary),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onLogin();
                    },
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: context.colors.statusError,
              ),
            );
          }
        }
      },
      builder: (context, state) {
        final loading = state is AuthLoading;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Create your account',
              style: TextStyle(
                fontSize: isCompact ? 18 : 22,
                fontWeight: FontWeight.w700,
                color: context.colors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Fill in your details to get started.',
              style: TextStyle(
                fontSize: isCompact ? 12 : 13,
                color: context.colors.textSecondary,
              ),
            ),
            SizedBox(height: isCompact ? 16 : 20),
            RegistrationFormWidget(
              isCompact: isCompact,
              isLoading: loading,
            ),
            SizedBox(height: isCompact ? 12 : 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Already have an account?',
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
