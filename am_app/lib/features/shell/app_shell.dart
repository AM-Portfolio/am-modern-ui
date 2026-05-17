import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:am_auth_ui/am_auth_ui.dart';
import 'package:am_dashboard_ui/am_dashboard_ui.dart' as dashboard;
import 'package:get_it/get_it.dart';
import 'package:am_common/am_common.dart' as common;

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

  @override
  void initState() {
    super.initState();
    // Trigger initial connection check
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkInitialAuthAndConnect();
    });
  }

  Future<void> _checkInitialAuthAndConnect() async {
    final authCubit = context.read<AuthCubit>();
    final authState = authCubit.state;
    if (authState is Authenticated) {
      common.AppLogger.info('AppShell: Initialized while Authenticated. Triggering STOMP connection...');
      final stompCubit = context.read<common.StompConnectionCubit>();
      
      stompCubit.onConnected = (userId) {
        common.AppLogger.info('AppShell (Initial): STOMP Connected. Triggering global portfolio sync for $userId');
        common.ServiceRegistry.stomp.send(
          destination: '/app/portfolio/subscribe',
          headers: {'content-type': 'application/json'},
          body: '{"userId": "$userId"}',
        );
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
                 common.AppLogger.info('AppShell: STOMP Connected. Triggering global portfolio sync for $userId');
                 common.ServiceRegistry.stomp.send(
                   destination: '/app/portfolio/subscribe',
                   headers: {'content-type': 'application/json'},
                   body: '{"userId": "$userId"}',
                 );
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
              final showMobileGlobalBar =
                  !isDesktop && (_selectedIndex == 0 || _selectedIndex == 5);

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
                        onNavigate: (title) {
                          if (_navMap.containsKey(title)) {
                            setState(() => _selectedIndex = _navMap[title]!);
                          }
                        },
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
                        ],
                      ),
                    Expanded(
                      child: GlobalPortfolioWrapper(
                        userId: userId,
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
                        onProfileTap: () =>
                            setState(() => _selectedIndex = 8),
                        onNavigate: (title) {
                          if (_navMap.containsKey(title)) {
                            setState(() => _selectedIndex = _navMap[title]!);
                          }
                        },
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
        return dashboard.DashboardPage(userId: userId);
      case 1:
        return PortfolioScreen(userId: userId);
      case 2:
        return TradeWebScreen(userId: userId);
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
      default:
        return dashboard.DashboardPage(userId: userId);
    }
  }
}
