import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/auth_cubit.dart';
import 'package:am_design_system/core/utils/validators.dart';

/// Email login form widget
class EmailLoginFormWidget extends StatefulWidget {
  final bool isCompact;

  const EmailLoginFormWidget({
    super.key,
    this.isCompact = false,
  });

  @override
  State<EmailLoginFormWidget> createState() => _EmailLoginFormWidgetState();
}

class _EmailLoginFormWidgetState extends State<EmailLoginFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthCubit>().loginWithEmail(
            _emailController.text.trim(),
            _passwordController.text,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Email field
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'Enter your email',
              prefixIcon: Icon(Icons.email_outlined),
              border: OutlineInputBorder(),
            ),
            validator: (value) => Validators.validateEmail(value),
          ),
          const SizedBox(height: 20),

          // Password field
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Password',
              hintText: 'Enter your password',
              prefixIcon: Icon(Icons.lock_outline),
              border: OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            validator: (value) => Validators.validatePassword(value),
          ),
          const SizedBox(height: 32),

          // Login button
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _handleLogin,
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                '🚀 Sign In',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
