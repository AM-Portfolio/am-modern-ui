import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:am_design_system/core/constants/app_config.dart';
import 'package:am_design_system/core/theme/cubit/theme_cubit.dart';
import 'package:am_design_system/core/theme/app_colors.dart';
import '../widgets/app_header_widget.dart';
import '../widgets/glass_card_widget.dart';
import '../widgets/theme_toggle_widget.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import '../widgets/registration_form_widget.dart';
import 'package:am_design_system/shared/widgets/display/interactive_background.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<ThemeCubit, ThemeState>(
          builder: (context, themeState) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 600;
                
                return Stack(
                  children: [
                    // Background
                    _buildBackground(themeState.isDarkMode),
                    
                    // Main content
                    Center(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(isCompact ? 16 : 24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AppHeaderWidget(
                              appName: AppConfig.getAppName(),
                              appIcon: AppConfig.getAppIcon(),
                              isCompact: isCompact,
                            ),
                            if (isCompact) const SizedBox(height: 24),
                            
                            GlassCardWidget(
                              isCompact: isCompact,
                              child: RegisterPageForm(
                                onLogin: () => Navigator.of(context).pop(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Theme toggle
                    Positioned(
                      top: 16,
                      right: 16,
                      child: ThemeToggleWidget(iconSize: isCompact ? 20 : 24),
                    ),
                    
                    // Back button
                    Positioned(
                      top: 16,
                      left: 16,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ],
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
}

/// User registration form for use inside persistent shell
class RegisterPageForm extends StatelessWidget {
  const RegisterPageForm({super.key, required this.onLogin});

  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) => BlocConsumer<AuthCubit, AuthState>(
    listener: (context, state) {
      if (state is Authenticated) {
        // Navigate to home page after successful registration
        Navigator.of(context).pushReplacementNamed('/home');
      } else if (state is AuthError) {
        // Check if message contains User ID (UUID)
        if (state.message.contains('User ID:')) {
          // Extract UUID from message
          final uuidMatch = RegExp(
            r'User ID: ([a-f0-9-]+)',
          ).firstMatch(state.message);
          final userId = uuidMatch?.group(1) ?? '';

          // Show dialog with copy button
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.check_circle, color: AppColors.success),
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
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
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
                              const SnackBar(
                                content: Text('UUID copied to clipboard!'),
                                duration: Duration(seconds: 2),
                                backgroundColor: AppColors.success,
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
                    style: TextStyle(fontSize: 12, color: AppColors.textTertiaryLight),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close dialog
                    onLogin(); // Back to login via callback
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        } else {
          // Show regular error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: AppColors.error),
          );
        }
      }
    },
    builder: (context, state) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Create Account ✨',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),

        // Registration form
        if (state is AuthLoading)
          const Center(child: CircularProgressIndicator())
        else
          const RegistrationFormWidget(),

        const SizedBox(height: 24),

        // Already have account link
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Already have an account? '),
            TextButton(onPressed: onLogin, child: const Text('Sign In')),
          ],
        ),
      ],
    ),
  );
}
