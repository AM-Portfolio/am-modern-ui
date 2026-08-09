import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:am_design_system/core/theme/color_extensions.dart';
import '../cubit/auth_cubit.dart';

/// Demo login button widget matching image (1).png
class DemoLoginButtonWidget extends StatelessWidget {
  const DemoLoginButtonWidget({super.key});

  @override
  Widget build(BuildContext context) {

    return SizedBox(
      width: double.infinity,
      height: 44,
      child: OutlinedButton(
        onPressed: () {
          context.read<AuthCubit>().loginWithDemo();
        },
        style: OutlinedButton.styleFrom(
          backgroundColor: context.colors.surface,
          foregroundColor: context.colors.textPrimary,
          side: BorderSide(
            color: context.colors.border,
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
                color: context.colors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
