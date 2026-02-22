import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:am_auth_ui/am_auth_ui.dart';
import 'package:am_dashboard_ui/am_dashboard_ui.dart' as dashboard;

// ── DISABLED MODULES (re-enable one at a time as each module is fixed) ─────
import 'package:am_portfolio_ui/am_portfolio_ui.dart';
import 'package:am_trade_ui/am_trade_ui.dart';
import 'package:am_market_ui/am_market_ui.dart';
// import 'package:am_ai_ui/am_ai_ui.dart';
// import 'package:am_diagnostic_ui/am_diagnostic_ui.dart';

import '../../core/di/injection.dart';

/// Main application shell with navigation
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0; // Default to Dashboard

  // Mapping string titles to indices
  final Map<String, int> _navMap = const {
    'Dashboard': 0,
    'Portfolio': 1,
    'Trade': 2,
    'Market': 3,
    'AI Chat': 4,
    'Lab': 5,
    'Profile': 6,
  };

  String get _activeNavItem {
    if (_selectedIndex == 6) return ''; // Profile is separate
    return _navMap.entries
        .firstWhere((e) => e.value == _selectedIndex,
            orElse: () => const MapEntry('Dashboard', 0))
        .key;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        if (authState is! Authenticated) {
          return const LoginPage();
        }

        const userId = 'e1fd2918-484f-4716-ad5b-d46090891e01';
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
                          setState(() => _selectedIndex = 6),
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
                      ],
                    ),
                  Expanded(
                    child: _buildPage(userId, isDesktop),
                  ),
                ],
              ),
              bottomNavigationBar: showMobileGlobalBar
                  ? GlobalBottomNavigation(
                      activeNavItem: _activeNavItem,
                      isDarkMode: isDark,
                      userName: authState.user.displayName,
                      onProfileTap: () =>
                          setState(() => _selectedIndex = 6),
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
                      ],
                    )
                  : null,
            );
          },
        );
      },
    );
  }

  Widget _buildComingSoon(String label) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.construction_rounded,
                size: 64, color: Colors.amber),
            const SizedBox(height: 16),
            Text(label,
                style: const TextStyle(
                    fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('This module is being upgraded.',
                style: TextStyle(fontSize: 16, color: Colors.grey)),
          ],
        ),
      );

  Widget _buildPage(String userId, bool isDesktop) {

    switch (_selectedIndex) {
      case 0:
        return dashboard.DashboardPage(userId: userId);

      // ── DISABLED (uncomment when module is fixed) ──────────────────────
      case 1:
        return PortfolioScreen(userId: userId);
      case 2:
        return TradeWebScreen(userId: userId);
      case 3:
        return MarketPage(userId: userId);
      case 4:
        // return AiChatScreen(userId: userId);
        return _buildComingSoon('AI Chat');
      case 5:
        // return const DiagnosticDashboardPage();
        return _buildComingSoon('Lab / Diagnostic');
      case 6:
        // return ProfileSettingsPage(userId: userId);
        return _buildComingSoon('Profile');
      // ──────────────────────────────────────────────────────────────────

      default:
        return dashboard.DashboardPage(userId: userId);
    }
  }
}
