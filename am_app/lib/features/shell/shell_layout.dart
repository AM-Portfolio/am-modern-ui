part of 'app_shell.dart';

/// Desktop GlobalSidebar + mobile bottom-nav / search overlay chrome.
mixin ShellLayout on State<AppShell>,
    ShellNav,
    ShellBottomNavChrome,
    ShellSecurityAlerts,
    ShellGlobalAdd,
    ShellSearchOps {
  Widget _buildShellScaffold({
    required AuthState authState,
    required String userId,
    required bool isAdmin,
    required bool isDark,
    required bool isDesktop,
    required Widget child,
  }) {
    return Scaffold(
      // Body draws under the floating overlay nav — no reserved slot.
      extendBody: !isDesktop,
      resizeToAvoidBottomInset: false,
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
                  userAvatar: buildShellSidebarAvatar(
                    displayName:
                        authState.user.displayName ?? authState.user.email,
                    photoUrl: authState.user.photoUrl,
                  ),
                  moduleShareUrls: AppRoutes.navTitleToDefaultPath,
                  onSearchTap: _showSearch,
                  highlightSearch: _highlightSearchHint,
                  searchHighlightColor: _moduleAccentFor(_activeNavItem),
                  addActions: _globalAddActions(context),
                  onThemeToggle: () {
                    try {
                      final cubit = context.read<ThemeCubit>();
                      showThemeModePickerDialog(
                        context: context,
                        currentMode: cubit.state.mode,
                        onSelected: (mode) {
                          cubit.setTheme(mode);
                        },
                      );
                    } catch (e) {
                      debugPrint('Theme picker error: $e');
                    }
                  },
                  onLogout: () async {
                    final uid = authState.user.id;
                    if (GetIt.I.isRegistered<common.OfflineSyncEngine>() &&
                        uid.isNotEmpty) {
                      await GetIt.I<common.OfflineSyncEngine>().clearUser(uid);
                    }
                    if (GetIt.I.isRegistered<am_sub.SubscriptionCubit>()) {
                      await GetIt.I<am_sub.SubscriptionCubit>()
                          .invalidateCache();
                    }
                    if (!mounted) return;
                    await context.read<AuthCubit>().logout();
                  },
                  onProfileTap: () => context.go(AppRoutes.profile),
                  onNavigate: (title) => _onGlobalNavigate(title, userId),
                  items: _sidebarItemsFor(isAdmin: isAdmin),
                ),
              Expanded(
                child: isDesktop
                    ? (authState is Authenticated
                        ? common.CrossSectionNavScope(
                            controller: common.CrossSectionNavController(
                              goNextModule: () => _onCrossSectionNext(userId),
                              goPreviousModule: () =>
                                  _onCrossSectionPrevious(userId),
                            ),
                            child: common.PortfolioSelectionScope(
                              child: child,
                            ),
                          )
                        : child)
                    : Listener(
                        behavior: HitTestBehavior.translucent,
                        onPointerDown: _onChromePointerDown,
                        onPointerMove: _onChromePointerMove,
                        onPointerUp: _onChromePointerUp,
                        onPointerCancel: _onChromePointerCancel,
                        child: NotificationListener<ScrollNotification>(
                          onNotification: _handleBottomNavScroll,
                          child: authState is Authenticated
                              ? common.CrossSectionNavScope(
                                  controller: common.CrossSectionNavController(
                                    goNextModule: () =>
                                        _onCrossSectionNext(userId),
                                    goPreviousModule: () =>
                                        _onCrossSectionPrevious(userId),
                                  ),
                                  child: common.PortfolioSelectionScope(
                                    child: CrossSectionSwipeHost(
                                      onNext: () =>
                                          _onCrossSectionNext(userId),
                                      onPrevious: () =>
                                          _onCrossSectionPrevious(userId),
                                      child: child,
                                    ),
                                  ),
                                )
                              : child,
                        ),
                      ),
              ),
            ],
          ),
          if (!isDesktop && authState is Authenticated)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: ValueListenableBuilder<bool>(
                valueListenable: _mobileSearchOpen,
                builder: (context, searchOpen, overlayChild) {
                  if (searchOpen) {
                    return const SizedBox.shrink();
                  }
                  return overlayChild!;
                },
                child: AnimatedBuilder(
                  animation: _bottomNavController,
                  builder: (context, overlayChild) {
                    final visible = _bottomNavController.value > 0.01;
                    return IgnorePointer(
                      ignoring: !visible,
                      child: overlayChild,
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
                        accentColor: _moduleAccentFor(_activeNavItem),
                        userName: authState.user.displayName,
                        visibleCount: 5,
                        moduleShareUrls: AppRoutes.navTitleToDefaultPath,
                        onNavigate: (title) =>
                            _onGlobalNavigate(title, userId),
                        items: [
                          const SidebarItem(
                            title: 'Dashboard',
                            icon: Icons.dashboard_rounded,
                          ),
                          const SidebarItem(
                            title: 'Portfolio',
                            icon: Icons.account_balance_wallet_rounded,
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
                            title: 'AI Chat',
                            icon: Icons.auto_awesome_rounded,
                          ),
                          const SidebarItem(
                            title: 'Profile',
                            icon: Icons.person_rounded,
                          ),
                          if (isAdmin) ...[
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
            ),
          if (!isDesktop && authState is Authenticated)
            Positioned.fill(
              child: ValueListenableBuilder<bool>(
                valueListenable: _mobileSearchOpen,
                builder: (context, searchOpen, _) {
                  if (!searchOpen) {
                    return const SizedBox.shrink();
                  }
                  final copy = SearchContextRegistry.copyFor(_searchContext);
                  final nav = _activeNavItem;
                  final accent = _moduleAccentFor(nav);
                  return ModuleColorProvider(
                    module: _moduleTypeFor(nav),
                    child: common.MobileGlobalSearchOverlay(
                      key: ValueKey(
                        'global-search-${_searchContext.name}-$nav',
                      ),
                      accent: accent,
                      hintText: SearchContextRegistry.hintFor(_searchContext),
                      bannerTitle: copy.bannerTitle,
                      bannerSubtitle: copy.bannerSubtitle,
                      liveSearch: _liveSearchQuery,
                      emptySuggestions: _emptySearchSuggestions,
                      seedItems: _seedActionItems(context),
                      onClose: () {
                        if (_mobileSearchOpen.value) {
                          _mobileSearchOpen.value = false;
                        }
                        if (mounted) setState(() {});
                      },
                    ),
                  );
                },
              ),
            ),
          if (kIsWeb &&
              _isSecurityAlertBannerEnabled &&
              _securityAlert != null)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SecurityAlertBanner(
                event: _securityAlert!,
                onAcknowledge: () async {
                  await _acknowledgeSecurityAlert();
                },
                onReviewSessions: () {
                  context.go(AppRoutes.activeSessions);
                },
              ),
            ),
        ],
      ),
    );
  }
}
