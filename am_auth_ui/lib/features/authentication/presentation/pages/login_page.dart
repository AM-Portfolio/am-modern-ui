import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:am_design_system/core/config/feature_flags.dart';
import 'package:am_design_system/core/constants/app_config.dart';
import 'package:am_design_system/core/theme/app_spacing.dart';
import 'package:am_design_system/core/theme/app_text_styles.dart';
import 'package:am_design_system/core/theme/color_extensions.dart';
import 'package:am_design_system/core/theme/cubit/theme_cubit.dart';

import '../../../../core/utils/auth_redirect.dart';
import '../../../../di/auth_providers.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import '../widgets/auth_method_pill_tabs.dart';
import '../widgets/auth_page_background.dart';
import '../widgets/dev_section_widget.dart';
import '../widgets/email_login_form_widget.dart';
import '../widgets/glass_card_widget.dart';
import '../widgets/google_login_button_widget.dart';
import '../widgets/theme_toggle_widget.dart';
import '../widgets/web_otp_login_widget.dart';
import '../widgets/web_qr_login_section.dart';

/// Redesigned login page with glassmorphism, global theme, and better mobile UX
class LoginPage extends StatefulWidget {
  final String? appName;
  final IconData? appIcon;

  const LoginPage({
    super.key,
    this.appName,
    this.appIcon,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

enum _WebLoginMethod { classic, scanQr, otp }

class _LoginPageState extends State<LoginPage> {
  _WebLoginMethod _webLoginMethod = _WebLoginMethod.classic;
  PrefetchedQrSession? _prefetchedQr;
  Future<PrefetchedQrSession>? _prefetchQrFuture;

  @override
  void initState() {
    super.initState();
    if (kIsWeb && FeatureFlags().enableQrWebLogin) {
      _prefetchQrFuture = _prefetchQr();
    }
  }

  Future<PrefetchedQrSession> _prefetchQr() async {
    try {
      final session =
          await prefetchQrSession(AuthProviders.deviceLinkPollService);
      if (mounted) {
        setState(() => _prefetchedQr = session);
      }
      return session;
    } catch (e) {
      // Section will start its own session if prefetch fails.
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveAppName = widget.appName ?? AppConfig.getAppName();

    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<AuthCubit, AuthState>(
          listener: (context, state) {
            if (state is Authenticated) {
              final router = GoRouter.maybeOf(context);
              if (router != null) {
                final target = AuthRedirect.postLoginLocation(
                  GoRouterState.of(context).uri,
                );
                context.go(target);
              } else {
                Navigator.of(context).pushReplacementNamed('/home');
              }
            } else if (state is RegisterPendingVerification) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Please verify ${state.email} before signing in. Check your Asrax welcome email.',
                  ),
                  backgroundColor: context.colors.statusWarning,
                  duration: const Duration(seconds: 8),
                  action: SnackBarAction(
                    label: 'Resend',
                    textColor: Colors.white,
                    onPressed: () {
                      context.read<AuthCubit>().resendVerifyEmail(state.email);
                    },
                  ),
                ),
              );
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
            if (kIsWeb) {
              final redirect =
                  GoRouterState.of(context).uri.queryParameters['redirect'];
              final restoringSession = redirect != null &&
                  redirect.startsWith('/app') &&
                  (state is AuthInitial ||
                      state is AuthLoading ||
                      state is AuthRestoreFailed);
              if (restoringSession) {
                return const Scaffold(
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Restoring your session…'),
                      ],
                    ),
                  ),
                );
              }
            }

            return BlocBuilder<ThemeCubit, ThemeState>(
              builder: (context, themeState) {
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final isCompact = constraints.maxWidth < 600;

                    return Stack(
                      children: [
                        const AuthPageBackground(),
                        Center(
                          child: SingleChildScrollView(
                            padding: EdgeInsets.all(isCompact ? 16 : 24),
                            child: GlassCardWidget(
                              isCompact: isCompact,
                              maxWidth: isCompact ? double.infinity : 1080,
                              enableMotion: false,
                              child: isCompact
                                  ? _buildCompactShell(
                                      context,
                                      state,
                                      effectiveAppName,
                                    )
                                  : _buildWideShell(
                                      context,
                                      state,
                                      effectiveAppName,
                                    ),
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

  Widget _buildCompactShell(
    BuildContext context,
    AuthState state,
    String appName,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Welcome Back!',
          textAlign: TextAlign.center,
          style: context.text.heroTitle(compact: true).copyWith(
                color: context.colors.textPrimary,
              ),
        ),
        const SizedBox(height: AppSpacing.sm - 2),
        Text(
          'Sign in to continue to your account',
          textAlign: TextAlign.center,
          style: context.text.bodyMuted().copyWith(
                color: context.colors.textSecondary,
              ),
        ),
        const SizedBox(height: AppSpacing.md + 4),
        _buildLoginForm(context, state, isCompact: true, showEmailTitle: false),
      ],
    );
  }

  Widget _buildWideShell(
    BuildContext context,
    AuthState state,
    String appName,
  ) {
    // Avoid IntrinsicHeight: QR/OTP panes use LayoutBuilder (via QrImageView),
    // which cannot report intrinsic dimensions and blanked the glass card.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 5,
          child: _buildBrandingPanel(context, appName),
        ),
        Expanded(
          flex: 5,
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: context.colors.divider.withValues(alpha: 0.5),
                ),
              ),
            ),
            padding: const EdgeInsets.only(left: 24),
            child: _buildLoginForm(
              context,
              state,
              isCompact: false,
              showEmailTitle: true,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBrandingPanel(BuildContext context, String appName) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Welcome back',
            style: context.text.heroTitle().copyWith(
                  color: context.colors.textPrimary,
                ),
          ),
          const SizedBox(height: AppSpacing.sm + 4),
          Text(
            'Sign in to $appName and continue managing your portfolio with confidence.',
            style: context.text.body().copyWith(
                  color: context.colors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginForm(
    BuildContext context,
    AuthState state, {
    required bool isCompact,
    required bool showEmailTitle,
  }) {
    final flags = FeatureFlags();
    final showWebLoginTabs =
        kIsWeb && (flags.enableQrWebLogin || flags.enableWebOtp);

    if (showWebLoginTabs) {
      final activeMethod = _resolveWebLoginMethod(_webLoginMethod, flags);
      // Match QR/OTP: one short pane blurb, no large in-tab header.
      final panes = <Widget>[
        _buildClassicLogin(
          context,
          state,
          isCompact,
          showEmailTitle: false,
          showPaneBlurb: true,
        ),
        if (flags.enableQrWebLogin)
          WebQrLoginSection(
            prefetched: _prefetchedQr,
            prefetchFuture: _prefetchQrFuture,
            isActive: activeMethod == _WebLoginMethod.scanQr,
            onSessionUpdated: (session) {
              setState(() => _prefetchedQr = session);
            },
          ),
        if (flags.enableWebOtp) const WebOtpLoginWidget(),
      ];
      final paneIndex = switch (activeMethod) {
        _WebLoginMethod.classic => 0,
        _WebLoginMethod.scanQr => flags.enableQrWebLogin ? 1 : 0,
        _WebLoginMethod.otp => flags.enableQrWebLogin
            ? (flags.enableWebOtp ? 2 : 0)
            : (flags.enableWebOtp ? 1 : 0),
      };

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildWebLoginMethodSwitch(context, isCompact, flags, activeMethod),
          SizedBox(height: isCompact ? 16 : 20),
          IndexedStack(
            index: paneIndex.clamp(0, panes.length - 1),
            children: panes,
          ),
          SizedBox(height: isCompact ? 12 : 16),
          DevSectionWidget(isCompact: isCompact),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        ..._buildClassicLoginChildren(
          context,
          state,
          isCompact,
          showEmailTitle: showEmailTitle,
        ),
        SizedBox(height: isCompact ? 12 : 16),
        DevSectionWidget(isCompact: isCompact),
      ],
    );
  }

  _WebLoginMethod _resolveWebLoginMethod(
    _WebLoginMethod method,
    FeatureFlags flags,
  ) {
    return switch (method) {
      _WebLoginMethod.scanQr when !flags.enableQrWebLogin =>
        _WebLoginMethod.classic,
      _WebLoginMethod.otp when !flags.enableWebOtp => _WebLoginMethod.classic,
      _ => method,
    };
  }

  Widget _buildWebLoginMethodSwitch(
    BuildContext context,
    bool isCompact,
    FeatureFlags flags,
    _WebLoginMethod activeMethod,
  ) {
    final options = <AuthMethodPillOption<_WebLoginMethod>>[
      AuthMethodPillOption(
        value: _WebLoginMethod.classic,
        label: isCompact ? 'Email' : 'Email & Google',
        icon: Icons.mail_outline,
      ),
      if (flags.enableQrWebLogin)
        const AuthMethodPillOption(
          value: _WebLoginMethod.scanQr,
          label: 'Scan QR',
          icon: Icons.qr_code_2_outlined,
        ),
      if (flags.enableWebOtp)
        const AuthMethodPillOption(
          value: _WebLoginMethod.otp,
          label: 'OTP',
          icon: Icons.phonelink_lock_outlined,
        ),
    ];

    return AuthMethodPillTabs<_WebLoginMethod>(
      options: options,
      selected: activeMethod,
      compact: isCompact,
      accentColor: context.colors.actionPrimaryBg,
      onChanged: (value) => setState(() => _webLoginMethod = value),
    );
  }

  Widget _buildClassicLogin(
    BuildContext context,
    AuthState state,
    bool isCompact, {
    required bool showEmailTitle,
    bool showPaneBlurb = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: _buildClassicLoginChildren(
        context,
        state,
        isCompact,
        showEmailTitle: showEmailTitle,
        showPaneBlurb: showPaneBlurb,
      ),
    );
  }

  List<Widget> _buildClassicLoginChildren(
    BuildContext context,
    AuthState state,
    bool isCompact, {
    required bool showEmailTitle,
    bool showPaneBlurb = false,
  }) {
    return [
      if (showPaneBlurb) ...[
        Text(
          'Sign in with your email and password, or continue with Google.',
          textAlign: TextAlign.center,
          style: context.text.bodyMuted(compact: true).copyWith(
                color: context.colors.textSecondary,
                height: 1.4,
              ),
        ),
        const SizedBox(height: 16),
      ],
      EmailLoginFormWidget(
        isCompact: isCompact,
        isLoading: state is AuthLoading,
        showTitle: showEmailTitle,
      ),
      SizedBox(height: isCompact ? 16 : 20),
      Row(
        children: [
          Expanded(child: Divider(color: context.colors.divider)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'OR',
              style: TextStyle(
                fontSize: isCompact ? 11 : 12,
                color: context.colors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(child: Divider(color: context.colors.divider)),
        ],
      ),
      SizedBox(height: isCompact ? 16 : 20),
      GoogleLoginButtonWidget(isLoading: state is AuthLoading),
      SizedBox(height: isCompact ? 16 : 20),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Don't have an account? ",
            style: TextStyle(
              fontSize: isCompact ? 12 : 13,
              color: context.colors.textSecondary,
            ),
          ),
          _LiquidAuthLink(
            text: 'Create Account',
            isCompact: isCompact,
            onPressed: () => context.push('/register'),
          ),
        ],
      ),
    ];
  }
}

class _LiquidAuthLink extends StatefulWidget {
  final String text;
  final bool isCompact;
  final VoidCallback onPressed;

  const _LiquidAuthLink({
    required this.text,
    required this.isCompact,
    required this.onPressed,
  });

  @override
  State<_LiquidAuthLink> createState() => _LiquidAuthLinkState();
}

class _LiquidAuthLinkState extends State<_LiquidAuthLink> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final linkColor = context.colors.actionPrimaryBg
        .withValues(alpha: _isHovering ? 1.0 : 0.9);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: TextStyle(
            fontSize: widget.isCompact ? 12 : 13,
            color: linkColor,
            fontWeight: FontWeight.w700,
          ),
          child: Text(
            widget.text,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
