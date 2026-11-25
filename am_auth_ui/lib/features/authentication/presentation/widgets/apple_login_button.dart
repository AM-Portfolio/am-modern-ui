import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../cubit/auth_cubit.dart';

class AppleLoginButton extends StatelessWidget {
  const AppleLoginButton({super.key, required this.isLoading});

  final bool isLoading;

  static bool get isAvailable =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 48,
        width: double.infinity,
        child: SignInWithAppleButton(
          onPressed: isLoading
              ? null
              : () => context.read<AuthCubit>().loginWithApple(),
          style: SignInWithAppleButtonStyle.black,
          borderRadius: const BorderRadius.all(Radius.circular(8)),
        ),
      );
}
