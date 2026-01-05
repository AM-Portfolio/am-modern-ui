import 'package:flutter/material.dart';
import 'package:am_design_system/core/theme/app_colors.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/auth_cubit.dart';

/// Splash screen for checking authentication status
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    // Wait a bit for splash effect
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      // Check authentication status
      context.read<AuthCubit>().checkAuthStatus();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.info,
            AppColors.accentBlue,
            AppColors.primary,
          ],
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo/title
            Text('🌟', style: TextStyle(fontSize: 80)),
            SizedBox(height: 24),
            Text(
              'AM Investment UI',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: context.textPrimary,
              ),
            ),
            SizedBox(height: 48),
            // Loading indicator
            CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    ),
  );
}
