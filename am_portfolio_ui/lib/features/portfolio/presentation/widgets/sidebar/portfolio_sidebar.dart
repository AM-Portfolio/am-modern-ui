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
    // Portfolio accent color (Amber/Orange)
    const portfolioAccent = Color(0xFFFFA500);

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
      SecondarySidebarItem(
        title: 'Analysis',
        icon: Icons.analytics_outlined,
        accentColor: portfolioAccent,
        isSelected: currentPage == 'Analysis',
        onTap: () => onPageSelected('Analysis'),
      ),
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
    final newTradeButton = Container(
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFF1F222B), // Dark background for contrast
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Navigate to NEW TRADE
          },
          borderRadius: BorderRadius.circular(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.add, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                'New Trade',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
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
