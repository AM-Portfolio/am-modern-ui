import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:am_auth_ui/am_auth_ui.dart';
import 'package:am_portfolio_ui/am_portfolio_ui.dart';

import 'package:am_market_ui/am_market_ui.dart';
import 'package:am_user_ui/am_user_ui.dart';

import '../dashboard/dashboard_page.dart';

/// Main application shell with navigation
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0; // Default to Dashboard

  // Mapping string titles to indices
  final Map<String, int> _navMap = {
    'Dashboard': 0,
    'Portfolio': 1,

    'Market': 3,
    'Profile': 4,
  };

  String get _activeNavItem {
    if (_selectedIndex == 4) return ''; // Profile is separate
    return _navMap.entries.firstWhere((e) => e.value == _selectedIndex, orElse: () => const MapEntry('Dashboard', 0)).key;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        if (authState is! Authenticated) {
          return const LoginPage();
        }

        final userId = 'e1fd2918-484f-4716-ad5b-d46090891e01'; 
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return LayoutBuilder(
          builder: (context, constraints) {
            // Responsive breakpoint (Standardized to 1100px for Tablet support)
            final isDesktop = constraints.maxWidth > 1100;

            // Determine if we should show global nav on mobile
            // Show only if in Dashboard (0) or Profile (4).
            // Modules (1, 2, 3) will provide their own bottom bar.
            final showMobileGlobalBar = !isDesktop && (_selectedIndex == 0 || _selectedIndex == 4);

            return Scaffold(
              // Desktop: Row Layout (Sidebar + Body)
              // Mobile: Body takes full space (Bottom Bar handled via bottomNavigationBar)
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
                           debugPrint('Theme toggle error: \$e');
                         }
                      }, 
                      onLogout: () => context.read<AuthCubit>().logout(),
                      onProfileTap: () => setState(() => _selectedIndex = 4),
                      onNavigate: (title) {
                        if (_navMap.containsKey(title)) {
                          setState(() => _selectedIndex = _navMap[title]!);
                        }
                      },
                      items: [
                         SidebarItem(title: 'Dashboard', icon: Icons.dashboard_rounded),
                         SidebarItem(title: 'Portfolio', icon: Icons.account_balance_wallet_rounded),

                         SidebarItem(title: 'Market', icon: Icons.show_chart_rounded),
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
                      onProfileTap: () => setState(() => _selectedIndex = 4),
                      onNavigate: (title) {
                        if (_navMap.containsKey(title)) {
                          setState(() => _selectedIndex = _navMap[title]!);
                        }
                      },
                      items: [
                         SidebarItem(title: 'Dashboard', icon: Icons.dashboard_rounded),
                         SidebarItem(title: 'Portfolio', icon: Icons.account_balance_wallet_rounded),

                         SidebarItem(title: 'Market', icon: Icons.show_chart_rounded),
                      ],
                    )
                  : null, // Hide global bar when inside a module on mobile
            );
          },
        );
      },
    );
  }

  Widget _buildPage(String userId, bool isDesktop) {
    // Callback to return to Dashboard (Global Nav) on mobile
    final onBackToGlobal = () => setState(() => _selectedIndex = 0);

    switch (_selectedIndex) {
      case 0:
        return DashboardPage(userId: userId);
      case 1:
        return PortfolioScreen(
          userId: userId,
          onBack: onBackToGlobal,
        );

      case 3:
        return MarketPage(
          userId: userId,
          onBack: onBackToGlobal,
        ); // MarketPage wraps MarketWebScreen?
      case 4:
        return ProfileSettingsPage(userId: userId);
      default:
        return DashboardPage(userId: userId);
    }
  }
}
