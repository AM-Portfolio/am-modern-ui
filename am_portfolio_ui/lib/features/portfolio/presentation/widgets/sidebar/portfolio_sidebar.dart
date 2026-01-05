import 'package:flutter/material.dart';
import 'package:am_design_system/shared/widgets/navigation/secondary_sidebar.dart';

/// Portfolio-specific sidebar that uses the shared SecondarySidebar component
class PortfolioSidebar extends StatelessWidget {
  const PortfolioSidebar({
    required this.currentPage,
    required this.onPageSelected,
    super.key,
  });

  final String currentPage;
  final Function(String) onPageSelected;

  @override
  Widget build(BuildContext context) {
    // Portfolio accent color (purple)
    const portfolioAccent = Color(0xFF6C5DD3);

    return SecondarySidebar(
      title: 'Portfolio',
      subtitle: 'Manage your holdings',
      icon: Icons.account_balance_wallet_rounded,
      accentColor: portfolioAccent,
      width: 280,
      items: [
        SecondarySidebarItem(
          title: 'Overview',
          subtitle: 'Dashboard & summary',
          icon: Icons.dashboard_outlined,
          accentColor: portfolioAccent,
          isSelected: currentPage == 'Overview',
          onTap: () => onPageSelected('Overview'),
        ),
        SecondarySidebarItem(
          title: 'Holdings',
          subtitle: 'Stock positions',
          icon: Icons.account_balance_outlined,
          accentColor: portfolioAccent,
          isSelected: currentPage == 'Holdings',
          onTap: () => onPageSelected('Holdings'),
        ),
        SecondarySidebarItem(
          title: 'Analysis',
          subtitle: 'Performance metrics',
          icon: Icons.analytics_outlined,
          accentColor: portfolioAccent,
          isSelected: currentPage == 'Analysis',
          onTap: () => onPageSelected('Analysis'),
        ),
        SecondarySidebarItem(
          title: 'Heatmap',
          subtitle: 'Visual performance',
          icon: Icons.grid_on_outlined,
          accentColor: portfolioAccent,
          isSelected: currentPage == 'Heatmap',
          onTap: () => onPageSelected('Heatmap'),
        ),
      ],
    );
  }
}
