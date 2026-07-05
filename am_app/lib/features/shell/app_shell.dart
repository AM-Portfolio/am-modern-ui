import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:am_auth_ui/am_auth_ui.dart';
import 'package:get_it/get_it.dart';
import 'package:am_common/am_common.dart' as common;
import 'package:am_portfolio_ui/am_portfolio_ui.dart';

import '../../core/router/app_routes.dart';
import '../../core/router/share_url_builder.dart';

/// Dev mock portfolio IDs (trade mock JSON) must not be restored from session.
bool _isDevMockPortfolioId(String portfolioId) =>
    portfolioId.startsWith('mock-');

/// Main application shell with navigation — hosts [ShellRoute] child pages.
class AppShell extends StatefulWidget {
  const AppShell({required this.child, super.key});

  final Widget child;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  bool _sessionRestored = false;
  bool _shellMarked = false;

  List<_MoreMenuItem> _moreMenuItemsFor({required bool isAdmin}) => [
        const _MoreMenuItem(
            title: 'AI Chat',
            icon: Icons.auto_awesome_rounded,
            path: AppRoutes.aiChat),
        if (isAdmin)
          const _MoreMenuItem(
              title: 'Analysis',
              icon: Icons.analytics_outlined,
              path: AppRoutes.analysis),
        const _MoreMenuItem(
            title: 'Doc Intel',
            icon: Icons.psychology_outlined,
            path: AppRoutes.docIntel),
        const _MoreMenuItem(
            title: 'Subscription',
            icon: Icons.subscriptions_rounded,
            path: AppRoutes.subscription),
        const _MoreMenuItem(
            title: 'Profile',
            icon: Icons.person_rounded,
            path: AppRoutes.profile),
      ];

