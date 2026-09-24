import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';

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
    // Portfolio accent color (Amber/Orange)
    const portfolioAccent = Color(0xFFec4899);

    // Navigation Items
    final overviewItems = [
      SecondarySidebarItem(
        title: 'Overview',
        icon: Icons.dashboard_outlined,
        accentColor: portfolioAccent,
        isSelected: currentPage == 'Overview',
        onTap: () => onPageSelected('Overview'),
      ),
      SecondarySidebarItem(
        title: 'Holdings',
        icon: Icons.account_balance_outlined,
        accentColor: portfolioAccent,
        isSelected: currentPage == 'Holdings',
        onTap: () => onPageSelected('Holdings'),
      ),
      // SecondarySidebarItem(
      //   title: 'Analysis',
      //   icon: Icons.analytics_outlined,
      //   accentColor: portfolioAccent,
      //   isSelected: currentPage == 'Analysis',
      //   onTap: () => onPageSelected('Analysis'),
      // ),
      SecondarySidebarItem(
        title: 'Heatmap',
        icon: Icons.grid_on_outlined,
        accentColor: portfolioAccent,
        isSelected: currentPage == 'Heatmap',
        onTap: () => onPageSelected('Heatmap'),
      ),
    ];

    final historyItems = [
      SecondarySidebarItem(
        title: 'Transactions',
        icon: Icons.receipt_long_rounded,
        accentColor: portfolioAccent,
        isSelected: currentPage == 'Transactions',
        onTap: () => onPageSelected('Transactions'),
      ),
      SecondarySidebarItem(
        title: 'Dividends',
        icon: Icons.monetization_on_outlined,
        accentColor: portfolioAccent,
        isSelected: currentPage == 'Dividends',
        onTap: () => onPageSelected('Dividends'),
      ),
    ];

    // Sections
    final sections = <SecondarySidebarSection>[
      SecondarySidebarSection(
        title: 'PORTFOLIO',
        items: overviewItems,
        initiallyExpanded: true,
      ),
      SecondarySidebarSection(
        title: 'HISTORY',
        items: historyItems,
        initiallyExpanded: true,
      ),
    ];

    // New Trade Button
    final newTradeButton = SidebarFloatingActionMenu(
      onUploadPortfolio: () {},
      onAddTrade: () {},
      onAddAssetClass: () {},
      onAddBasket: () {},
    );

    return SecondarySidebar(
      title: 'WORKSPACE',
      subtitle: 'Personal Account',
      icon: Icons.grid_view_rounded,
      accentColor: portfolioAccent,
      width: 250,
      sections: sections,
      footer: newTradeButton,
    );
  }
}
