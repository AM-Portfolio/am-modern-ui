import 'package:flutter/material.dart';
import '../../../../basket/presentation/widgets/basket_explorer.dart';

/// Web-specific baskets page
class PortfolioBasketsWebPage extends StatelessWidget {
  const PortfolioBasketsWebPage({
    required this.userId,
    super.key,
    this.portfolioId,
  });

  final String userId;
  final String? portfolioId;

  @override
  Widget build(BuildContext context) {
    if (portfolioId == null) {
      return const Center(child: Text('Please select a portfolio'));
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Basket Opportunities',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: BasketExplorer(
              userId: userId,
              portfolioId: portfolioId!,
            ),
          ),
        ],
      ),
    );
  }
}
