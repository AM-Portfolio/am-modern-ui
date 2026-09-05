import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:am_design_system/core/theme/app_spacing.dart';
import 'package:am_design_system/core/theme/app_text_styles.dart';
import 'package:am_design_system/core/theme/color_extensions.dart';

import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import '../widgets/auth_flow_shell.dart';
import '../widgets/auth_primary_button.dart';

/// Confirms email verification from `?c=` (preferred) or `?token=` deep link.
/// On success the cubit stores tokens and emits [Authenticated]; this page
/// navigates into the app (auto-login).
class VerifyEmailPage extends StatefulWidget {
  const VerifyEmailPage({super.key, this.token, this.code});

  final String? token;
  final String? code;

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  var _started = false;

  String? get _code {
    final c = widget.code?.trim();
    return (c != null && c.isNotEmpty) ? c : null;
  }

  String? get _token {
    final t = widget.token?.trim();
    return (t != null && t.isNotEmpty) ? t : null;
  }

  bool get _hasCredential => _code != null || _token != null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (!_hasCredential) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AuthCubit>().confirmVerifyEmail(
            token: _code == null ? _token : null,
            code: _code,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    return AuthFlowShell(
      brandingTitle: 'Verify your email',
      brandingSubtitle:
          'Confirm your Asrax account so we can finish signing you in.',
      form: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is Authenticated) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Email verified. Signing you in…'),
                backgroundColor: context.colors.statusSuccess,
              ),
            );
            final router = GoRouter.maybeOf(context);
            if (router != null) {
              context.go('/app/dashboard');
            }
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
          final isCompact = MediaQuery.sizeOf(context).width < 600;
          final String message;
          if (!_hasCredential) {
            message = 'This verification link is incomplete.';
          } else if (state is Authenticated) {
            message =
                'Your Asrax email is verified. Opening your portfolio…';
          } else if (state is AuthError) {
            message = state.message;
          } else {
            message = 'Verifying your Asrax account…';
          }

          final busy = state is AuthLoading ||
              (_hasCredential &&
                  state is! Authenticated &&
                  state is! AuthError);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Verify email',
                style: context.text.pageTitle(compact: isCompact).copyWith(
                      color: context.colors.textPrimary,
                    ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Asrax account confirmation',
                style: context.text.bodyMuted(compact: isCompact).copyWith(
                      color: context.colors.textSecondary,
                    ),
              ),
              SizedBox(height: isCompact ? AppSpacing.md : AppSpacing.md + 4),
              if (busy)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                Text(
                  message,
                  style: context.text.body(compact: isCompact).copyWith(
                        color: context.colors.textSecondary,
                      ),
                ),
              if (state is AuthError || !_hasCredential) ...[
                SizedBox(height: isCompact ? AppSpacing.md : AppSpacing.md + 4),
                AuthPrimaryButton(
                  label: 'Continue to Sign In',
                  onPressed: () => context.go('/login'),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
