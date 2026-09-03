import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:am_design_system/core/config/feature_flags.dart';
import 'package:am_design_system/core/constants/app_config.dart';
import 'package:am_design_system/core/theme/color_extensions.dart';
import 'package:am_design_system/core/theme/cubit/theme_cubit.dart';
import 'package:am_design_system/shared/widgets/display/interactive_background.dart';

import '../../../../core/utils/auth_redirect.dart';
import '../../../../di/auth_providers.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import '../widgets/auth_method_pill_tabs.dart';
import '../widgets/dev_section_widget.dart';
import '../widgets/email_login_form_widget.dart';
import '../widgets/glass_card_widget.dart';
import '../widgets/google_login_button_widget.dart';
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

  @override
  void initState() {
    super.initState();
    if (kIsWeb && FeatureFlags().enableQrWebLogin) {
      unawaited(_prefetchQr());
    }
  }

  Future<void> _prefetchQr() async {
    try {
      final session =
          await prefetchQrSession(AuthProviders.deviceLinkPollService);
      if (!mounted) return;
      setState(() => _prefetchedQr = session);
    } catch (_) {
      // Section will start its own session if the user opens Scan QR.
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
                        _buildBackground(),
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

  Widget _buildBackground() {
    return Positioned.fill(
      child: Builder(
        builder: (context) => Container(
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
            highlightColor:
                context.colors.actionPrimaryBg.withValues(alpha: 0.8),
          ),
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
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: context.colors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Sign in to continue to your account',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: context.colors.textSecondary,
          ),
        ),
        const SizedBox(height: 20),
        _buildLoginForm(context, state, isCompact: true, showEmailTitle: false),
      ],
    );
  }

  Widget _buildWideShell(
    BuildContext context,
    AuthState state,
    String appName,
  ) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 5,
            child: _buildBrandingPanel(context, appName),
          ),
          Container(
            width: 1,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            color: context.colors.divider.withValues(alpha: 0.5),
          ),
          Expanded(
            flex: 5,
            child: _buildLoginForm(
              context,
              state,
              isCompact: false,
              showEmailTitle: true,
            ),
          ),
        ],
      ),
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
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              height: 1.15,
              color: context.colors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Sign in to $appName and continue managing your portfolio with confidence.',
            style: TextStyle(
              fontSize: 14,
              height: 1.45,
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
      final panes = <Widget>[
        _buildClassicLogin(
          context,
          state,
          isCompact,
          showEmailTitle: showEmailTitle,
        ),
        if (flags.enableQrWebLogin)
          WebQrLoginSection(
            prefetched: _prefetchedQr,
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
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: _buildClassicLoginChildren(
        context,
        state,
        isCompact,
        showEmailTitle: showEmailTitle,
      ),
    );
  }

  List<Widget> _buildClassicLoginChildren(
    BuildContext context,
    AuthState state,
    bool isCompact, {
    required bool showEmailTitle,
  }) {
    return [
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
