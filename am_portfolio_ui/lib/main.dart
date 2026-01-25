import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:am_auth_ui/am_auth_ui.dart';
import 'package:am_portfolio_ui/features/portfolio/presentation/pages/portfolio_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:am_portfolio_ui/features/basket/presentation/pages/basket_preview_page.dart';
import 'package:am_portfolio_ui/features/basket/presentation/pages/manual_basket_creator_page.dart';
import 'package:am_portfolio_ui/features/basket/domain/models/basket_opportunity.dart';

void main() {
  runApp(
    const ProviderScope(
      child: AmPortfolioStandaloneApp(),
    ),
  );
}

class AmPortfolioStandaloneApp extends ConsumerWidget {
  const AmPortfolioStandaloneApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeCubit>(
          create: (context) => ThemeCubit(ThemeRepository()),
        ),
        BlocProvider<AuthCubit>(
          create: (context) => AuthProviders.createAuthCubit()..checkAuthStatus(),
        ),
      ],
      child: BlocBuilder<ThemeCubit, ThemeState>(
        builder: (context, themeState) {
          final router = GoRouter(
            initialLocation: '/',
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => AuthWrapper(
                  loginTitle: 'Portfolio Login',
                  child: BlocBuilder<AuthCubit, AuthState>(
                    builder: (context, authState) {
                      if (authState is Authenticated) {
                        return PortfolioScreen(
                          userId: authState.user.id,
                        );
                      }
                      return const Scaffold(
                        body: Center(child: CircularProgressIndicator()),
                      );
                    },
                  ),
                ),
              ),
              GoRoute(
                path: '/basket/preview',
                builder: (context, state) {
                  final extras = state.extra as Map<String, dynamic>;
                  return BasketPreviewPage(
                    etfIsin: extras['etfIsin'] as String,
                    userId: extras['userId'] as String,
                    portfolioId: extras['portfolioId'] as String,
                  );
                },
              ),
              GoRoute(
                path: '/basket/creator',
                builder: (context, state) {
                  final extras = state.extra as Map<String, dynamic>;
                  return ManualBasketCreatorPage(
                    opportunity: extras['opportunity'] as BasketOpportunity,
                    userId: extras['userId'] as String,
                    portfolioId: extras['portfolioId'] as String,
                  );
                },
              ),
            ],
          );

          return MaterialApp.router(
            title: 'AM Portfolio UI (Standalone)',
            debugShowCheckedModeBanner: false,
            theme: themeState.lightTheme,
            darkTheme: themeState.darkTheme,
            themeMode: themeState.themeMode,
            routerConfig: router,
          );
        },
      ),
    );
  }
}
