import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:am_design_system/core/constants/app_config.dart';
import 'package:am_design_system/core/theme/cubit/theme_cubit.dart';
import 'package:am_design_system/core/theme/color_extensions.dart';
import '../../../../core/utils/auth_redirect.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import '../widgets/app_header_widget.dart';
import '../widgets/dev_section_widget.dart';
import '../widgets/email_login_form_widget.dart';
import '../widgets/glass_card_widget.dart';
import '../widgets/google_login_button_widget.dart';
import '../widgets/theme_toggle_widget.dart';
import '../widgets/web_otp_login_widget.dart';
import '../widgets/web_qr_login_section.dart';
import 'package:am_design_system/core/config/feature_flags.dart';
import 'package:am_design_system/shared/widgets/display/interactive_background.dart';


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

  @override
  Widget build(BuildContext context) {
    final effectiveAppName = widget.appName ?? AppConfig.getAppName();
    final effectiveAppIcon = widget.appIcon ?? AppConfig.getAppIcon();
    
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
                        // Background gradient (adapts to theme)
                        _buildBackground(),
                        
                        // Main content
                        Center(
                          child: SingleChildScrollView(
                            padding: EdgeInsets.all(isCompact ? 16 : 24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // App header (mobile only)
                                AppHeaderWidget(
                                  appName: effectiveAppName,
                                  appIcon: effectiveAppIcon,
                                  isCompact: isCompact,
                                ),
                                if (isCompact) const SizedBox(height: 24),
                                
                                // Login card with glassmorphism
                                GlassCardWidget(
                                  isCompact: isCompact,
                                  child: _buildLoginForm(context, state, isCompact),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        // Theme toggle (top-right)
                        Positioned(
                          top: 16,
                          right: 16,
                          child: ThemeToggleWidget(iconSize: isCompact ? 20 : 24),
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
            highlightColor: context.colors.actionPrimaryBg.withValues(alpha: 0.8),
          ),
        ),
      ),
    );
  }

  
  Widget _buildLoginForm(BuildContext context, AuthState state, bool isCompact) {
    final flags = FeatureFlags();
    final showWebLoginTabs =
        kIsWeb && (flags.enableQrWebLogin || flags.enableWebOtp);

    if (showWebLoginTabs) {
      final activeMethod = _resolveWebLoginMethod(_webLoginMethod, flags);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildWebLoginMethodSwitch(context, isCompact, flags),
          SizedBox(height: isCompact ? 16 : 20),
          switch (activeMethod) {
            _WebLoginMethod.classic =>
              _buildClassicLogin(context, state, isCompact),
            _WebLoginMethod.scanQr => _buildScanQrLogin(context, isCompact),
            _WebLoginMethod.otp => _buildOtpLogin(context, isCompact),
          },
          SizedBox(height: isCompact ? 12 : 16),
          DevSectionWidget(isCompact: isCompact),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        ..._buildClassicLoginChildren(context, state, isCompact),
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
  ) {
    final segments = <ButtonSegment<_WebLoginMethod>>[
      ButtonSegment(
        value: _WebLoginMethod.classic,
        label: Text(
          isCompact ? 'Email' : 'Email & Google',
          style: TextStyle(fontSize: isCompact ? 11 : 13),
        ),
        icon: Icon(Icons.mail_outline, size: isCompact ? 15 : 18),
      ),
      if (flags.enableQrWebLogin)
        ButtonSegment(
          value: _WebLoginMethod.scanQr,
          label: Text(
            isCompact ? 'QR' : 'Scan QR',
            style: TextStyle(fontSize: isCompact ? 11 : 13),
          ),
          icon: Icon(Icons.qr_code_scanner, size: isCompact ? 15 : 18),
        ),
      if (flags.enableWebOtp)
        ButtonSegment(
          value: _WebLoginMethod.otp,
          label: Text(
            'OTP',
            style: TextStyle(fontSize: isCompact ? 11 : 13),
          ),
          icon: Icon(Icons.pin_outlined, size: isCompact ? 15 : 18),
        ),
    ];

    final activeMethod = _resolveWebLoginMethod(_webLoginMethod, flags);

    return SegmentedButton<_WebLoginMethod>(
      segments: segments,
      selected: {activeMethod},
      showSelectedIcon: false,
      onSelectionChanged: (selection) {
        setState(() => _webLoginMethod = selection.first);
      },
    );
  }

  Widget _buildClassicLogin(
    BuildContext context,
    AuthState state,
    bool isCompact,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: _buildClassicLoginChildren(context, state, isCompact),
    );
  }

  List<Widget> _buildClassicLoginChildren(
    BuildContext context,
    AuthState state,
    bool isCompact,
  ) {
    return [
      EmailLoginFormWidget(
        isCompact: isCompact,
        isLoading: state is AuthLoading,
      ),
      SizedBox(height: isCompact ? 16 : 24),
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
      SizedBox(height: isCompact ? 16 : 24),
      GoogleLoginButtonWidget(isLoading: state is AuthLoading),
      SizedBox(height: isCompact ? 16 : 24),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: _LiquidAuthLink(
              text: 'Forgot Password?',
              isCompact: isCompact,
              onPressed: () => context.push('/forgot-password'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              '|',
              style: TextStyle(
                color: context.colors.textSecondary,
                fontSize: isCompact ? 13 : 14,
              ),
            ),
          ),
          Flexible(
            child: _LiquidAuthLink(
              text: 'Create Account',
              isCompact: isCompact,
              onPressed: () => context.push('/register'),
            ),
          ),
        ],
      ),
    ];
  }

  Widget _buildScanQrLogin(BuildContext context, bool isCompact) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Open the AM app on your phone, scan the QR code, and approve the login.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: isCompact ? 13 : 14,
            color: context.colors.textSecondary,
            height: 1.4,
          ),
        ),
        SizedBox(height: isCompact ? 12 : 16),
        const WebQrLoginSection(),
      ],
    );
  }

  Widget _buildOtpLogin(BuildContext context, bool isCompact) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Sign in with a one-time code sent to your email or phone.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: isCompact ? 13 : 14,
            color: context.colors.textSecondary,
            height: 1.4,
          ),
        ),
        SizedBox(height: isCompact ? 12 : 16),
        const WebOtpLoginWidget(),
      ],
    );
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
    final linkColor = context.colors.textPrimary.withValues(alpha: _isHovering ? 1.0 : 0.75);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: TextStyle(
            fontSize: widget.isCompact ? 13 : 14,
            color: linkColor,
            fontWeight: FontWeight.w500,
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

