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

        return Scaffold(
          body: Row(
            children: [
              // Navigation Rail
              NavigationRail(
                selectedIndex: _selectedIndex,
                onDestinationSelected: (index) {
                  setState(() => _selectedIndex = index);
                },
                labelType: NavigationRailLabelType.all,
                backgroundColor: Theme.of(context).colorScheme.surface,
                destinations: const [
                  NavigationRailDestination(
                    icon: Icon(Icons.dashboard_outlined),
                    selectedIcon: Icon(Icons.dashboard),
                    label: Text('Dashboard'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.account_balance_wallet_outlined),
                    selectedIcon: Icon(Icons.account_balance_wallet),
                    label: Text('Portfolio'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.trending_up_outlined),
                    selectedIcon: Icon(Icons.trending_up),
                    label: Text('Trade'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.show_chart_outlined),
                    selectedIcon: Icon(Icons.show_chart),
                    label: Text('Market'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.person_outline),
                    selectedIcon: Icon(Icons.person),
                    label: Text('Profile'),
                  ),
                ],
              ),
              
              const VerticalDivider(thickness: 1, width: 1),
              
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
