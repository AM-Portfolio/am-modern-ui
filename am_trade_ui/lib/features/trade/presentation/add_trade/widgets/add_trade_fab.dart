import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
        context.go('/trade/add', extra: <String, dynamic>{'portfolioId': portfolioId});
      },
      icon: const Icon(Icons.add),
      label: const Text('Add Trade'),
      tooltip: 'Add a new trade',
    );
  }
}
