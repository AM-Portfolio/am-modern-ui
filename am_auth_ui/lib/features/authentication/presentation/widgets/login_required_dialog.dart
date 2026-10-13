import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import '../../../../core/utils/auth_redirect.dart';

/// Login / Cancel dialog for gated actions (Paper, Chart, etc.).
///
/// Cancel dismisses without navigating. Login goes to `/login?redirect=…`.
Future<void> showLoginRequiredDialog(
  BuildContext context, {
  required String redirectPath,
  String title = 'Sign in required',
  String? message,
}) async {
  final goLogin = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) {
      return AlertDialog(
        title: Text(title),
        content: Text(
          message ??
              'Sign in to continue. You can cancel to stay on this page.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Login'),
          ),
        ],
      );
    },
  );

  if (goLogin == true && context.mounted) {
    final uri = Uri.tryParse(redirectPath);
    final path = uri?.path ?? redirectPath;
    final companions = uri?.queryParameters ?? const <String, String>{};
    context.go(
      AuthRedirect.loginLocation(appPath: path, companionQuery: companions),
    );
  }
}

/// Runs [onAuthenticated] if signed in; otherwise shows [showLoginRequiredDialog].
Future<bool> requireAuthThen(
  BuildContext context, {
  required String redirectPath,
  required VoidCallback onAuthenticated,
  String title = 'Sign in required',
  String? message,
}) async {
  final auth = context.read<AuthCubit>().state;
  if (auth is Authenticated) {
    onAuthenticated();
    return true;
  }
  await showLoginRequiredDialog(
    context,
    redirectPath: redirectPath,
    title: title,
    message: message,
  );
  return false;
}
