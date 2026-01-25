import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:go_router/go_router.dart';
import '../providers/basket_providers.dart';
import '../../domain/models/basket_opportunity.dart';

class BasketPreviewPage extends ConsumerWidget {
  final String etfIsin;
  final String userId;
  final String portfolioId;

  const BasketPreviewPage({
    super.key,
    required this.etfIsin,
    required this.userId,
    required this.portfolioId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final opportunityAsync = ref.watch(basketPreviewProvider(
      etfIsin: etfIsin,
      userId: userId,
      portfolioId: portfolioId,
    ));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Basket Preview'),
        centerTitle: false,
      ),
      body: opportunityAsync.when(
        data: (opportunity) => _BasketContent(
          opportunity: opportunity,
          userId: userId,
          portfolioId: portfolioId,
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

class _BasketContent extends StatelessWidget {
  final BasketOpportunity opportunity;
  final String userId;
  final String portfolioId;

  const _BasketContent({
    required this.opportunity,
    required this.userId,
    required this.portfolioId,
  });

  @override
  Widget build(BuildContext context) {
    // Compute held and missing items from composition
    final heldItems = opportunity.composition
        .where((item) => item.status == ItemStatus.held)
        .toList();
    final missingItems = opportunity.composition
        .where((item) => item.status != ItemStatus.held)
        .toList();

    return Column(
      children: [
        _EntryHeroCard(opportunity: opportunity),
        Expanded(
          child: DefaultTabController(
            length: 2,
            child: Column(
              children: [
                TabBar(
                  unselectedLabelColor: Theme.of(context).textTheme.bodySmall?.color,
                  labelColor: Theme.of(context).primaryColor,
                  indicatorColor: Theme.of(context).primaryColor,
                  tabs: [
                    Tab(text: "Your Match (${heldItems.length})"),
                    Tab(text: "The Gap (${missingItems.length})"),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _HeldItemsList(items: heldItems),
                      _MissingItemsList(items: missingItems),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        _BottomActionBar(
          onPressed: () {
            // Navigate to Manual Creator
             context.push('/basket/creator', extra: {
                'opportunity': opportunity,
                'userId': userId,
                'portfolioId': portfolioId,
              });
          },
        ),
      ],
    );
  }
}

class _EntryHeroCard extends StatelessWidget {
  final BasketOpportunity opportunity;

  const _EntryHeroCard({required this.opportunity});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.1),
            Theme.of(context).scaffoldBackgroundColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  opportunity.etfName,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Based on your holdings, you are ${opportunity.composition.length - opportunity.heldCount} stocks away from replicating this basket.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: CircularProgressIndicator(
                  value: opportunity.matchScore / 100,
                  strokeWidth: 8,
                  backgroundColor: Theme.of(context).dividerColor,
                  color: AppColors.success,
                ),
              ),
              Text(
                '${opportunity.matchScore.toStringAsFixed(0)}%',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeldItemsList extends StatelessWidget {
  final List<BasketItem> items;

  const _HeldItemsList({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(child: Text('No held items match this basket.'));
    }
    return ListView.builder(
      itemCount: items.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final item = items[index];
        return ListTile(
          leading: const Icon(Icons.check_circle, color: AppColors.success),
          title: Text(item.stockSymbol),
          subtitle: Text('Sector: ${item.sector}'),
          trailing: Text('${item.userWeight.toStringAsFixed(2)}%'),
        );
      },
    );
  }
}

class _MissingItemsList extends StatelessWidget {
  final List<BasketItem> items;

  const _MissingItemsList({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(child: Text('You have all items!'));
    }
    return ListView.builder(
      itemCount: items.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final item = items[index];
        final isSubstitute = item.status == ItemStatus.substitute;
        
        return Card(
          elevation: 0,
          color: isSubstitute ? AppColors.info.withOpacity(0.05) : AppColors.error.withOpacity(0.05),
           margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Icon(
              isSubstitute ? Icons.swap_horiz : Icons.add_circle_outline,
              color: isSubstitute ? AppColors.info : AppColors.error,
            ),
            title: Text(item.stockSymbol),
            subtitle: isSubstitute 
              ? Text('Substitute for: ${item.userHoldingSymbol} (${item.reason})')
              : Text('Required Weight: ${item.etfWeight?.toStringAsFixed(2)}%'),
             trailing: isSubstitute ? 
               Chip(label: Text('Proxy'), backgroundColor: AppColors.info.withOpacity(0.2)) : null,
          ),
        );
      },
    );
  }
}

class _BottomActionBar extends StatelessWidget {
  final VoidCallback onPressed;

  const _BottomActionBar({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: onPressed,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Customize & Create Portfolio'),
          ),
        ),
      ),
    );
  }
}
