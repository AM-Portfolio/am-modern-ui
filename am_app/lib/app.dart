import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:am_auth_ui/am_auth_ui.dart';
import 'package:am_common/am_common.dart' as common;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';

import 'features/shell/app_shell.dart';
import 'core/di/injection.dart';
import 'package:am_trade_ui/am_trade_ui.dart';

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
        // STOMP Connection Cubit (Infrastructure)
        BlocProvider<common.StompConnectionCubit>(
          create: (context) => getIt<common.StompConnectionCubit>(),
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
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              FlutterQuillLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en', 'US'),
            ],
            home: BlocListener<AuthCubit, AuthState>(
              listenWhen: (prev, curr) => curr is Authenticated,
              listener: (context, state) {
                if (state is Authenticated) {
                  common.SessionPersistenceService.instance
                      .load(state.user.id);
                }
              },
              child: const AppShell(),
            ),
            routes: {
              '/home': (context) => const AppShell(),
              '/register': (context) => const RegisterPage(),
              '/forgot-password': (context) => const ForgotPasswordPage(),
              '/reset-password': (context) => const ResetPasswordPage(),
            },
            onGenerateRoute: (settings) {
              if (settings.name == '/trade/add') {
                final args = settings.arguments as Map<String, dynamic>?;
                final portfolioId = args?['portfolioId'] as String?;
                final portfolioName = args?['portfolioName'] as String?;

                if (portfolioId == null) {
                   return MaterialPageRoute(
                    builder: (context) => const Scaffold(
                      body: Center(child: Text('Error: Portfolio ID is required')),
                    ),
                  );
                }

                return MaterialPageRoute(
                  builder: (context) => BlocProvider<TradeControllerCubit>(
                    create: (context) => getIt<TradeControllerCubit>(),
                    child: AddTradeWebPage(
                      portfolioId: portfolioId,
                      portfolioName: portfolioName,
                    ),
                  ),
                );
              }
              return null;
            },
          );
        },
      ),
    );
  }
}
