import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:am_auth_ui/am_auth_ui.dart';
import 'package:get_it/get_it.dart';
import 'package:am_common/am_common.dart' as common;

import '../../core/navigation/cross_module_section_sequence.dart';
import '../../core/navigation/cross_section_swipe_host.dart';
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

class _AppShellState extends State<AppShell> with SingleTickerProviderStateMixin {
  bool _sessionRestored = false;
  bool _shellMarked = false;
  bool _portfolioSeeded = false;
  String _lastRecordedLocation = '';
  final List<String> _history = [];

  late final AnimationController _bottomNavController;
  late final Animation<double> _bottomNavFactor;
  bool _wantBottomNav = true;
  double _bottomNavScrollAccum = 0;
  static const double _bottomNavScrollThreshold = 12;
  Timer? _bottomNavHideTimer;

  @override
  void initState() {
    super.initState();
    _bottomNavController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
      reverseDuration: const Duration(milliseconds: 250),
      value: 1.0,
    );
    final bottomNavCurve = CurvedAnimation(
      parent: _bottomNavController,
      curve: Curves.elasticOut,
      reverseCurve: Curves.easeInBack,
    );
    _bottomNavFactor = Tween<double>(begin: 0.0, end: 1.0).animate(bottomNavCurve);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkInitialAuthAndConnect();
      _restoreSessionNav();
      _seedPortfolioSelectionFromSession();
    });
    
    _showBottomNavWithIdleHide();
  }

  @override
  void dispose() {
    _bottomNavHideTimer?.cancel();
    _bottomNavController.dispose();
    super.dispose();
  }

  void _setBottomNavVisible(bool visible) {
    if (_wantBottomNav == visible) return;
    _wantBottomNav = visible;
    _bottomNavScrollAccum = 0;
    if (visible) {
      _bottomNavController.forward();
    } else {
      _bottomNavController.reverse();
    }
  }

  void _showBottomNavWithIdleHide() {
    _bottomNavHideTimer?.cancel();
    _setBottomNavVisible(true);
    _bottomNavHideTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) _setBottomNavVisible(false);
    });
  }

  /// Scroll down past threshold → hide; scroll up → show (+ idle auto-hide).
  bool _handleBottomNavScroll(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) return false;
    if (notification is! ScrollUpdateNotification) return false;

    final delta = notification.scrollDelta ?? 0.0;
    if (delta == 0) return false;

    if (delta > 0) {
      // Content moving up = finger scrolling down → hide bar.
      _bottomNavScrollAccum += delta;
      if (_bottomNavScrollAccum >= _bottomNavScrollThreshold) {
        _bottomNavHideTimer?.cancel();
        _setBottomNavVisible(false);
        _bottomNavScrollAccum = 0;
      }
    } else {
      // Scrolling up → reveal bar.
      _bottomNavScrollAccum += delta;
      if (_bottomNavScrollAccum.abs() >= _bottomNavScrollThreshold) {
        _showBottomNavWithIdleHide();
        _bottomNavScrollAccum = 0;
      }
    }
    return false;
  }

  void _updateHistory(String currentLocation) {
    if (currentLocation != _lastRecordedLocation) {
      _lastRecordedLocation = currentLocation;
      // Reveal bottom nav whenever the route changes.
      if (!_wantBottomNav) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _showBottomNavWithIdleHide();
        });
      }
      if (_history.contains(currentLocation)) {
        final index = _history.indexOf(currentLocation);
        _history.removeRange(index + 1, _history.length);
      } else {
        _history.add(currentLocation);
      }
    }
  }

  List<SidebarItem> _sidebarItemsFor({required bool isAdmin}) => [
        const SidebarItem(
            title: 'Dashboard', icon: Icons.dashboard_rounded),
        const SidebarItem(
            title: 'Portfolio',
            icon: Icons.account_balance_wallet_rounded),
        const SidebarItem(title: 'Trade', icon: Icons.swap_horiz_rounded),
        const SidebarItem(title: 'Market', icon: Icons.show_chart_rounded),
        if (isAdmin)
          const SidebarItem(
              title: 'AI Chat', icon: Icons.auto_awesome_rounded),
        if (isAdmin)
          const SidebarItem(
              title: 'Analysis', icon: Icons.analytics_outlined),
        const SidebarItem(
            title: 'Doc Intel', icon: Icons.psychology_outlined),
      ];

  Future<void> _seedPortfolioSelectionFromSession() async {
    if (_portfolioSeeded) return;
    final authState = context.read<AuthCubit>().state;
    if (authState is! Authenticated) return;
    _portfolioSeeded = true;

    final session =
        await common.SessionPersistenceService.instance.load(authState.user.id);
    if (session?.portfolioId == null || !mounted) return;

    final portfolioId = session!.portfolioId!;
    if (_isDevMockPortfolioId(portfolioId)) return;

    common.PortfolioSelectionScope.maybeStateOf(context)?.seedSelection(
      portfolioId,
      session.portfolioName,
    );
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

    if (portfolioId != null) {
      common.PortfolioSelectionScope.maybeStateOf(context)
          ?.seedSelection(portfolioId, null);
    }

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

    _showBottomNavWithIdleHide();
    _applyStreamingTabCoordinator(title);
    context.go(path);
    common.SessionPersistenceService.instance.patch(
      userId,
      (s) => s.copyWith(globalNav: title, clearBasket: title != 'Portfolio'),
    );
  }

  String? _resolveSwipePortfolioId() {
    final fromUrl =
        ShareUrlBuilder.portfolioIdFromLocation(_currentLocation);
    if (fromUrl != null && fromUrl.isNotEmpty) return fromUrl;
    final cached = common.SessionPersistenceService.instance.cached?.portfolioId;
    if (cached != null &&
        cached.isNotEmpty &&
        !_isDevMockPortfolioId(cached)) {
      return cached;
    }
    return null;
  }

  void _goSwipePath(String path, String userId) {
    _showBottomNavWithIdleHide();
    final navTitle = AppRoutes.activeNavTitleForLocation(path);
    _applyStreamingTabCoordinator(navTitle);
    context.go(path);
    common.SessionPersistenceService.instance.patch(
      userId,
      (s) => s.copyWith(
        globalNav: navTitle,
        clearBasket: navTitle != 'Portfolio',
      ),
    );
  }

  void _onCrossSectionNext(String userId) {
    final next = CrossModuleSectionSequence.nextPath(
      _currentLocation,
      portfolioId: _resolveSwipePortfolioId(),
    );
    if (next == null) return;
    _goSwipePath(next, userId);
  }

  void _onCrossSectionPrevious(String userId) {
    final prev = CrossModuleSectionSequence.previousPath(
      _currentLocation,
      portfolioId: _resolveSwipePortfolioId(),
    );
    if (prev == null) return;
    _goSwipePath(prev, userId);
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
                _portfolioSeeded = false;
                _restoreSessionNav();
                _seedPortfolioSelectionFromSession();
              }
            } else if (state is Unauthenticated) {
              _portfolioSeeded = false;
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

          final currentLocation = GoRouterState.of(context).matchedLocation;
          _updateHistory(currentLocation);

          final shell = LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth > 1100;

              return PopScope(
                canPop: _history.length <= 1,
                onPopInvokedWithResult: (didPop, result) {
                  if (didPop) return;
                  if (_history.length > 1) {
                    _history.removeLast(); // Remove current location
                    final previousLocation = _history.last;
                    
                    final previousTitle = AppRoutes.activeNavTitleForLocation(previousLocation);
                    _applyStreamingTabCoordinator(previousTitle);
                    
                    context.go(previousLocation);
                    
                    common.SessionPersistenceService.instance.patch(
                      userId,
                      (s) => s.copyWith(
                        globalNav: previousTitle.isEmpty ? 'Dashboard' : previousTitle,
                      ),
                    );
                  }
                },
                child: Scaffold(
                  // Body draws under the floating overlay nav — no reserved slot.
                  extendBody: !isDesktop,
                  body: Stack(
                    children: [
                      Row(
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
                              onLogout: () =>
                                  context.read<AuthCubit>().logout(),
                              onProfileTap: () =>
                                  context.go(AppRoutes.profile),
                              onNavigate: (title) =>
                                  _onGlobalNavigate(title, userId),
                              items: _sidebarItemsFor(isAdmin: isAdmin),
                            ),
                          Expanded(
                            child: NotificationListener<ScrollNotification>(
                              onNotification: isDesktop
                                  ? (_) => false
                                  : _handleBottomNavScroll,
                              child: authState is Authenticated
                                  ? common.CrossSectionNavScope(
                                      controller:
                                          common.CrossSectionNavController(
                                        goNextModule: () =>
                                            _onCrossSectionNext(userId),
                                        goPreviousModule: () =>
                                            _onCrossSectionPrevious(userId),
                                      ),
                                      child: common.PortfolioSelectionScope(
                                        child: isDesktop
                                            ? widget.child
                                            : CrossSectionSwipeHost(
                                                onNext: () =>
                                                    _onCrossSectionNext(
                                                        userId),
                                                onPrevious: () =>
                                                    _onCrossSectionPrevious(
                                                        userId),
                                                child: widget.child,
                                              ),
                                      ),
                                    )
                                  : widget.child,
                            ),
                          ),
                        ],
                      ),
                      if (!isDesktop && authState is Authenticated)
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: AnimatedBuilder(
                            animation: _bottomNavController,
                            builder: (context, child) {
                              final visible =
                                  _bottomNavController.value > 0.01;
                              return IgnorePointer(
                                ignoring: !visible,
                                child: child,
                              );
                            },
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, 1.15),
                                end: Offset.zero,
                              ).animate(_bottomNavFactor),
                              child: FadeTransition(
                                opacity: _bottomNavFactor,
                                child: GlobalBottomNavigation(
                                  activeNavItem: _activeNavItem,
                                  isDarkMode: isDark,
                                  userName: authState.user.displayName,
                                  visibleCount: 4,
                                  onNavigate: (title) =>
                                      _onGlobalNavigate(title, userId),
                                  items: [
                                    const SidebarItem(
                                      title: 'Dashboard',
                                      icon: Icons.dashboard_rounded,
                                    ),
                                    const SidebarItem(
                                      title: 'Portfolio',
                                      icon: Icons
                                          .account_balance_wallet_rounded,
                                    ),
                                    const SidebarItem(
                                      title: 'Trade',
                                      icon: Icons.swap_horiz_rounded,
                                    ),
                                    const SidebarItem(
                                      title: 'Market',
                                      icon: Icons.show_chart_rounded,
                                    ),
                                    const SidebarItem(
                                      title: 'Doc Intel',
                                      icon: Icons.psychology_outlined,
                                    ),
                                    const SidebarItem(
                                      title: 'Profile',
                                      icon: Icons.person_rounded,
                                    ),
                                    if (isAdmin) ...[
                                      const SidebarItem(
                                        title: 'AI Chat',
                                        icon: Icons.auto_awesome_rounded,
                                      ),
                                      const SidebarItem(
                                        title: 'Analysis',
                                        icon: Icons.analytics_outlined,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
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
}
