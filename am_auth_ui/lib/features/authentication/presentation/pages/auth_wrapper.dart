import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:am_common/am_common.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import 'login_page.dart';

/// Authentication-aware wrapper that manages authentication state
class AuthWrapper extends StatefulWidget {
  final Widget child;
  final String? loginTitle;

  const AuthWrapper({
    required this.child,
    this.loginTitle,
    super.key,
  });

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    // Check authentication status on app startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AuthCubit>().checkAuthStatus();
    });
  }

  @override
  Widget build(BuildContext context) => BlocBuilder<AuthCubit, AuthState>(
    builder: (context, state) {
      if (state is AuthLoading || state is AuthInitial) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }

      if (state is! Authenticated) {
        return const LoginPage();
      }

      final userId = state.user.id;
      if (userId.isEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          context.read<AuthCubit>().logout();
        });
        return const LoginPage();
      }

      return widget.child;
    },
  );
}

