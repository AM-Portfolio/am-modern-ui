import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../cubit/auth_cubit.dart';

class AppleLoginButton extends StatelessWidget {
  const AppleLoginButton({
    super.key,
    required this.isLoading,
    this.isBusy = false,
  });

  final bool isLoading;
  final bool isBusy;

  static bool get isAvailable =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 48,
        width: double.infinity,
        child: Opacity(
          opacity: isBusy && !isLoading ? 0.55 : 1,
          child: isLoading
              ? DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Signing in…',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )
              : SignInWithAppleButton(
                  onPressed: isBusy
                      ? null
                      : () => context.read<AuthCubit>().loginWithApple(),
                  text: 'Continue with Apple',
                  height: 48,
                  style: SignInWithAppleButtonStyle.black,
                  borderRadius: BorderRadius.circular(16),
                ),
        ),
      );
}
