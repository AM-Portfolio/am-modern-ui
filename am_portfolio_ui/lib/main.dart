import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:am_auth_ui/am_auth_ui.dart' hide SecureStorageService;
import 'package:am_common/am_common.dart' as common;
import 'package:am_common/am_common.dart' show PortfolioSelectionContext;
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

  await common.ConfigService.initialize();

  final analysisUrl = common.ConfigService.config.api.analysis?.baseUrl ?? '';
  final wsUrl = common.ConfigService.config.api.marketData?.wsUrl ?? '';

  common.ServiceRegistry.initialize(
    analysisBaseUrl: analysisUrl,
    wsUrl: wsUrl,
  );

  if (!GetIt.instance.isRegistered<common.SecureStorageService>()) {
    GetIt.instance.registerLazySingleton<common.SecureStorageService>(
      () => common.SecureStorageService(),
    );
  }
  if (!GetIt.instance.isRegistered<common.TelemetryService>()) {
    GetIt.instance.registerLazySingleton<common.TelemetryService>(
      () => common.TelemetryService(),
    );
  }
  if (!GetIt.instance.isRegistered<common.AmStompClient>()) {
    GetIt.instance.registerLazySingleton<common.AmStompClient>(
      () => common.AmStompClient(),
    );
  }

  common.AppLogger.initialize();
  CommonLogger.configure(enabled: true, minLevel: LogLevel.info);

  final stompClient = GetIt.instance<common.AmStompClient>();
  stompClient.configure(url: wsUrl);

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
                redirect: (_, __) => '/portfolio/overview',
              ),
              GoRoute(
                path: '/login',
                builder: (context, state) => AuthWrapper(
                  loginTitle: 'Portfolio Login',
                  child: Container(),
                ),
              ),
              ShellRoute(
                builder: (context, state, child) {
                  return BlocBuilder<AuthCubit, AuthState>(
                    builder: (context, authState) {
                      if (authState is Authenticated) {
                        final token = '';
                        context.read<common.StompConnectionCubit>().updateToken(
                          token,
                        );

                        return GlobalPortfolioWrapper(
                          child: AppShell(
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
                      return PortfolioOverviewWebPage(
                        portfolioId: context.selectedPortfolioId,
                      );
                    },
                  ),
                  GoRoute(
                    path: '/portfolio/holdings',
                    builder: (context, state) {
                      return PortfolioHoldingsWebPage(
                        portfolioId: context.selectedPortfolioId ?? '',
                      );
                    },
                  ),
                  GoRoute(
                    path: '/portfolio/analysis',
                    builder: (context, state) {
                      return PortfolioAnalysisWebPage(
                        portfolioId: context.selectedPortfolioId ?? '',
                      );
                    },
                  ),
                  GoRoute(
                    path: '/portfolio/heatmap',
                    builder: (context, state) {
                      return PortfolioHeatmapWebPage(
                        portfolioId: context.selectedPortfolioId ?? '',
                      );
                    },
                  ),
                  GoRoute(
                    path: '/portfolio/baskets',
                    builder: (context, state) {
                      return PortfolioBasketsWebPage(
                        portfolioId: context.selectedPortfolioId,
                      );
                    },
                  ),
                  GoRoute(
                    path: '/portfolio/basket/preview',
                    builder: (context, state) {
                      final extras = state.extra as Map<String, dynamic>;
                      final seed =
                          extras['seededOpportunity'] ?? extras['opportunity'];
                      return BasketPreviewPage(
                        etfIsin: extras['etfIsin'] as String,
                        portfolioId: extras['portfolioId'] as String,
                        userId: extras['userId'] as String? ?? 'dummy',
                        seededOpportunity: seed as BasketOpportunity?,
                      );
                    },
                  ),
                  GoRoute(
                    path: '/portfolio/basket/creator',
                    builder: (context, state) {
                      final extras = state.extra as Map<String, dynamic>?;
                      if (extras != null) {
                        return ManualBasketCreatorPage(
                          opportunity:
                              extras['opportunity'] as BasketOpportunity,
                          portfolioId: extras['portfolioId'] as String,
                          userId: 'dummy',
                        );
                      }
                      return const Center(
                        child: Text('Basket Creator - No Data'),
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
                return null;
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
