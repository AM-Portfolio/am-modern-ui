import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:am_auth_ui/am_auth_ui.dart';
import 'package:am_dashboard_ui/am_dashboard_ui.dart' as dashboard;
import 'package:get_it/get_it.dart';
import 'package:am_common/am_common.dart' as common;
import 'package:am_subscription_ui/am_subscription_ui.dart' as am_sub;

// ── DISABLED MODULES (re-enable one at a time as each module is fixed) ─────
import 'package:am_portfolio_ui/am_portfolio_ui.dart';
import 'package:am_trade_ui/am_trade_ui.dart';
import 'package:am_market_ui/am_market_ui.dart';
import 'package:am_ai_ui/am_ai_ui.dart';
import 'package:am_diagnostic_ui/am_diagnostic_ui.dart';
import 'package:am_user_ui/am_user_ui.dart';
import 'package:am_analysis_ui/am_analysis_ui.dart';
import 'package:am_doc_intelligence_ui/am_doc_intelligence_ui.dart';

/// Main application shell with navigation
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0; // Default to Dashboard
  bool _sessionRestored = false;

  // ── Secondary navigation items for the "More" bottom sheet ───────────────
  static const List<_MoreMenuItem> _moreMenuItems = [
    _MoreMenuItem(title: 'AI Chat', icon: Icons.auto_awesome_rounded, index: 4),
    _MoreMenuItem(title: 'Lab', icon: Icons.science_rounded, index: 5),
    _MoreMenuItem(title: 'Analysis', icon: Icons.analytics_outlined, index: 6),
    _MoreMenuItem(title: 'Doc Intel', icon: Icons.psychology_outlined, index: 7),
    _MoreMenuItem(title: 'Subscription', icon: Icons.subscriptions_rounded, index: 9),
    _MoreMenuItem(title: 'Profile', icon: Icons.person_rounded, index: 8),
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
    _sessionRestored = true;

    final session =
        await common.SessionPersistenceService.instance.load(authState.user.id);
    if (session != null && mounted && _navMap.containsKey(session.globalNav)) {
      setState(() => _selectedIndex = _navMap[session.globalNav]!);
      _applyStreamingTabCoordinator(session.globalNav);
    }
  }

  void _applyStreamingTabCoordinator(String tabTitle) {
    if (!GetIt.instance.isRegistered<common.AmStompClient>()) return;
    if (tabTitle.isEmpty) return;
    common.StreamingTabCoordinator(GetIt.instance<common.AmStompClient>())
        .onTabSelected(tabTitle);
  }

  void _onGlobalNavigate(String title, String userId) {
    if (!_navMap.containsKey(title)) return;
    _applyStreamingTabCoordinator(title);
    setState(() => _selectedIndex = _navMap[title]!);
    common.SessionPersistenceService.instance.patch(
      userId,
      (s) => s.copyWith(globalNav: title, clearBasket: title != 'Portfolio'),
    );
  }

  Future<void> _checkInitialAuthAndConnect() async {
    final authCubit = context.read<AuthCubit>();
    final authState = authCubit.state;
    if (authState is Authenticated) {
      common.AppLogger.info('AppShell: Initialized while Authenticated. Triggering STOMP connection...');
      final stompCubit = context.read<common.StompConnectionCubit>();
      
      stompCubit.onConnected = (userId) {
        common.AppLogger.info('AppShell (Initial): STOMP Connected for $userId');
        if (mounted) _applyStreamingTabCoordinator(_activeNavItem);
      };

      final secureStorage = GetIt.instance<common.SecureStorageService>();
      final token = await secureStorage.getAccessToken();
      if (token == null || token.isEmpty) {
        if (mounted) {
          common.AppLogger.warning('AppShell: Authenticated state but no token in storage. Forcing logout.');
          authCubit.logout();
        }
        return;
      }
      if (mounted) {
        stompCubit.updateToken(token, userId: authState.user.id);
      }
    }
  }

  // Mapping string titles to indices
  final Map<String, int> _navMap = const {
    'Dashboard': 0,
    'Portfolio': 1,
    'Trade': 2,
    'Market': 3,
    'AI Chat': 4,
    'Lab': 5,
    'Analysis': 6,
    'Doc Intel': 7,
    'Profile': 8,
    'Subscription': 9,
  };

  String get _activeNavItem {
    if (_selectedIndex == 8) return ''; // Profile is separate
    return _navMap.entries
        .firstWhere((e) => e.value == _selectedIndex,
            orElse: () => const MapEntry('Dashboard', 0))
        .key;
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<AuthCubit, AuthState>(
          listener: (context, state) async {
            final stompCubit = context.read<common.StompConnectionCubit>();
            
            if (state is Authenticated) {
               common.AppLogger.info('AppShell: AuthState changed to Authenticated. Connecting STOMP...');
               
               // Register root-level sync trigger
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
                   common.AppLogger.warning('AppShell: Authenticated state but no token. Forcing logout.');
                   context.read<AuthCubit>().logout();
                 }
                 return;
               }
               if (context.mounted) {
                 stompCubit.updateToken(token, userId: state.user.id);
               }
            } else if (state is Unauthenticated) {
               common.AppLogger.info('AppShell: AuthState changed to Unauthenticated. Disconnecting STOMP...');
               stompCubit.onConnected = null;
               stompCubit.updateToken(null);
            }
          },
        ),
      ],
      child: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, authState) {
          if (authState is! Authenticated) {
            return const LoginPage();
          }

          final userId = authState.user.id;
          final isDark = Theme.of(context).brightness == Brightness.dark;

          return LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth > 1100;
              final showMobileGlobalBar = !isDesktop;

              return Scaffold(
                body: Row(
                  children: [
                    if (isDesktop)
                      GlobalSidebar(
                        activeNavItem: _activeNavItem,
                        isDarkMode: isDark,
                        userName: authState.user.displayName,
                        userEmail: authState.user.email,
                        userAvatarUrl: authState.user.photoUrl,
                        onThemeToggle: () {
                          try {
                            context.read<ThemeCubit>().toggleTheme();
                          } catch (e) {
                            debugPrint('Theme toggle error: $e');
                          }
                        },
                        onLogout: () => context.read<AuthCubit>().logout(),
                        onProfileTap: () =>
                            setState(() => _selectedIndex = 8),
                        onNavigate: (title) => _onGlobalNavigate(title, userId),
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
                              title: 'AI Chat',
                              icon: Icons.auto_awesome_rounded),
                          SidebarItem(
                              title: 'Lab', icon: Icons.science_rounded),
                          SidebarItem(
                              title: 'Analysis', icon: Icons.analytics_outlined),
                          SidebarItem(
                              title: 'Doc Intel', icon: Icons.psychology_outlined),
                          SidebarItem(
                              title: 'Subscription', icon: Icons.subscriptions_rounded),
                        ],
                      ),
                    Expanded(
                      child: GlobalPortfolioWrapper(
                        streamingTab: _activeNavItem.isEmpty
                            ? 'Dashboard'
                            : _activeNavItem,
                        child: _buildPage(userId, isDesktop),
                      ),
                    ),
                  ],
                ),
                bottomNavigationBar: showMobileGlobalBar
                    ? GlobalBottomNavigation(
                        activeNavItem: _activeNavItem,
                        isDarkMode: isDark,
                        userName: authState.user.displayName,
                        onMenuTap: () => _showMoreMenu(context, userId, isDark),
                        onNavigate: (title) => _onGlobalNavigate(title, userId),
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
        },
      ),
    );
  }

  Widget _buildPage(String userId, bool isDesktop) {
    switch (_selectedIndex) {
      case 0:
        return dashboard.DashboardScreen(userId: userId);
      case 1:
        return const PortfolioScreen();
      case 2:
        return const TradeResponsiveLayout();
      case 3:
        return MarketPage(userId: userId);
      case 4:
        return AiChatScreen(userId: userId);
      case 5:
        return const DiagnosticDashboardPage();
      case 6:
        return AnalysisDashboard(
          entityType: AnalysisEntityType.PORTFOLIO,
          entityId: userId,
          analysisService: RealAnalysisService(),
        );
      case 7:
        return DocIntelligenceScreen(userId: userId);
      case 8:
        return ProfileSettingsPage(userId: userId);
      case 9:
        return BlocProvider<am_sub.SubscriptionCubit>.value(
          value: GetIt.instance<am_sub.SubscriptionCubit>(),
          child: const am_sub.SubscriptionPricingScreen(),
        );
      default:
        return dashboard.DashboardScreen(userId: userId);
    }
  }

  // ── Premium "More Menu" Bottom Sheet ────────────────────────────────────────
  void _showMoreMenu(BuildContext context, String userId, bool isDark) {
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
                // Drag handle
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Title
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

                // Grid of menu items
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
                    itemCount: _moreMenuItems.length,
                    itemBuilder: (ctx, i) {
                      final item = _moreMenuItems[i];
                      final isActive = _selectedIndex == item.index;
                      final accentColor = _getMoreItemColor(item.title);

                      return GestureDetector(
                        onTap: () {
                          Navigator.pop(sheetContext);
                          _onGlobalNavigate(item.title, userId);
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
      case 'Lab':
        return const Color(0xFF00B894);
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

/// Data class for the "More Menu" items
class _MoreMenuItem {
  const _MoreMenuItem({
    required this.title,
    required this.icon,
    required this.index,
  });

  final String title;
  final IconData icon;
  final int index;
}
