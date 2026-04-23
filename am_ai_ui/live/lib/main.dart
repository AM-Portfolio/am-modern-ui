import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:am_ai_ui/am_ai_ui.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:get_it/get_it.dart';
import 'package:am_auth_ui/am_auth_ui.dart';

void main() {
  // Initialize DI
  final storage = SecureStorageService();
  GetIt.I.registerSingleton<SecureStorageService>(storage);

  runApp(
    MultiBlocProvider(
      providers: [
        ...AuthProviders.providers,
        BlocProvider<ThemeCubit>(
          create: (context) => ThemeCubit(ThemeRepository()),
        ),
      ],
      child: const ProviderScope(
        child: AIChatExampleApp(),
      ),
    ),
  );
}

class AIChatExampleApp extends StatelessWidget {
  const AIChatExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Chat UI Example',
      theme: AppTheme.darkTheme,
      home: AuthWrapper(
        child: BlocBuilder<AuthCubit, AuthState>(
          builder: (context, state) {
            String userId = '';
            if (state is Authenticated) {
              userId = state.user.id;
            }
            // Using AIChatScreen as the home
            return AIChatScreen(
              userId: userId,
            );
          },
        ),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
