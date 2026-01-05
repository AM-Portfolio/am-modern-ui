import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';

class PortfolioSelectionPrompt extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onViewPortfolioList;

  const PortfolioSelectionPrompt({
    super.key,
    required this.title,
    required this.icon,
    required this.onViewPortfolioList,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Select a Portfolio',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose a portfolio to view $title',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onViewPortfolioList,
            icon: const Icon(Icons.list),
            label: const Text('View Portfolio List'),
          ),
        ],
      ),
    );
  }
}
