import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/auth_cubit.dart';

/// Demo login button widget matching image (1).png
class DemoLoginButtonWidget extends StatelessWidget {
  const DemoLoginButtonWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
              : Colors.white.withValues(alpha: 0.14),
          foregroundColor: isDark ? Colors.white : const Color(0xFF475569),
          side: BorderSide(
            color: isDark ? Colors.white.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.35),
            width: 1.0,
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
                color: isDark ? Colors.white : const Color(0xFF475569),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
