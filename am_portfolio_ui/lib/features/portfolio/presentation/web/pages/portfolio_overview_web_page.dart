import 'package:flutter/material.dart';


import 'package:am_portfolio_ui/features/portfolio/presentation/widgets/portfolio_overview_widget.dart';
import '../../../../basket/presentation/widgets/basket_explorer.dart';
import '../../widgets/gmail_sync/gmail_connect_button.dart';

/// Web-specific portfolio overview page
class PortfolioOverviewWebPage extends StatelessWidget {
  const PortfolioOverviewWebPage({
    required this.userId,
    super.key,
    this.portfolioId,
    this.portfolioName,
  });

  final String userId;
  final String? portfolioId;
  final String? portfolioName;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  portfolioName ?? 'My Portfolio',
                  style: Theme.of(context).textTheme.headlineMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 16),
              const GmailConnectButton(),
            ],
          ),
          const SizedBox(height: 16),
          if (portfolioId != null)
            BasketExplorer(
              userId: userId,
              portfolioId: portfolioId!,
            ),
          const SizedBox(height: 16),
          Expanded(
            child: PortfolioOverviewWidget(
              userId: userId,
            ),
          ),
        ],
      ),
    );
  }
}
