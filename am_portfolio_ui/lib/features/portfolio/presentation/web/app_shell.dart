import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:am_auth_ui/am_auth_ui.dart';
import '../cubit/portfolio_cubit.dart';
import '../cubit/portfolio_state.dart';
import '../widgets/global_portfolio_wrapper.dart'; // Correct relative import
import '../../internal/domain/entities/portfolio_list.dart';

class AppShell extends StatelessWidget {
  final Widget child;
  final String userId;
  final VoidCallback onLogout;

  const AppShell({
    required this.child,
    required this.userId,
    required this.onLogout,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // Current route location for highlighting sidebar items
    final String location = GoRouterState.of(context).uri.toString();

    return BlocBuilder<PortfolioCubit, PortfolioState>(
      builder: (context, state) {
        final portfolios = state.portfolioList?.portfolios;

        return UnifiedSidebarScaffold(
          module: ModuleType.portfolio,
          // Empty header/title as requested ("Institute" style is minimal)
          title: null,
          subtitle: null,
          header: const SizedBox(height: 16),

          onThemeToggle: () {
            context.read<ThemeCubit>().toggleTheme();
          },
          onProfileTap: () {
            // Profile logic
          },
          onLogout: onLogout,

          footer: Padding(
            padding: const EdgeInsets.all(16),
            child: SidebarPrimaryAction(
              title: 'New Trade',
              icon: Icons.add,
              accentColor: ModuleColors.portfolio,
              onTap: () {
                // Navigate to Basket Creator or Trade
                context.go('/portfolio/basket/creator');
              },
            ),
          ),

          sections: [
            // 1. Portfolio Selector
            if (portfolios != null && portfolios.isNotEmpty)
              SecondarySidebarSection(
                title: '',
                customWidget: SharedPortfolioSelector<PortfolioItem>(
                  currentPortfolioId: context.selectedPortfolioId,
                  currentPortfolioName: context.selectedPortfolioName,
                  portfolios: portfolios,
                  onPortfolioSelected: (id, name) {
                    context.selectPortfolio(id, name);
                    // Refresh current route? Usually needed if the route depends on ID.
                    // Ideally, we force a refresh or the pages listen to the ID change via provider.
                  },
                  idExtractor: (p) => p.portfolioId,
                  nameExtractor: (p) => p.portfolioName,
                  accentColor: ModuleColors.portfolio,
                ),
              ),

            // 2. Navigation Items
            SecondarySidebarSection(
              title: '',
              items: [
                SecondarySidebarItem(
                  title: 'Overview',
                  icon: Icons.dashboard_outlined,
                  isSelected:
                      location == '/portfolio/overview' ||
                      location == '/portfolio',
                  onTap: () => context.go('/portfolio/overview'),
                  accentColor: ModuleColors.portfolio,
                ),
                SecondarySidebarItem(
                  title: 'Holdings',
                  icon: Icons.pie_chart,
                  isSelected: location == '/portfolio/holdings',
                  onTap: () => context.go('/portfolio/holdings'),
                  accentColor: ModuleColors.portfolio,
                ),
                SecondarySidebarItem(
                  title: 'Analysis',
                  icon: Icons.analytics_outlined,
                  isSelected: location == '/portfolio/analysis',
                  onTap: () => context.go('/portfolio/analysis'),
                  accentColor: ModuleColors.portfolio,
                ),
                SecondarySidebarItem(
                  title: 'Heatmap',
                  icon: Icons.grid_on_outlined,
                  isSelected: location == '/portfolio/heatmap',
                  onTap: () => context.go('/portfolio/heatmap'),
                  accentColor: ModuleColors.portfolio,
                ),
                // Added manual link for debugging/access if needed,
                // though usually accessed via "New Trade" or flow
                SecondarySidebarItem(
                  title: 'Baskets',
                  icon: Icons.shopping_basket_outlined,
                  isSelected:
                      location.contains('/portfolio/basket') &&
                      !location.contains('/creator'),
                  onTap: () => context.go('/portfolio/baskets'),
                  accentColor: ModuleColors.portfolio,
                ),
              ],
            ),
          ],

          body: child, // Render specific page content here
        );
      },
    );
  }
}
