import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import '../../../internal/domain/entities/portfolio_list.dart';
import 'package:am_common/am_common.dart';
import '../../widgets/gmail_sync/gmail_connect_button.dart';

/// Widget that displays the portfolio selector and tab bar
class PortfolioHeaderWidget extends StatelessWidget {
  const PortfolioHeaderWidget({
    required this.tabController,
    required this.currentPortfolioId,
    required this.onLogout,
    super.key,
    this.portfolios,
    this.onPortfolioChanged,
  });

  final TabController tabController;
  final String? currentPortfolioId;
  final List<PortfolioItem>? portfolios;
  final Function(String portfolioId, String portfolioName)? onPortfolioChanged;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    // Find current portfolio name
    String currentName = 'Select Portfolio';
    if (currentPortfolioId != null && portfolios != null) {
      final match = portfolios!.where(
        (p) => p.portfolioId == currentPortfolioId,
      );
      if (match.isNotEmpty) {
        currentName = match.first.portfolioName;
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // Portfolio Switcher Trigger (Bottom Sheet)
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _showPortfolioBottomSheet(context),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.account_balance_wallet,
                              color: Theme.of(context).primaryColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Current Portfolio',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Colors.grey,
                                      fontSize: 10,
                                    ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    currentName,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.keyboard_arrow_down,
                                    size: 16,
                                    color: Colors.grey,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Actions
                  const GmailConnectButton(),
                ],
              ),
            ),

            // Tab bar
            _buildTabBar(context),
          ],
        ),
      ),
    );
  }

  void _showPortfolioBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Select Portfolio',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            if (portfolios != null)
              ...portfolios!.map(
                (p) => ListTile(
                  leading: Icon(
                    Icons.account_balance_wallet,
                    color: p.portfolioId == currentPortfolioId
                        ? Theme.of(context).primaryColor
                        : Colors.grey,
                  ),
                  title: Text(
                    p.portfolioName,
                    style: TextStyle(
                      fontWeight: p.portfolioId == currentPortfolioId
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: p.portfolioId == currentPortfolioId
                          ? Theme.of(context).primaryColor
                          : null,
                    ),
                  ),
                  trailing: p.portfolioId == currentPortfolioId
                      ? Icon(Icons.check, color: Theme.of(context).primaryColor)
                      : null,
                  onTap: () {
                    Navigator.pop(context);
                    _handlePortfolioChange(p.portfolioId);
                  },
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                ),
              ),

            const Divider(height: 32),

            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 24),
              onTap: () {
                Navigator.pop(context);
                onLogout();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// Builds the tab bar
  Widget _buildTabBar(BuildContext context) => TabBar(
    controller: tabController,
    labelColor: Theme.of(context).primaryColor,
    unselectedLabelColor: Colors.grey,
    indicatorColor: Theme.of(context).primaryColor,
    labelPadding: EdgeInsets.zero, // Optimize space
    indicatorSize: TabBarIndicatorSize.label,
    labelStyle: const TextStyle(
      fontSize: 10, // Smaller font for mobile
      fontWeight: FontWeight.w600,
    ),
    tabs: const [
      Tab(icon: Icon(Icons.dashboard_outlined, size: 20), text: 'Overview'),
      Tab(icon: Icon(Icons.wallet, size: 20), text: 'Holdings'),
      Tab(icon: Icon(Icons.analytics_outlined, size: 20), text: 'Analysis'),
      Tab(icon: Icon(Icons.grid_view, size: 20), text: 'Heatmap'),
      Tab(icon: Icon(Icons.show_chart, size: 20), text: 'Trade'),
    ],
  );

  /// Handles portfolio selection change
  void _handlePortfolioChange(String? newPortfolioId) {
    if (newPortfolioId != null &&
        newPortfolioId != currentPortfolioId &&
        portfolios != null &&
        onPortfolioChanged != null) {
      final selectedPortfolio = portfolios!.firstWhere(
        (p) => p.portfolioId == newPortfolioId,
      );

      onPortfolioChanged!(newPortfolioId, selectedPortfolio.portfolioName);

      CommonLogger.info(
        'Portfolio selection changed to: ${selectedPortfolio.portfolioName} ($newPortfolioId)',
        tag: 'PortfolioHeaderWidget',
      );
    }
  }
}
