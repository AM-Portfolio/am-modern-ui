import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:am_portfolio_ui/am_portfolio_ui.dart';
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
        child: PortfolioExampleApp(),
      ),
    ),
  );
}

class PortfolioExampleApp extends StatelessWidget {
  const PortfolioExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Portfolio UI Example',
      theme: AppTheme.darkTheme,
      home: AuthWrapper(
        child: BlocBuilder<AuthCubit, AuthState>(
          builder: (context, state) {
            String userId = '';
            if (state is Authenticated) {
              userId = state.user.id;
            }
            // Fallback or loading state might be handled by AuthWrapper, 
            // but we need a valid string for the constructor if it's rendered.
            // AuthWrapper only renders child if authenticated, so state should be Authenticated.
            return PortfolioScreen(
              userId: userId,
            );
          },
        ),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
