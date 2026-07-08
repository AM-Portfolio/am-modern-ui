import 'package:am_auth_ui/am_auth_ui.dart';
import 'package:am_dashboard_ui/am_dashboard_ui.dart' as dashboard;
import 'package:am_common/am_common.dart' as common;
import 'package:am_subscription_ui/am_subscription_ui.dart' as am_sub;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../features/shell/app_shell.dart';
import 'app_routes.dart';
import 'auth_refresh_listenable.dart';
import 'deferred_routes.dart';
import 'share_url_builder.dart';

GoRouter createAppRouter({
  required AuthCubit authCubit,
  required AuthRefreshListenable refreshListenable,
}) {
  return GoRouter(
    initialLocation: resolveLaunchLocation(),
    overridePlatformDefaultLocation: kIsWeb,
    refreshListenable: refreshListenable,
    redirect: (context, state) {
      final authState = authCubit.state;
      final location = state.matchedLocation;
      final isAuthenticated = authState is Authenticated;
      final authPending = authState is AuthInitial ||
          authState is AuthLoading ||
          authState is AuthRestoreFailed;

      // Browser opens http://localhost:9000/ — no page registered for `/`.
      if (location == '/' || location.isEmpty) {
        if (authPending) return AppRoutes.dashboard;
        return isAuthenticated ? AppRoutes.dashboard : AppRoutes.login;
      }

      // Restoring session — stay on current /app/* URL (avoids login flash on reload).
      if (authPending && AppRoutes.isAuthenticatedAppRoute(location)) {
        return null;
      }

      if (!isAuthenticated && AppRoutes.isAuthenticatedAppRoute(location)) {
        final redirect = Uri.encodeComponent(_redirectTarget(state.uri));
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
              return buildPortfolioRoute(
                portfolioId: portfolioId,
                tab: tab,
                onTabChanged: (slug) => context.go(
                  AppRoutes.portfolioPath(portfolioId, slug),
                ),
                onPortfolioChanged: (id, name) {
                  _patchPortfolioSession(context, id, name);
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
              return buildPortfolioRoute(
                portfolioId: null,
                tab: tab,
                onTabChanged: (slug) =>
                    context.go(AppRoutes.portfolioLegacyTabPath(slug)),
                onPortfolioChanged: (id, name) {
                  _patchPortfolioSession(context, id, name);
                  context.go(AppRoutes.portfolioPath(id, tab));
                },
              );
            },
          ),
          GoRoute(
            path: AppRoutes.tradeDiscovery,
            builder: (context, state) {
              return buildTradeDiscoveryRoute(
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
                  _patchPortfolioSession(context, id, name);
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
              return buildTradePortfolioRoute(
                portfolioId: portfolioId,
                tab: tab,
                onTabChanged: (slug) {
                  if (slug == 'portfolios' && portfolioId.isEmpty) {
                    context.go(AppRoutes.tradeDiscovery);
                    return;
                  }
                  context.go(AppRoutes.tradePath(portfolioId, slug));
                },
                onPortfolioChanged: (id, name) {
                  _patchPortfolioSession(context, id, name);
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
              return buildTradeLegacyTabRoute(
                tab: tab,
                onTabChanged: (slug) =>
                    context.go(AppRoutes.tradeLegacyTabPath(slug)),
                onPortfolioChanged: (id, name) {
                  _patchPortfolioSession(context, id, name);
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
              return buildMarketRoute(
                userId: userId,
                tab: tab,
                onTabChanged: (slug) => context.go(AppRoutes.marketPath(slug)),
              );
            },
          ),
          GoRoute(
            path: AppRoutes.aiChat,
            builder: (context, state) =>
                buildAiChatRoute(userId: _userId(context)),
          ),
          GoRoute(
            path: AppRoutes.lab,
            builder: (context, state) => buildLabRoute(),
          ),
          GoRoute(
            path: AppRoutes.analysis,
            builder: (context, state) =>
                buildAnalysisRoute(userId: _userId(context)),
          ),
          GoRoute(
            path: AppRoutes.docIntel,
            builder: (context, state) =>
                buildDocIntelRoute(userId: _userId(context)),
          ),
          GoRoute(
            path: AppRoutes.profile,
            builder: (context, state) =>
                buildProfileRoute(userId: _userId(context)),
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

/// Browser URL on web reload; dashboard fallback when path is empty or `/`.
String resolveLaunchLocation() {
  if (kIsWeb) {
    final uri = Uri.base;
    final path = uri.path.isEmpty ? '/' : uri.path;
    if (path != '/' && AppRoutes.isAuthenticatedAppRoute(path)) {
      return uri.hasQuery ? '$path?${uri.query}' : path;
    }
    if (path == AppRoutes.login ||
        path == AppRoutes.register ||
        path == AppRoutes.forgotPassword ||
        path == AppRoutes.resetPassword) {
      return uri.hasQuery ? '$path?${uri.query}' : path;
    }
  }
  return AppRoutes.dashboard;
}

String _redirectTarget(Uri uri) {
  final path = uri.path.isEmpty ? '/' : uri.path;
  return uri.hasQuery ? '$path?${uri.query}' : path;
}

void _patchPortfolioSession(BuildContext context, String id, String name) {
  context.selectPortfolio(id, name);
  final authState = context.read<AuthCubit>().state;
  if (authState is Authenticated) {
    common.SessionPersistenceService.instance.patch(
      authState.user.id,
      (s) => s.copyWith(portfolioId: id, portfolioName: name),
    );
  }
}

