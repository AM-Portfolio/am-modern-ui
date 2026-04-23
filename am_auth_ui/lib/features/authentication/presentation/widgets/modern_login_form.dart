import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:am_common/am_common.dart';
import 'package:am_design_system/core/utils/validators.dart';

/// A modern styled login form with improved UI/UX
class ModernLoginForm extends StatelessWidget {
  const ModernLoginForm({
    required this.formKey,
    required this.identifierController,
    required this.passwordController,
    required this.isLoading,
    required this.onLogin,
    required this.onQuickLogin,
    required this.onForgotPassword,
    required this.onRegister,
    required this.selectedLoginMethod,
    required this.onLoginMethodChanged,
    super.key,
    this.errorMessage,
    this.onSsdLogin,
  });
  final GlobalKey<FormState> formKey;
  final TextEditingController identifierController;
  final TextEditingController passwordController;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onLogin;
  final VoidCallback onQuickLogin;
  final VoidCallback? onSsdLogin;
  final VoidCallback onForgotPassword;
  final VoidCallback onRegister;
  final LoginMethod selectedLoginMethod;
  final Function(Set<LoginMethod>) onLoginMethodChanged;

  @override
  Widget build(BuildContext context) => Form(
    key: formKey,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Login method selector
        _buildLoginMethodSelector(context),
        const SizedBox(height: 24),

        // Identifier field (email, username, or phone)
        _buildIdentifierField(),
        const SizedBox(height: 16),

        // Password field with improved styling
        _buildPasswordField(context),
        const SizedBox(height: 8),

        // Forgot password link
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: onForgotPassword,
            style: TextButton.styleFrom(
              foregroundColor: Colors.white70,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: const Text(
              'Forgot Password?',
              style: TextStyle(fontSize: 14),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Error message
        if (errorMessage != null)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.error.withOpacity(0.3),
              ),
            ),
            child: Text(
              errorMessage!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        if (errorMessage != null) const SizedBox(height: 16),

        // Login button
        AppButton(
          text: 'Login',
          isLoading: isLoading,
          onPressed: onLogin,
          height: 52,
        ),
        const SizedBox(height: 16),

        // Quick login button
        AppButton(
          text: 'Quick Login (Demo User)',
          onPressed: isLoading ? null : onQuickLogin,
          type: AppButtonType.secondary,
          height: 52,
        ),
        const SizedBox(height: 16),

        // SSD2658 login button
        if (onSsdLogin != null)
          AppButton(
            text: 'Login as SSD2658',
            onPressed: isLoading ? null : onSsdLogin,
            type: AppButtonType.secondary,
            height: 52,
          ),
        const SizedBox(height: 24),

        // Register link
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Don't have an account?",
              style: TextStyle(color: Colors.white70),
            ),
            TextButton(
              onPressed: onRegister,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: const Text(
                'Register',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ],
    ),
  );

  // Build modern login method selector
  Widget _buildLoginMethodSelector(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
    ),
    padding: const EdgeInsets.all(4),
    child: SegmentedButton<LoginMethod>(
      segments: const [
        ButtonSegment<LoginMethod>(
          value: LoginMethod.email,
          label: Text('Email'),
          icon: Icon(Icons.email, size: 18),
        ),
        ButtonSegment<LoginMethod>(
          value: LoginMethod.username,
          label: Text('Username'),
          icon: Icon(Icons.person, size: 18),
        ),
        ButtonSegment<LoginMethod>(
          value: LoginMethod.phone,
          label: Text('Phone'),
          icon: Icon(Icons.phone, size: 18),
        ),
      ],
      selected: {selectedLoginMethod},
      onSelectionChanged: onLoginMethodChanged,
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white.withOpacity(0.2);
          }
          return Colors.transparent;
        }),
        foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return Colors.white70;
        }),
        visualDensity: VisualDensity.compact,
      ),
    ),
  );

  // Build dynamic identifier field based on selected login method
  Widget _buildIdentifierField() {
    late final String labelText;
    late final String hintText;
    late final TextInputType keyboardType;
    late final Widget prefix;
    late final String? Function(String?)? validator;

    switch (selectedLoginMethod) {
      case LoginMethod.email:
        labelText = 'Email';
        hintText = 'Enter your email';
        keyboardType = TextInputType.emailAddress;
        prefix = const Icon(Icons.email_outlined);
        validator = Validators.validateEmail;
        break;
      case LoginMethod.username:
        labelText = 'Username';
        hintText = 'Enter your username';
        keyboardType = TextInputType.text;
        prefix = const Icon(Icons.person_outline);
        validator = _validateUsername;
        break;
      case LoginMethod.phone:
        labelText = 'Phone';
        hintText = 'Enter your phone with country code';
        keyboardType = TextInputType.phone;
        prefix = const Icon(Icons.phone_outlined);
        validator = Validators.validatePhone;
        break;
    }

    return _buildStyledTextField(
      controller: identifierController,
      labelText: labelText,
      hintText: hintText,
      keyboardType: keyboardType,
      textInputAction: TextInputAction.next,
      validator: validator,
      prefix: prefix,
    );
  }

  // Build password field with improved styling
  Widget _buildPasswordField(BuildContext context) => _buildStyledTextField(
    controller: passwordController,
    labelText: 'Password',
    hintText: 'Enter your password',
    obscureText: true,
    textInputAction: TextInputAction.done,
    validator: Validators.validatePassword,
    prefix: const Icon(Icons.lock_outline),
  );

  // Helper method to create styled text fields
  Widget _buildStyledTextField({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction? textInputAction,
    String? Function(String?)? validator,
    Widget? prefix,
    ValueChanged<String>? onSubmitted,
  }) => Theme(
    data: ThemeData(
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        contentPadding: const EdgeInsets.all(16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white30),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.redAccent.withOpacity(0.5)),
        ),
        labelStyle: const TextStyle(color: Colors.white70),
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
      ),
    ),
    child: AppTextField(
      controller: controller,
      labelText: labelText,
      hintText: hintText,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      validator: validator,
      prefix: prefix,
      onSubmitted: onSubmitted,
    ),
  );

  // Username validation helper
  String? _validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Username is required';
    }

    if (value.length < 3) {
      return 'Username must be at least 3 characters';
    }

    final usernameRegex = RegExp(r'^[a-zA-Z0-9_]+$');
    if (!usernameRegex.hasMatch(value)) {
      return 'Username can only contain letters, numbers, and underscores';
    }

    return null;
  }
}

// Login method options
enum LoginMethod { email, username, phone }