  List<SidebarItem> _sidebarItemsFor({required bool isAdmin}) => [
        const SidebarItem(
            title: 'Dashboard', icon: Icons.dashboard_rounded),
        const SidebarItem(
            title: 'Portfolio',
            icon: Icons.account_balance_wallet_rounded),
        const SidebarItem(title: 'Trade', icon: Icons.swap_horiz_rounded),
        const SidebarItem(title: 'Market', icon: Icons.show_chart_rounded),
        const SidebarItem(
            title: 'AI Chat', icon: Icons.auto_awesome_rounded),
        if (isAdmin)
          const SidebarItem(
              title: 'Analysis', icon: Icons.analytics_outlined),
        const SidebarItem(
            title: 'Doc Intel', icon: Icons.psychology_outlined),
        const SidebarItem(
            title: 'Subscription', icon: Icons.subscriptions_rounded),
      ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkInitialAuthAndConnect();
      _restoreSessionNav();
    });
  }

  Future<void> _restoreSessionNav() async {
    if (_sessionRestored) return;
    final authState = context.read<AuthCubit>().state;
    if (authState is! Authenticated) return;

    final userId = authState.user.id;
    final current = GoRouterState.of(context).matchedLocation;

    if (ShareUrlBuilder.isReloadableAppRoute(current) ||
        ShareUrlBuilder.isExplicitDeepLink(current)) {
      _sessionRestored = true;
      _syncSessionFromLocation(userId, current);
      return;
    }

    _sessionRestored = true;

    final session =
        await common.SessionPersistenceService.instance.load(userId);
    if (session == null || !mounted) return;

    if (ShareUrlBuilder.isExplicitDeepLink(current)) return;

    var savedPath = AppRoutes.pathForNavTitle(session.globalNav);
    if (savedPath == null) return;

    final portfolioId = session.portfolioId;
    final restoredPortfolioId =
        portfolioId != null && _isDevMockPortfolioId(portfolioId)
            ? null
            : portfolioId;

    if (restoredPortfolioId != null) {
      if (session.globalNav == 'Portfolio') {
        savedPath = AppRoutes.portfolioPath(
          restoredPortfolioId,
          AppRoutes.portfolioTab(session.portfolioTabIndex),
        );
      } else if (session.globalNav == 'Trade') {
        savedPath = AppRoutes.tradePath(restoredPortfolioId, 'portfolios');
      }
    } else if (portfolioId != null && restoredPortfolioId == null) {
      common.SessionPersistenceService.instance.patch(
        userId,
        (s) => s.copyWith(clearPortfolio: true),
      );
    }

    if (current == AppRoutes.dashboard && savedPath != AppRoutes.dashboard) {
      _applyStreamingTabCoordinator(session.globalNav);
      context.go(savedPath);
    }
  }

  void _syncSessionFromLocation(String userId, String location) {
    final nav = AppRoutes.activeNavTitleForLocation(location);
    final portfolioId = ShareUrlBuilder.portfolioIdFromLocation(location);
    final portfolioTab = ShareUrlBuilder.portfolioTabFromLocation(location);

    common.SessionPersistenceService.instance.patch(
      userId,
      (s) => s.copyWith(
        globalNav: nav,
        portfolioId: portfolioId,
        portfolioTabIndex: portfolioTab != null
            ? AppRoutes.portfolioTabIndex(portfolioTab)
            : s.portfolioTabIndex,
        clearPortfolio: portfolioId == null,
      ),
    );
  }

  void _applyStreamingTabCoordinator(String tabTitle) {
    if (!GetIt.instance.isRegistered<common.AmStompClient>()) return;
    if (tabTitle.isEmpty) return;
    common.StreamingTabCoordinator(GetIt.instance<common.AmStompClient>())
        .onTabSelected(tabTitle);
  }

  void _onGlobalNavigate(String title, String userId) {
    final path = AppRoutes.pathForNavTitle(title);
    if (path == null) return;

    _applyStreamingTabCoordinator(title);
    context.go(path);
    common.SessionPersistenceService.instance.patch(
      userId,
      (s) => s.copyWith(globalNav: title, clearBasket: title != 'Portfolio'),
    );
  }

  void _onGlobalPortfolioChanged(String portfolioId, String portfolioName) {
    final authState = context.read<AuthCubit>().state;
    if (authState is! Authenticated) return;

    common.SessionPersistenceService.instance.patch(
      authState.user.id,
      (s) => s.copyWith(
        portfolioId: portfolioId,
        portfolioName: portfolioName,
      ),
    );
  }

  Future<void> _checkInitialAuthAndConnect() async {
    final authCubit = context.read<AuthCubit>();
    final authState = authCubit.state;
    if (authState is Authenticated) {
      common.AppLogger.info(
        'AppShell: Initialized while Authenticated. Triggering STOMP connection...',
      );
      final stompCubit = context.read<common.StompConnectionCubit>();

      stompCubit.onConnected = (userId) {
        common.AppLogger.info('AppShell (Initial): STOMP Connected for $userId');
        if (mounted) _applyStreamingTabCoordinator(_activeNavItem);
      };

      final secureStorage = GetIt.instance<common.SecureStorageService>();
      final token = await secureStorage.getAccessToken();
      if (token == null || token.isEmpty) {
        if (mounted) {
          common.AppLogger.warning(
            'AppShell: Authenticated state but no token in storage. Forcing logout.',
          );
          authCubit.logout();
        }
        return;
      }
      if (mounted) {
        stompCubit.updateToken(token, userId: authState.user.id);
      }
    }
  }

  String get _activeNavItem {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith(AppRoutes.profile)) return '';
    return AppRoutes.activeNavTitleForLocation(location);
  }

  String get _currentLocation => GoRouterState.of(context).matchedLocation;

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<AuthCubit, AuthState>(
          listener: (context, state) async {
            final stompCubit = context.read<common.StompConnectionCubit>();

            if (state is Authenticated) {
              common.AppLogger.info(
                'AppShell: AuthState changed to Authenticated. Connecting STOMP...',
              );

              stompCubit.onConnected = (userId) {
                common.AppLogger.info('AppShell: STOMP Connected for $userId');
                if (context.mounted) {
                  _applyStreamingTabCoordinator(_activeNavItem);
                }
              };

              final secureStorage = GetIt.instance<common.SecureStorageService>();
              final token = await secureStorage.getAccessToken();
              if (token == null || token.isEmpty) {
                if (context.mounted) {
                  common.AppLogger.warning(
                    'AppShell: Authenticated state but no token. Forcing logout.',
                  );
                  context.read<AuthCubit>().logout();
                }
                return;
              }
              if (context.mounted) {
                stompCubit.updateToken(token, userId: state.user.id);
                _restoreSessionNav();
              }
            } else if (state is Unauthenticated) {
              common.AppLogger.info(
                'AppShell: AuthState changed to Unauthenticated. Disconnecting STOMP...',
              );
              stompCubit.onConnected = null;
              stompCubit.updateToken(null);
            }
          },
        ),
      ],
      child: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, authState) {
          final authPending = authState is AuthInitial ||
              authState is AuthLoading ||
              authState is AuthRestoreFailed;

          if (authState is! Authenticated && !authPending) {
            return const SizedBox.shrink();
          }

          if (!_shellMarked && authState is Authenticated) {
            _shellMarked = true;
            common.BootTrace.instance.mark('shell_visible');
          }

          final userId =
              authState is Authenticated ? authState.user.id : '';
          final isAdmin =
              authState is Authenticated && authState.user.isAdmin;
          final isDark = Theme.of(context).brightness == Brightness.dark;

          final shell = LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth > 1100;

              return Scaffold(
                body: Row(
                  children: [
                    if (isDesktop && authState is Authenticated)
                      GlobalSidebar(
                        activeNavItem: _activeNavItem,
                        isDarkMode: isDark,
                        userName: authState.user.displayName,
                        userEmail: authState.user.email,
                        userAvatarUrl: authState.user.photoUrl,
                        moduleShareUrls: AppRoutes.navTitleToDefaultPath,
                        onThemeToggle: () {
                          try {
                            context.read<ThemeCubit>().toggleTheme();
                          } catch (e) {
                            debugPrint('Theme toggle error: $e');
                          }
                        },
                        onLogout: () => context.read<AuthCubit>().logout(),
                        onProfileTap: () => context.go(AppRoutes.profile),
                        onNavigate: (title) => _onGlobalNavigate(title, userId),
                        items: _sidebarItemsFor(isAdmin: isAdmin),
                      ),
                    Expanded(
                      child: authState is Authenticated
                          ? GlobalPortfolioWrapper(
                              streamingTab: _activeNavItem.isEmpty
                                  ? 'Dashboard'
                                  : _activeNavItem,
                              onPortfolioChanged: _onGlobalPortfolioChanged,
                              child: widget.child,
                            )
                          : widget.child,
                    ),
                  ],
                ),
                bottomNavigationBar: !isDesktop && authState is Authenticated
                    ? GlobalBottomNavigation(
                        activeNavItem: _activeNavItem,
                        isDarkMode: isDark,
                        userName: authState.user.displayName,
                        onMenuTap: () =>
                            _showMoreMenu(context, userId, isDark, isAdmin),
                        onNavigate: (title) =>
                            _onGlobalNavigate(title, userId),
                        items: const [
                          SidebarItem(
                              title: 'Dashboard',
                              icon: Icons.dashboard_rounded),
                          SidebarItem(
                              title: 'Portfolio',
                              icon: Icons.account_balance_wallet_rounded),
                          SidebarItem(
                              title: 'Trade',
                              icon: Icons.swap_horiz_rounded),
                          SidebarItem(
                              title: 'Market',
                              icon: Icons.show_chart_rounded),
                          SidebarItem(
                              title: 'Menu',
                              icon: Icons.menu_rounded),
                        ],
                      )
                    : null,
              );
            },
          );

          if (!authPending) return shell;

          return Stack(
            children: [
              shell,
              ColoredBox(
                color: const Color(0xFF0B1120),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(color: Color(0xFF6366F1)),
                      const SizedBox(height: 20),
                      Text(
                        authState is AuthRestoreFailed
                            ? 'Connection issue — retrying session…'
                            : 'Restoring your session…',
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 16,
                        ),
                      ),
                      if (authState is AuthRestoreFailed) ...[
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () =>
                              context.read<AuthCubit>().checkAuthStatus(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showMoreMenu(
    BuildContext context,
    String userId,
    bool isDark,
    bool isAdmin,
  ) {
    final moreMenuItems = _moreMenuItemsFor(isAdmin: isAdmin);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: false,
      builder: (sheetContext) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1a1a2e) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.05),
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      Text(
                        'More',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : Colors.black87,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => Navigator.pop(sheetContext),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: isDark ? Colors.white54 : Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 1.15,
                    ),
                    itemCount: moreMenuItems.length,
                    itemBuilder: (ctx, i) {
                      final item = moreMenuItems[i];
                      final isActive = _currentLocation.startsWith(item.path);
                      final accentColor = _getMoreItemColor(item.title);

                      return GestureDetector(
                        onTap: () {
                          Navigator.pop(sheetContext);
                          context.go(item.path);
                          common.SessionPersistenceService.instance.patch(
                            userId,
                            (s) => s.copyWith(globalNav: item.title),
                          );
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: isActive
                                ? accentColor.withValues(alpha: isDark ? 0.15 : 0.08)
                                : (isDark
                                    ? Colors.white.withValues(alpha: 0.04)
                                    : Colors.grey.shade50),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isActive
                                  ? accentColor.withValues(alpha: 0.3)
                                  : (isDark
                                      ? Colors.white.withValues(alpha: 0.06)
                                      : Colors.grey.shade200),
                              width: isActive ? 1.5 : 1,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: accentColor.withValues(alpha: isDark ? 0.15 : 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  item.icon,
                                  color: accentColor,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                item.title,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                                  color: isActive
                                      ? accentColor
                                      : (isDark ? Colors.white70 : Colors.grey.shade700),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getMoreItemColor(String title) {
    switch (title) {
      case 'AI Chat':
        return const Color(0xFF6C5DD3);
      case 'Analysis':
        return const Color(0xFF0984E3);
      case 'Doc Intel':
        return const Color(0xFF00D2D3);
      case 'Subscription':
        return const Color(0xFFFF9F43);
      case 'Profile':
        return const Color(0xFF8B7EE0);
      default:
        return const Color(0xFF6C5DD3);
    }
  }
}

class _MoreMenuItem {
  const _MoreMenuItem({
    required this.title,
    required this.icon,
    required this.path,
  });

  final String title;
  final IconData icon;
  final String path;
}
