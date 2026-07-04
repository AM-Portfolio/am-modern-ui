import 'package:flutter/material.dart';
import '../../../../basket/presentation/basket_navigation.dart';

/// Web-specific baskets page
class PortfolioBasketsWebPage extends StatelessWidget {
  const PortfolioBasketsWebPage({
    super.key,
    this.portfolioId,
  });

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

          Expanded(
            child: BasketSectionNavigator(
              userId: 'default_user',
              portfolioId: portfolioId!,
            ),
          ),
        ],
      ),
    );
  }
}
