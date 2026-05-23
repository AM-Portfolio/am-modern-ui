import 'package:flutter/material.dart';

import '../../trade_navigation.dart';

/// Floating Action Button for adding new trades
class AddTradeFab extends StatelessWidget {
  const AddTradeFab({super.key, this.portfolioId});
  final String? portfolioId;

  @override
  Widget build(BuildContext context) {
    if (portfolioId == null) {
      return const SizedBox.shrink();
    }

    return FloatingActionButton.extended(
      onPressed: () {
        openAddTradeWebPage(context, portfolioId: portfolioId!);
      },
      icon: const Icon(Icons.add),
      label: const Text('Add Trade'),
      tooltip: 'Add a new trade',
    );
  }
}
