import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:am_ai_ui/am_ai_ui.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:get_it/get_it.dart';
import 'package:am_auth_ui/am_auth_ui.dart';

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const AiChatScreen(
        userId: 'demo-user-1',
      ),
    ),
  ],
);

void main() {
  // Initialize DI
  final storage = SecureStorageService();
  if (!GetIt.I.isRegistered<SecureStorageService>()) {
    GetIt.I.registerSingleton<SecureStorageService>(storage);
  }

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
    return MaterialApp.router(
      title: 'AM Finance AI Chat',
      theme: AppTheme.darkTheme,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}
