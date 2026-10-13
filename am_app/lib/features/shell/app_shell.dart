import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:am_auth_ui/am_auth_ui.dart';
import 'package:get_it/get_it.dart';
import 'package:am_common/am_common.dart' as common;
import 'package:am_library/am_library.dart';
import 'package:am_subscription_ui/am_subscription_ui.dart' as am_sub;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/navigation/cross_module_section_sequence.dart';
import '../../core/navigation/cross_section_swipe_host.dart';
import '../../core/router/app_routes.dart';
import '../../core/router/share_url_builder.dart';
import '../search/search_context.dart';
import '../search/search_context_registry.dart';
import '../search/search_discovery_hint.dart';
import '../search/unified_search_engine.dart';
import 'global_add_action_request.dart';

part 'shell_nav.dart';
part 'shell_session.dart';
part 'shell_bottom_nav_chrome.dart';
part 'shell_security_alerts.dart';
part 'shell_global_add.dart';
part 'shell_search.dart';
part 'shell_sidebar_avatar.dart';
part 'shell_layout.dart';

/// Main application shell with navigation — hosts [ShellRoute] child pages.
class SearchIntent extends Intent {}

class AppShell extends StatefulWidget {
  const AppShell({required this.child, super.key});

  final Widget child;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell>
    with
        SingleTickerProviderStateMixin,
        ShellNav,
        ShellSessionOps,
        ShellBottomNavChrome,
        ShellSecurityAlerts,
        ShellGlobalAdd,
        ShellSearchOps,
        ShellLayout {
  bool _shellMarked = false;

  @override
  void initState() {
    super.initState();
    common.GlobalSearchBridge.open = _showSearch;
    _initBottomNavChrome();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkInitialAuthAndConnect();
      _restoreSessionNav();
      _seedPortfolioSelectionFromSession();
      _startSecurityAlertsIfWeb();
      _listenToFeatureFlagChanges();
      // At top of initial page → show bottom nav for 3s.
      if (mounted) _showBottomNavWithIdleHide();
    });
  }

  @override
  void dispose() {
    _disposeSecurityAlerts();
    _disposeSearch();
    _disposeBottomNavChrome();
    _marketGateSubscription?.cancel();
    _marketGateSubscription = null;
    super.dispose();
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
        unawaited(common.UserAvatarStore.instance.loadForUser(authState.user.id));
        unawaited(_startMarketStreamingGate());
        unawaited(_syncFeatureFlagAttributes(authState.user.id));
        unawaited(
          am_sub.ReferralIntroHost.maybeShow(context, authState.user.id),
        );
      }
    }
  }

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
                unawaited(
                  common.UserAvatarStore.instance.loadForUser(state.user.id),
                );
                unawaited(_startMarketStreamingGate());
                unawaited(_syncFeatureFlagAttributes(state.user.id));
                unawaited(
                  am_sub.ReferralIntroHost.maybeShow(context, state.user.id),
                );
              }
            } else if (state is Unauthenticated) {
              _portfolioSeeded = false;
              common.AppLogger.info(
                'AppShell: AuthState changed to Unauthenticated. Disconnecting STOMP...',
              );
              _resetMarketStreamingGate();
              unawaited(_clearFeatureFlagAttributes());
              stompCubit.onConnected = null;
              stompCubit.updateToken(null);
            }
          },
        ),
        BlocListener<FeatureFlagCubit, FeatureFlagState>(
          listener: (context, state) {
            if (!_isSecurityAlertBannerEnabled) {
              _securityAlertHideTimer?.cancel();
              if (kIsWeb) {
                AuthProviders.securityAlertService.stop();
              }
              if (_securityAlert != null) {
                setState(() => _securityAlert = null);
              }
            } else {
              _startSecurityAlertsIfWeb();
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

          // AI chat + soft keyboard: keep floating nav hidden for the session.
          final aiChatKeyboardOpen =
              currentLocation.startsWith(AppRoutes.aiChat) &&
                  MediaQuery.viewInsetsOf(context).bottom > 0;
          if (aiChatKeyboardOpen && _wantBottomNav) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              _bottomNavHideTimer?.cancel();
              _setBottomNavVisible(false);
            });
          }

          final shell = LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = BrowserZoomScope.layoutWidthOf(context) > 1100;

              return PopScope(
                canPop: _history.length <= 1,
                onPopInvokedWithResult: (didPop, result) {
                  if (didPop) return;
                  if (_history.length > 1) {
                    _history.removeLast();
                    final previousLocation = _history.last;

                    final previousTitle =
                        AppRoutes.activeNavTitleForLocation(previousLocation);
                    _applyStreamingTabCoordinator(previousTitle);

                    context.go(previousLocation);

                    common.SessionPersistenceService.instance.patch(
                      userId,
                      (s) => s.copyWith(
                        globalNav: previousTitle.isEmpty
                            ? 'Dashboard'
                            : previousTitle,
                      ),
                    );
                  }
                },
                child: common.MobileSearchScope(
                  getItems: () => _seedActionItems(context),
                  searchOpen: _mobileSearchOpen,
                  openGlobalSearch: _showSearch,
                  liveSearch: _liveSearchQuery,
                  hintText: SearchContextRegistry.hintFor(_searchContext),
                  bannerTitle:
                      SearchContextRegistry.copyFor(_searchContext).bannerTitle,
                  bannerSubtitle: SearchContextRegistry.copyFor(_searchContext)
                      .bannerSubtitle,
                  emptySuggestions: _emptySearchSuggestions,
                  highlightSearch: _highlightSearchHint,
                  searchHighlightColor: _searchContext == SearchContext.baskets
                      ? ModuleColors.portfolio
                      : ModuleColors.market,
                  child: common.OfflineShell(
                    child: Shortcuts(
                      shortcuts: {
                        LogicalKeySet(
                          !kIsWeb && Platform.isMacOS
                              ? LogicalKeyboardKey.meta
                              : LogicalKeyboardKey.control,
                          LogicalKeyboardKey.keyK,
                        ): SearchIntent(),
                      },
                      child: Actions(
                        actions: {
                          SearchIntent: CallbackAction<SearchIntent>(
                            onInvoke: (intent) {
                              _showSearch();
                              return null;
                            },
                          ),
                        },
                        child: _buildShellScaffold(
                          authState: authState,
                          userId: userId,
                          isAdmin: isAdmin,
                          isDark: isDark,
                          isDesktop: isDesktop,
                          child: widget.child,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );

          // Cover shell while auth restores (web + native). Authenticated users
          // never hit this branch — [authPending] is false once session lands.
          if (!authPending) return shell;

          final failed = authState is AuthRestoreFailed;
          return Stack(
            children: [
              shell,
              Positioned.fill(
                child: AmSessionStatusView(
                  title: failed
                      ? 'Connection issue — retrying session…'
                      : 'Restoring your session…',
                  subtitle: failed
                      ? 'We could not reach the auth service. You can retry now.'
                      : 'Signing you back into AM securely',
                  tone: failed
                      ? AmSessionStatusTone.retrying
                      : AmSessionStatusTone.restoring,
                  onRetry: failed
                      ? () => context.read<AuthCubit>().checkAuthStatus()
                      : null,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
