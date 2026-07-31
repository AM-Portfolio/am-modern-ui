import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/auth_cubit.dart';

/// Demo login button widget matching image (1).png
class DemoLoginButtonWidget extends StatelessWidget {
  const DemoLoginButtonWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const primaryIndigo = Color(0xFF6366F1);

    return SizedBox(
      width: double.infinity,
      height: 44,
      child: OutlinedButton(
        onPressed: () {
          context.read<AuthCubit>().loginWithDemo();
        },
        style: OutlinedButton.styleFrom(
          backgroundColor: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFE4E8FF).withValues(alpha: 0.50),
          foregroundColor: isDark ? Colors.white : primaryIndigo,
          side: BorderSide(
            color: isDark ? Colors.white.withValues(alpha: 0.4) : primaryIndigo.withValues(alpha: 0.70),
            width: 1.2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('😊 🎭 ', style: TextStyle(fontSize: 14)),
            Text(
              'Try Demo Version',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : primaryIndigo,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
