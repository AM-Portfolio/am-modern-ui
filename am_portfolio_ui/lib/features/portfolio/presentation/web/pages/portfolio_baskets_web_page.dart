import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:am_auth_ui/am_auth_ui.dart';
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

    final authState = context.read<AuthCubit>().state;
    final userId = authState is Authenticated ? authState.user.id : '';
    if (userId.isEmpty) {
      return const Center(child: Text('Please sign in to view basket opportunities'));
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: BasketSectionNavigator(
              userId: userId,
              portfolioId: portfolioId!,
            ),
          ),
        ],
      ),
    );
  }
}
