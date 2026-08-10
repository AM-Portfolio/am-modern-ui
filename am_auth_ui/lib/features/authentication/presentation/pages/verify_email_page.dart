import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:am_design_system/core/constants/app_config.dart';
import 'package:am_design_system/core/theme/cubit/theme_cubit.dart';
import 'package:am_design_system/core/theme/app_colors.dart';
import 'package:am_design_system/core/theme/color_extensions.dart';
import 'package:am_design_system/shared/widgets/display/interactive_background.dart';

import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import '../widgets/app_header_widget.dart';
import '../widgets/glass_card_widget.dart';
import '../widgets/theme_toggle_widget.dart';

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
    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<AuthCubit, AuthState>(
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
            return BlocBuilder<ThemeCubit, ThemeState>(
              builder: (context, themeState) {
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final isCompact = constraints.maxWidth < 600;
                    String message;
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

                    return Stack(
                      children: [
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  context.colors.surface,
                                  context.colors.scaffoldBackground,
                                  context.colors.surface,
                                ],
                              ),
                            ),
                            child: InteractiveBackground(
                              baseColor: context.colors.actionPrimaryBg,
                              highlightColor: context.colors.actionPrimaryBg.withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                        Center(
                          child: SingleChildScrollView(
                            padding: EdgeInsets.all(isCompact ? 16 : 24),
                            child: Column(
                              children: [
                                AppHeaderWidget(
                                  appName: AppConfig.getAppName(),
                                  appIcon: AppConfig.getAppIcon(),
                                  isCompact: isCompact,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Asrax account',
                                  style: TextStyle(
                                    color: context.colors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                GlassCardWidget(
                                  isCompact: isCompact,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Text(
                                        'Verify email',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: context.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      if (state is AuthLoading ||
                                          (_hasCredential &&
                                              state is! Authenticated &&
                                              state is! AuthError))
                                        const Center(
                                          child: Padding(
                                            padding: EdgeInsets.all(16),
                                            child: CircularProgressIndicator(),
                                          ),
                                        )
                                      else
                                        Text(
                                          message,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: context.textSecondary,
                                          ),
                                        ),
                                      if (state is AuthError ||
                                          !_hasCredential) ...[
                                        const SizedBox(height: 24),
                                        FilledButton(
                                          onPressed: () =>
                                              context.go('/login'),
                                          child: const Text(
                                            'Continue to sign in',
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          top: 16,
                          right: 16,
                          child: ThemeToggleWidget(
                            iconSize: isCompact ? 20 : 24,
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
