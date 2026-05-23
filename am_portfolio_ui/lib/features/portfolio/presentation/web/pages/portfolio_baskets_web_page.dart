import 'package:flutter/material.dart';
import '../../../../basket/presentation/basket_navigation.dart';

/// Web baskets tab — nested navigator keeps module + global sidebars visible.
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

    return BasketSectionNavigator(
      userId: userId,
      portfolioId: portfolioId!,
    );
  }
}
