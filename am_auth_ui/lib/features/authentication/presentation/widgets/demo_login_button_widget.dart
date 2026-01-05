import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/auth_cubit.dart';

/// Demo login button widget
class DemoLoginButtonWidget extends StatelessWidget {
  const DemoLoginButtonWidget({super.key});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 48,
    child: OutlinedButton.icon(
      onPressed: () {
        context.read<AuthCubit>().loginWithDemo();
      },
      icon: const Icon(Icons.emoji_emotions),
      label: const Text('🎭 Try Demo Version'),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.blue,
        side: const BorderSide(color: Colors.blue, width: 2),
      ),
    ),
  );
}
