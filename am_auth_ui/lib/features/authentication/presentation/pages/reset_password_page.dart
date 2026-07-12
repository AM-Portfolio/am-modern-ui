import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:am_design_system/core/constants/app_config.dart';
import 'package:am_design_system/core/theme/cubit/theme_cubit.dart';
import 'package:am_design_system/core/theme/app_colors.dart';
import 'package:am_design_system/core/theme/color_extensions.dart';
import '../widgets/app_header_widget.dart';
import '../widgets/glass_card_widget.dart';
import '../widgets/theme_toggle_widget.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import 'package:am_design_system/core/utils/validators.dart';
import 'package:am_design_system/shared/widgets/display/interactive_background.dart';

/// Reset password page with redesigned UI
class ResetPasswordPage extends StatelessWidget {
  const ResetPasswordPage({super.key, this.resetToken, this.resetCode});
  
  final String? resetToken;
  final String? resetCode;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<AuthCubit, AuthState>(
          listener: (context, state) {
            if (state is PasswordResetSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Password reset successfully! Please sign in with your new password.'),
                  backgroundColor: AppColors.success,
                ),
              );
              context.go('/login');
            } else if (state is AuthError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message), backgroundColor: AppColors.error),
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
                        // Background
                        _buildBackground(),
                        
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
                                  child: ResetPasswordPageForm(
                                    resetToken: resetToken,
                                    resetCode: resetCode,
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
              colors: context.isDark
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
            baseColor: context.isDark ? AppColors.authAccent : AppColors.primaryLight,
            highlightColor: context.isDark ? AppColors.accentBlue : AppColors.info,
          ),
        ),
      ),
    );
  }
}

/// Reset password form widget
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
  Widget build(BuildContext context) => Form(
    key: _formKey,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Reset Password 🔐',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),

        if (!_hasDeepLink) ...[
          TextFormField(
            controller: _tokenController,
            decoration: const InputDecoration(
              labelText: 'Reset Token',
              prefixIcon: Icon(Icons.vpn_key_outlined),
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Reset token is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
        ],

        // New Password
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            labelText: 'New Password',
            prefixIcon: const Icon(Icons.lock),
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) return 'Please enter a password';
            if (value.length < 8) return 'Password must be at least 8 characters';
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Confirm Password
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: _obscureConfirmPassword,
          decoration: InputDecoration(
            labelText: 'Confirm Password',
            prefixIcon: const Icon(Icons.lock_outline),
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed: () {
                setState(() {
                  _obscureConfirmPassword = !_obscureConfirmPassword;
                });
              },
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) return 'Please confirm your password';
            if (value != _passwordController.text) return 'Passwords do not match';
            return null;
          },
        ),
        const SizedBox(height: 32),

        // Reset Password Button
        SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: _handleSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Reset Password',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Back to login link
        TextButton(
          onPressed: () {
            Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
          },
          child: const Text('Back to Sign In'),
        ),
      ],
    ),
  );
}
