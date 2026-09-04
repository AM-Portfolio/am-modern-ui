import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:am_design_system/core/theme/color_extensions.dart';

import '../../../../di/auth_providers.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';

class AppLockScreen extends StatefulWidget {
  const AppLockScreen({super.key});

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> {
  bool _unlocking = false;
  String? _error;
  int _failedAttempts = 0;

  Future<void> _unlock() async {
    setState(() {
      _unlocking = true;
      _error = null;
    });

    final unlocked = await AuthProviders.appLockService.unlock();
    if (!mounted) return;

    if (unlocked) {
      await context.read<AuthCubit>().checkAuthStatus();
      if (!mounted) return;
      final authState = context.read<AuthCubit>().state;
      if (authState is Authenticated) {
        context.go('/app/dashboard');
      } else {
        context.go('/login');
      }
      return;
    }

    setState(() {
      _unlocking = false;
      _failedAttempts += 1;
      _error = _failedAttempts >= 3
          ? 'Too many failed attempts. Please sign in again.'
          : 'Unlock failed. Try again or sign in with password.';
    });

    if (_failedAttempts >= 3) {
      await context.read<AuthCubit>().logout();
      if (mounted) context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 64,
                  color: context.colors.actionPrimaryBg,
                ),
                const SizedBox(height: 24),
                Text(
                  'Unlock AM',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: context.colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Use biometrics or device PIN to continue',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: context.colors.textSecondary),
                ),
                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: _unlocking ? null : _unlock,
                  icon: _unlocking
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.fingerprint),
                  label: Text(_unlocking ? 'Unlocking…' : 'Unlock'),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: context.colors.statusError),
                  ),
                ],
                TextButton(
                  onPressed: () {
                    context.read<AuthCubit>().logout();
                    context.go('/login');
                  },
                  child: const Text('Sign in with password'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
