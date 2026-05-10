import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:am_auth_ui/am_auth_ui.dart' hide SecureStorageService;
import 'package:am_common/am_common.dart' as common;
import 'package:am_portfolio_ui/features/portfolio/presentation/pages/portfolio_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:am_portfolio_ui/features/basket/presentation/pages/basket_preview_page.dart';
import 'package:am_portfolio_ui/features/basket/presentation/pages/manual_basket_creator_page.dart';
import 'package:get_it/get_it.dart';
import 'package:am_portfolio_ui/features/basket/domain/models/basket_opportunity.dart';
import 'package:am_analysis_ui/am_analysis_ui.dart';

import 'package:am_portfolio_ui/features/portfolio/presentation/widgets/global_portfolio_wrapper.dart';
import 'package:am_portfolio_ui/features/portfolio/presentation/web/app_shell.dart';
import 'package:am_portfolio_ui/features/portfolio/presentation/web/pages/portfolio_overview_web_page.dart';
import 'package:am_portfolio_ui/features/portfolio/presentation/web/pages/portfolio_holdings_web_page.dart';
import 'package:am_portfolio_ui/features/portfolio/presentation/web/pages/portfolio_analysis_web_page.dart';
import 'package:am_portfolio_ui/features/portfolio/presentation/web/pages/portfolio_baskets_web_page.dart';
import 'package:am_portfolio_ui/features/portfolio/presentation/web/pages/portfolio_heatmap_web_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize ConfigService (required by many downstream services)
  await common.ConfigService.initialize();

  // Service Locator (DI) Setup
  GetIt.instance.registerLazySingleton<common.SecureStorageService>(
    () => common.SecureStorageService(),
  );
  GetIt.instance.registerLazySingleton<common.AmStompClient>(
    () => common.AmStompClient(),
  );

  // Initialize Logger
  common.AppLogger.initialize();
  // Override to INFO as requested
  CommonLogger.configure(enabled: true, minLevel: LogLevel.info);

  // Initialize WebSocket Client
  final stompClient = GetIt.instance<common.AmStompClient>();
  // Use raw WebSocket endpoint (no SockJS) for better compatibility with stomp_dart_client
  final wsUrl = common.ConfigService.config.api.marketData?.wsUrl ?? 'ws://localhost:8091/ws-gateway-raw';
  stompClient.configure(url: wsUrl);
  // Connect will be handled by GlobalPortfolioWrapper after authentication

  // FORCE ANALYSIS CONFIG TO USE LOCAL DOCKER
  // Port 8061 is mapped to the analysis service in your docker-compose.yml
  final analysisUrl = common.ConfigService.config.api.analysis?.baseUrl ?? 'http://localhost:8061';
  AnalysisConfig.instance.setBaseUrl(analysisUrl);

  runApp(const ProviderScope(child: AmPortfolioStandaloneApp()));
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
          create: (context) =>
              AuthProviders.createAuthCubit()..checkAuthStatus(),
        ),
        BlocProvider<FeatureFlagCubit>(create: (context) => FeatureFlagCubit()),
        BlocProvider<common.StompConnectionCubit>(
          create: (context) => common.StompConnectionCubit(
            stompClient: GetIt.instance<common.AmStompClient>(),
          ),
        ),
      ],
      child: BlocBuilder<ThemeCubit, ThemeState>(
        builder: (context, themeState) {
          final router = GoRouter(
            initialLocation: '/portfolio/overview',
            routes: [
              GoRoute(
                path: '/',
                redirect: (_, __) =>
                    '/portfolio/overview', // Redirect root to dashboard
              ),
              GoRoute(
                path: '/login',
                builder: (context, state) => AuthWrapper(
                  loginTitle: 'Portfolio Login',
                  child:
                      Container(), // Logic is controlled by AuthWrapper redirecting if authenticated?
                  // Actually AuthWrapper in this repo seems to be a wrapper that SHOWS login if not auth, or child if auth.
                  // But usually with GoRouter we use redirect logic.
                  // For simplicity in this specific "Wrap" pattern:
                ),
              ),

              // Shell Route for Authenticated App
              ShellRoute(
                builder: (context, state, child) {
                  return BlocBuilder<AuthCubit, AuthState>(
                    builder: (context, authState) {
                      if (authState is Authenticated) {
                        // Connect WebSocket when authenticated
                        final token = authState
                            .token; // Assume token exists in Authenticated state
                        context.read<common.StompConnectionCubit>().updateToken(
                          token,
                          userId: authState.user.id,
                        );

                        return GlobalPortfolioWrapper(
                          userId: authState.user.id,
                          child: AppShell(
                            userId: authState.user.id,
                            onLogout: () {
                              context.read<AuthCubit>().logout();
                              context
                                  .read<common.StompConnectionCubit>()
                                  .updateToken(null);
                            },
                            child: child,
                          ),
                        );
                      } else {
                        return AuthWrapper(
                          loginTitle: 'Portfolio Login',
                          child: const Scaffold(
                            body: Center(child: CircularProgressIndicator()),
                          ),
                        );
                      }
                    },
                  );
                },
                routes: [
                  GoRoute(
                    path: '/portfolio/overview',
                    builder: (context, state) {
                      final authState = context.read<AuthCubit>().state;
                      // We can assume authState is Authenticated because of Shell logic, but safe to check or cast if needed.
                      // Actually cleaner to get userId passed down or from context if available.
                      // ShellRoute builder verifies auth.
                      final userId = (authState as Authenticated).user.id;

                      return PortfolioOverviewWebPage(
                        userId: userId,
                        portfolioId: context.selectedPortfolioId ?? userId,
                      );
                    },
                  ),
                  GoRoute(
                    path: '/portfolio/holdings',
                    builder: (context, state) {
                      final userId =
                          (context.read<AuthCubit>().state as Authenticated)
                              .user
                              .id;
                      return PortfolioHoldingsWebPage(
                        userId: userId,
                        portfolioId: context.selectedPortfolioId ?? userId,
                      );
                    },
                  ),
                  GoRoute(
                    path: '/portfolio/analysis',
                    builder: (context, state) {
                      final userId =
                          (context.read<AuthCubit>().state as Authenticated)
                              .user
                              .id;
                      return PortfolioAnalysisWebPage(
                        userId: userId,
                        portfolioId: context.selectedPortfolioId ?? userId,
                      );
                    },
                  ),
                  GoRoute(
                    path: '/portfolio/heatmap',
                    builder: (context, state) {
                      final userId =
                          (context.read<AuthCubit>().state as Authenticated)
                              .user
                              .id;
                      return PortfolioHeatmapWebPage(
                        userId: userId,
                        portfolioId: context.selectedPortfolioId ?? userId,
                      );
                    },
                  ),

                  GoRoute(
                    path: '/portfolio/baskets',
                    builder: (context, state) {
                      final userId =
                          (context.read<AuthCubit>().state as Authenticated)
                              .user
                              .id;
                      return PortfolioBasketsWebPage(
                        userId: userId,
                        portfolioId: context.selectedPortfolioId ?? userId,
                      );
                    },
                  ),
                  // Basket Routes
                  GoRoute(
                    path: '/portfolio/basket/preview',
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
                    path: '/portfolio/basket/creator',
                    builder: (context, state) {
                      // Handle nullable extras for direct access
                      final extras = state.extra as Map<String, dynamic>?;
                      if (extras != null) {
                        return ManualBasketCreatorPage(
                          opportunity:
                              extras['opportunity'] as BasketOpportunity,
                          userId: extras['userId'] as String,
                          portfolioId: extras['portfolioId'] as String,
                        );
                      }
                      return const Center(
                        child: Text("Basket Creator - No Data"),
                      );
                    },
                  ),
                ],
              ),
            ],
            redirect: (context, state) {
              final authState = context.read<AuthCubit>().state;
              final isLoggingIn = state.uri.toString() == '/login';

              if (authState is! Authenticated && !isLoggingIn) {
                // Try to check auth status if unknown?
                // AuthCubit checks on create.
                // If unauthenticated, go to login (which shows AuthWrapper login screen)
                return null; // AuthWrapper handles the UI for unauthenticated state
              }

              return null;
            },
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

class PortfolioPlaceholderPage extends StatelessWidget {
  final String title;
  const PortfolioPlaceholderPage({required this.title, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text('Content for $title')),
    );
  }
}
