import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:am_auth_ui/am_auth_ui.dart';
import 'package:am_trade_ui/am_trade_ui.dart';

import 'features/shell/app_shell.dart';
import 'core/di/injection.dart';

/// Main Application Widget
class AMApp extends ConsumerWidget {
  const AMApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MultiBlocProvider(
      providers: [
        // Auth Cubit
        BlocProvider<AuthCubit>(
          create: (context) => getIt<AuthCubit>()..checkAuthStatus(),
        ),
        // Theme Cubit
        BlocProvider<ThemeCubit>(
          create: (context) => getIt<ThemeCubit>(),
        ),
        // Feature Flag Cubit
        BlocProvider<FeatureFlagCubit>(
          create: (context) => getIt<FeatureFlagCubit>(),
        ),
      ],
      child: BlocBuilder<ThemeCubit, ThemeState>(
        builder: (context, themeState) {
          return MaterialApp(
            title: 'AM Investment Platform',
            debugShowCheckedModeBanner: false,
            theme: themeState.lightTheme,
            darkTheme: themeState.darkTheme,
            themeMode: themeState.themeMode,
            home: const AppShell(),
            routes: {
              '/home': (context) => const AppShell(),
              '/trade/add': (context) {
                final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>? ?? {};
                return AddTradeWebPage(
                  portfolioId: args['portfolioId'] as String? ?? '',
                  portfolioName: args['portfolioName'] as String?,
                );
              },
            },
          );
        },
      ),
    );
  }
}
