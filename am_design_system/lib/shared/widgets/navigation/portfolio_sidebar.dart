import 'package:flutter/material.dart';

/// A sidebar component for portfolio navigation
class PortfolioSidebar extends StatelessWidget {
  /// Constructor
  const PortfolioSidebar({
    required this.currentPage,
    required this.onPageSelected,
    super.key,
  });

  /// Current selected page
  final String currentPage;

  /// Callback when a page is selected
  final Function(String) onPageSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E), // Dark background
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Text(
                'Portfolio',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),
            _buildSidebarItem(
              context,
              'Overview',
              Icons.dashboard_outlined,
              currentPage == 'Overview',
            ),
            _buildSidebarItem(
              context,
              'Holdings',
              Icons.account_balance_outlined,
              currentPage == 'Holdings',
            ),
            _buildSidebarItem(
              context,
              'Analysis',
              Icons.analytics_outlined,
              currentPage == 'Analysis',
            ),
          ],
        ),
      ),
    );
  }

  /// Build a sidebar navigation item
  Widget _buildSidebarItem(
    BuildContext context,
    String title,
    IconData icon,
    bool isActive,
  ) {
    const activeColor = Color(0xFF6C5DD3);
    final inactiveColor = Colors.white.withValues(alpha: 0.7);

    return InkWell(
      onTap: () => onPageSelected(title),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        decoration: BoxDecoration(
          color: isActive
              ? activeColor.withValues(alpha: 0.1)
              : Colors.transparent,
          border: Border(
            left: BorderSide(
              color: isActive ? activeColor : Colors.transparent,
              width: 4,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isActive ? activeColor : inactiveColor,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                color: isActive ? activeColor : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
