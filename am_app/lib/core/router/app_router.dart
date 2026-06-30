import 'package:am_ai_ui/am_ai_ui.dart';
import 'package:am_analysis_ui/am_analysis_ui.dart';
import 'package:am_auth_ui/am_auth_ui.dart';
import 'package:am_dashboard_ui/am_dashboard_ui.dart' as dashboard;
import 'package:am_diagnostic_ui/am_diagnostic_ui.dart';
import 'package:am_doc_intelligence_ui/am_doc_intelligence_ui.dart';
import 'package:am_market_ui/am_market_ui.dart';
import 'package:am_portfolio_ui/am_portfolio_ui.dart';
import 'package:am_subscription_ui/am_subscription_ui.dart' as am_sub;
import 'package:am_trade_ui/am_trade_ui.dart';
import 'package:am_user_ui/am_user_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../features/shell/app_shell.dart';
import 'app_routes.dart';
import 'auth_refresh_listenable.dart';
import 'share_url_builder.dart';

GoRouter createAppRouter({
  required AuthCubit authCubit,
  required AuthRefreshListenable refreshListenable,
}) {
  return GoRouter(
    initialLocation: AppRoutes.login,
    refreshListenable: refreshListenable,
    redirect: (context, state) {
      final authState = authCubit.state;
      final isAuthenticated = authState is Authenticated;
      final location = state.matchedLocation;

      // Browser opens http://localhost:9000/ — no page registered for `/`.
      if (location == '/' || location.isEmpty) {
        return isAuthenticated ? AppRoutes.dashboard : AppRoutes.login;
      }

      if (!isAuthenticated && AppRoutes.isAuthenticatedAppRoute(location)) {
        final redirect = Uri.encodeComponent(state.uri.toString());
        return '${AppRoutes.login}?redirect=$redirect';
      }

      if (isAuthenticated && location == AppRoutes.login) {
        final target = ShareUrlBuilder.sanitizeRedirect(
          state.uri.queryParameters['redirect'],
        );
        return target ?? AppRoutes.dashboard;
      }

      // Lab is disabled in navigation — block direct URL access.
      if (location == AppRoutes.lab || location.startsWith('${AppRoutes.lab}/')) {
        return AppRoutes.dashboard;
      }

      // Global Analysis module is admin-only.
      if (location == AppRoutes.analysis ||
          location.startsWith('${AppRoutes.analysis}/')) {
        final isAdmin =
            authState is Authenticated && authState.user.isAdmin;
        if (!isAdmin) return AppRoutes.dashboard;
      }

      if (location == AppRoutes.portfolio) {
        return AppRoutes.portfolioLegacyTabPath('overview');
      }
      if (location == AppRoutes.trade) {
        return AppRoutes.tradeDiscovery;
      }
      if (location == AppRoutes.market) {
        return AppRoutes.marketPath('all-indices');
      }

      // Legacy 2-segment portfolio: /app/portfolio/{segment} where segment is a tab slug.
      final portfolioLegacy = _legacyPortfolioTabRedirect(location);
      if (portfolioLegacy != null) return portfolioLegacy;

      // Legacy 2-segment trade tab-only (not discovery).
      final tradeLegacy = _legacyTradeTabRedirect(location);
      if (tradeLegacy != null) return tradeLegacy;

      // 2-segment portfolio path where segment is portfolio ID (not a tab slug).
      final portfolioIdOnly = _portfolioIdOnlyRedirect(location);
      if (portfolioIdOnly != null) return portfolioIdOnly;

      return null;
    },
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 16),
              Text(
                'Page not found: ${state.uri}',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.go(AppRoutes.login),
                child: const Text('Go to login'),
              ),
            ],
          ),
        ),
      ),
    ),
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: AppRoutes.resetPassword,
        builder: (context, state) => const ResetPasswordPage(),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.dashboard,
            builder: (context, state) {
              final userId = _userId(context);
              return dashboard.DashboardScreen(userId: userId);
            },
          ),
          GoRoute(
            path: '${AppRoutes.portfolio}/:portfolioId/:tab',
            builder: (context, state) {
              final portfolioId = state.pathParameters['portfolioId']!;
              final tab = state.pathParameters['tab'] ?? 'overview';
              return PortfolioScreen(
                initialPortfolioId: portfolioId,
                initialTab: tab,
                onTabChanged: (slug) => context.go(
                  AppRoutes.portfolioPath(portfolioId, slug),
                ),
                onPortfolioChanged: (id, name) {
                  final currentTab =
                      ShareUrlBuilder.portfolioTabFromLocation(
                            GoRouterState.of(context).matchedLocation,
                          ) ??
                          tab;
                  context.go(AppRoutes.portfolioPath(id, currentTab));
                },
              );
            },
          ),
          GoRoute(
            path: '${AppRoutes.portfolio}/:tab',
            builder: (context, state) {
              final tab = state.pathParameters['tab'] ?? 'overview';
              return PortfolioScreen(
                initialTab: tab,
                onTabChanged: (slug) =>
                    context.go(AppRoutes.portfolioLegacyTabPath(slug)),
                onPortfolioChanged: (id, name) {
                  context.go(AppRoutes.portfolioPath(id, tab));
                },
              );
            },
          ),
          GoRoute(
            path: AppRoutes.tradeDiscovery,
            builder: (context, state) {
              return TradeResponsiveLayout(
                initialTab: 'portfolios',
                onTabChanged: (slug) {
                  if (slug == 'portfolios') {
                    context.go(AppRoutes.tradeDiscovery);
                    return;
                  }
                  final portfolioId = context.selectedPortfolioId;
                  if (portfolioId != null) {
                    context.go(AppRoutes.tradePath(portfolioId, slug));
                  } else {
                    context.go(AppRoutes.tradeLegacyTabPath(slug));
                  }
                },
                onPortfolioChanged: (id, name) {
                  context.go(AppRoutes.tradePath(id, 'portfolios'));
                },
              );
            },
          ),
          GoRoute(
            path: '${AppRoutes.trade}/:portfolioId/:tab',
            builder: (context, state) {
              final portfolioId = state.pathParameters['portfolioId']!;
              final tab = state.pathParameters['tab'] ?? 'portfolios';
              return TradeResponsiveLayout(
                initialPortfolioId: portfolioId,
                initialTab: tab,
                onTabChanged: (slug) {
                  if (slug == 'portfolios' && portfolioId.isEmpty) {
                    context.go(AppRoutes.tradeDiscovery);
                    return;
                  }
                  context.go(AppRoutes.tradePath(portfolioId, slug));
                },
                onPortfolioChanged: (id, name) {
                  final currentTab = ShareUrlBuilder.tradeTabFromLocation(
                        GoRouterState.of(context).matchedLocation,
                      ) ??
                      tab;
                  context.go(AppRoutes.tradePath(id, currentTab));
                },
              );
            },
          ),
          GoRoute(
            path: '${AppRoutes.trade}/:tab',
            builder: (context, state) {
              final tab = state.pathParameters['tab'] ?? 'portfolios';
              return TradeResponsiveLayout(
                initialTab: tab,
                onTabChanged: (slug) =>
                    context.go(AppRoutes.tradeLegacyTabPath(slug)),
                onPortfolioChanged: (id, name) {
                  context.go(AppRoutes.tradePath(id, tab));
                },
              );
            },
          ),
          GoRoute(
            path: '${AppRoutes.market}/:tab',
            builder: (context, state) {
              final tab = state.pathParameters['tab'] ?? 'all-indices';
              final userId = _userId(context);
              return MarketPage(
                userId: userId,
                initialTab: tab,
                onTabChanged: (slug) => context.go(AppRoutes.marketPath(slug)),
              );
            },
          ),
          GoRoute(
            path: AppRoutes.aiChat,
            builder: (context, state) => AiChatScreen(userId: _userId(context)),
          ),
          GoRoute(
            path: AppRoutes.lab,
            builder: (context, state) => const DiagnosticDashboardPage(),
          ),
          GoRoute(
            path: AppRoutes.analysis,
            builder: (context, state) {
              final userId = _userId(context);
              return AnalysisDashboard(
                entityType: AnalysisEntityType.PORTFOLIO,
                entityId: userId,
                analysisService: RealAnalysisService(),
              );
            },
          ),
          GoRoute(
            path: AppRoutes.docIntel,
            builder: (context, state) =>
                DocIntelligenceScreen(userId: _userId(context)),
          ),
          GoRoute(
            path: AppRoutes.profile,
            builder: (context, state) {
              final authState = context.read<AuthCubit>().state;
              if (authState is Authenticated) {
                return ProfileSettingsPage(
                  userId: authState.user.id,
                  email: authState.user.email,
                  displayName: authState.user.displayName,
                );
              }
              return ProfileSettingsPage(userId: _userId(context));
            },
          ),
          GoRoute(
            path: AppRoutes.subscription,
            builder: (context, state) => BlocProvider<am_sub.SubscriptionCubit>.value(
              value: GetIt.instance<am_sub.SubscriptionCubit>(),
              child: const am_sub.SubscriptionPricingScreen(),
            ),
          ),
        ],
      ),
    ],
  );
}

String? _legacyPortfolioTabRedirect(String location) {
  if (!location.startsWith('${AppRoutes.portfolio}/')) return null;
  final segments = location.split('/').where((s) => s.isNotEmpty).toList();
  if (segments.length != 3 || segments[0] != 'app' || segments[1] != 'portfolio') {
    return null;
  }
  final segment = segments[2];
  if (AppRoutes.isPortfolioTab(segment)) return null;
  return AppRoutes.portfolioPath(segment, 'overview');
}

String? _legacyTradeTabRedirect(String location) {
  if (location == AppRoutes.tradeDiscovery) return null;
  if (!location.startsWith('${AppRoutes.trade}/')) return null;
  final segments = location.split('/').where((s) => s.isNotEmpty).toList();
  if (segments.length != 3 || segments[0] != 'app' || segments[1] != 'trade') {
    return null;
  }
  final segment = segments[2];
  if (AppRoutes.isTradeTab(segment)) return null;
  return AppRoutes.tradePath(segment, 'portfolios');
}

String? _portfolioIdOnlyRedirect(String location) {
  return _legacyPortfolioTabRedirect(location);
}

String _userId(BuildContext context) {
  final authState = context.read<AuthCubit>().state;
  return authState is Authenticated ? authState.user.id : '';
}

