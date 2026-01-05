import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:am_design_system/core/constants/app_config.dart';
import 'package:am_design_system/core/theme/cubit/theme_cubit.dart';
import '../widgets/app_header_widget.dart';
import '../widgets/glass_card_widget.dart';
import '../widgets/theme_toggle_widget.dart';
import 'package:am_design_system/shared/widgets/inputs/glass_text_field.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import 'package:am_design_system/core/utils/validators.dart';
import 'package:am_design_system/shared/widgets/display/interactive_background.dart';


class ForgotPasswordPage extends StatelessWidget {
  const ForgotPasswordPage({super.key});

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
                              child: ForgotPasswordForm(
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
                    const Color(0xFF1A1A2E),
                    const Color(0xFF16213E),
                    const Color(0xFF0F3460),
                  ]
                : [
                    Colors.deepPurple.shade50,
                    Colors.blue.shade50,
                    Colors.purple.shade50,
                  ],
          ),
        ),
        child: InteractiveBackground(
          baseColor: isDark ? const Color(0xFF6C63FF) : Colors.deepPurple.shade200,
          highlightColor: isDark ? Colors.cyanAccent : Colors.blueAccent,
        ),
      ),
    );
  }

}

/// Forgot password form for use inside persistent shell
class ForgotPasswordForm extends StatelessWidget {
  const ForgotPasswordForm({
    super.key, 
    required this.onLogin,
  });

  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) => BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is PasswordResetEmailSent) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Password reset instructions sent to your email'),
              backgroundColor: Colors.green,
            ),
          );
          onLogin(); // Go back to login after success
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      builder: (context, state) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Forgot Password? 🔑',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'Enter your email address and we\'ll send you instructions to reset your password.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 32),

          // Forgot password form
          if (state is AuthLoading)
            const Center(child: CircularProgressIndicator())
          else
            const _ForgotPasswordFormContent(),

          const SizedBox(height: 24),

          // Back to login link
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Remember your password? '),
              TextButton(
                onPressed: onLogin,
                child: const Text('Sign In'),
              ),
            ],
          ),
        ],
      ),
    );
}

/// Internal form state
class _ForgotPasswordFormContent extends StatefulWidget {
  const _ForgotPasswordFormContent();

  @override
  State<_ForgotPasswordFormContent> createState() => _ForgotPasswordFormContentState();
}

class _ForgotPasswordFormContentState extends State<_ForgotPasswordFormContent> {
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
  Widget build(BuildContext context) => Form(
    key: _formKey,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Email
        GlassTextField(
          controller: _emailController,
          hintText: 'Email',
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
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
        const SizedBox(height: 24),

        // Send Reset Link Button
        ElevatedButton(
          onPressed: _handleSubmit,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.all(16),
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: const Text(
            'Send Reset Link',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    ),
  );
}
