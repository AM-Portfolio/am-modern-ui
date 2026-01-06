import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:am_auth_ui/am_auth_ui.dart';
import 'package:am_portfolio_ui/am_portfolio_ui.dart';
import 'package:am_trade_ui/am_trade_ui.dart';
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
  int _selectedIndex = 2; // Default to Trade UI

  // Mapping string titles to indices
  final Map<String, int> _navMap = {
    'Dashboard': 0,
    'Portfolio': 1,
    'Trade': 2,
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
        // Show login if not authenticated
        if (authState is! Authenticated) {
          return const LoginPage();
        }

        // DEBUG: Force User ID to match the debug token
        final userId = 'e1fd2918-484f-4716-ad5b-d46090891e01'; // authState.user.id;
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Scaffold(
          body: Row(
            children: [
              // Global Sidebar
              GlobalSidebar(
                activeNavItem: _activeNavItem,
                isDarkMode: isDark,
                userName: authState.user.displayName,
                userEmail: authState.user.email,
                // onThemeToggle: () => context.read<ThemeCubit>().toggleTheme(), // Assuming ThemeCubit exists
                onThemeToggle: () {
                   // Fallback if ThemeCubit isn't directly available or method differs
                   // For now, assuming standard Provider/Bloc setup
                   try {
                     // context.read<ThemeCubit>().toggleTheme(); 
                     // Or just print if we can't find it easily without checking main.dart again
                   } catch (e) {
                     debugPrint('Theme toggle not wired: $e');
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
                   SidebarItem(title: 'Trade', icon: Icons.trending_up_rounded),
                   SidebarItem(title: 'Market', icon: Icons.show_chart_rounded),
                ],
              ),
              
              // No divider needed as GlobalSidebar has its own border
              
              // Main content area
              Expanded(
                child: _buildPage(userId),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPage(String userId) {
    switch (_selectedIndex) {
      case 0:
        return DashboardPage(userId: userId);
      case 1:
        // Portfolio - Use actual portfolio web screen
        return PortfolioScreen(userId: userId);
      case 2:
        // Trade - Use add trade page (main trade page)
        return TradeWebScreen(userId: userId);
      case 3:
        // Market - Use market overview page
        return MarketPage(userId: userId);
      case 4:
        // Profile - Use profile settings page
        return ProfileSettingsPage(userId: userId);
      default:
        return DashboardPage(userId: userId);
    }
  }
}
