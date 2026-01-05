import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:am_design_system/core/constants/app_config.dart';
import 'package:am_design_system/core/theme/cubit/theme_cubit.dart';
import 'package:am_design_system/core/theme/app_colors.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import '../widgets/app_header_widget.dart';
import '../widgets/dev_section_widget.dart';
import '../widgets/email_login_form_widget.dart';
import '../widgets/glass_card_widget.dart';
import '../widgets/google_login_button_widget.dart';
import '../widgets/theme_toggle_widget.dart';
import 'package:am_design_system/shared/widgets/display/interactive_background.dart';


/// Redesigned login page with glassmorphism, global theme, and better mobile UX
class LoginPage extends StatelessWidget {
  final String? appName;
  final IconData? appIcon;
  
  const LoginPage({
    super.key,
    this.appName,
    this.appIcon,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveAppName = appName ?? AppConfig.getAppName();
    final effectiveAppIcon = appIcon ?? AppConfig.getAppIcon();
    
    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<AuthCubit, AuthState>(
          listener: (context, state) {
            if (state is Authenticated) {
              Navigator.of(context).pushReplacementNamed('/home');
            } else if (state is AuthError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.error,
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
                    
                    return Stack(
                      children: [
                        // Background gradient (adapts to theme)
                        _buildBackground(themeState.isDarkMode),
                        
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
  
  Widget _buildBackground(bool isDark) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    AppColors.darkBackground,
                    AppColors.darkBackgroundLight,
                    AppColors.darkBackgroundDeep,
                  ]
                : [
                    AppColors.lightBackgroundAlt,
                    AppColors.lightBackground,
                    AppColors.lightBackgroundAlt,
                  ],
          ),
        ),
        child: InteractiveBackground(
          baseColor: isDark ? AppColors.authAccent : AppColors.primaryLight,
          highlightColor: isDark ? AppColors.accentBlue : AppColors.info,
        ),
      ),
    );
  }

  
  Widget _buildLoginForm(BuildContext context, AuthState state, bool isCompact) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Email/Password form
        if (state is AuthLoading)
          const Center(child: CircularProgressIndicator())
        else
          EmailLoginFormWidget(isCompact: isCompact),
        
        SizedBox(height: isCompact ? 16 : 24),
        
        // Divider
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'OR',
                style: TextStyle(
                  fontSize: isCompact ? 11 : 12,
                  color: AppColors.textTertiaryLight,
                ),
              ),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        
        SizedBox(height: isCompact ? 16 : 24),
        
        // Google login
        const GoogleLoginButtonWidget(),
        
        SizedBox(height: isCompact ? 16 : 24),
        
        // Auth links (Forgot Password | Create Account)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: TextButton(
                onPressed: () => Navigator.of(context).pushNamed('/forgot-password'),
                child: Text(
                  'Forgot Password?',
                  style: TextStyle(
                    fontSize: isCompact ? 13 : 14,
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
            Text(
              '|',
              style: TextStyle(
                color: AppColors.textTertiaryLight,
                fontSize: isCompact ? 13 : 14,
              ),
            ),
            Flexible(
              child: TextButton(
                onPressed: () => Navigator.of(context).pushNamed('/register'),
                child: Text(
                  'Create Account',
                  style: TextStyle(
                    fontSize: isCompact ? 13 : 14,
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
          ],
        ),
        
        SizedBox(height: isCompact ? 12 : 16),
        
        // Developer section (collapsible)
        DevSectionWidget(isCompact: isCompact),
      ],
    );
  }
}
