import 'package:flutter/material.dart';

/// Smart floating action button for adding new trades
/// Features:
/// - Animated entrance
/// - Extended label on desktop
/// - Tooltip support
/// - Responsive sizing
class AddTradeFAB extends StatelessWidget {
  const AddTradeFAB({required this.onPressed, super.key, this.label = 'Add Trade', this.isExtended = true});

  final VoidCallback onPressed;
  final String label;
  final bool isExtended;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1200;
    final isTablet = screenWidth >= 800 && screenWidth < 1200;

    // Use extended FAB for desktop and tablet
    final shouldExtend = isExtended && (isDesktop || isTablet);

    return Hero(
      tag: 'add_trade_fab',
      child: shouldExtend
          ? FloatingActionButton.extended(
              onPressed: onPressed,
              icon: const Icon(Icons.add),
              label: Text(label),
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              elevation: 4,
              tooltip: 'Add a new trade to your portfolio',
            )
          : FloatingActionButton(
              onPressed: onPressed,
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              elevation: 4,
              tooltip: label,
              child: const Icon(Icons.add),
            ),
    );
  }
}

/// Positioned floating action button for consistent placement
class PositionedAddTradeFAB extends StatelessWidget {
  const PositionedAddTradeFAB({required this.portfolioId, required this.portfolioName, super.key});

  final String portfolioId;
  final String? portfolioName;

  @override
  Widget build(BuildContext context) =>
      Positioned(right: 24, bottom: 24, child: AddTradeFAB(onPressed: () => _navigateToAddTrade(context)));

  void _navigateToAddTrade(BuildContext context) {
    Navigator.pushNamed(context, '/trade/add', arguments: {'portfolioId': portfolioId, 'portfolioName': portfolioName});
  }
}
