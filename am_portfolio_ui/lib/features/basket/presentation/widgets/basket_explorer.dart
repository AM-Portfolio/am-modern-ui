import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:go_router/go_router.dart';
import '../providers/basket_providers.dart';
import '../../domain/models/basket_opportunity.dart';
import 'etf_search_bar.dart';

class BasketExplorer extends ConsumerWidget {
  final String userId;
  final String portfolioId;

  const BasketExplorer({
    super.key,
    required this.userId,
    required this.portfolioId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use a default query of major indices if no specific query is meant to be provided
    // This matches user requirement to suggested indices
    final opportunitiesAsync = ref.watch(basketOpportunitiesProvider(
      userId: userId,
      portfolioId: portfolioId,
      query: 'Nifty 50,Nifty Bank,Nifty IT', // Default query
    ));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Basket Opportunities',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  // Navigate to full list if implemented
                },
                child: const Text('View All'),
              ),
            ],
          ),
        ),
        
        // ETF Search Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: EtfSearchBar(
            onEtfSelected: (selection) {
              if (selection.isin != null) {
                context.push('/portfolio/basket/preview', extra: {
                  'etfIsin': selection.isin,
                  'userId': userId,
                  'portfolioId': portfolioId,
                });
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Error: Selected ETF has no ISIN')),
                );
              }
            },
          ),
        ),
        
        const SizedBox(height: 12),
        SizedBox(
          height: 220,
          child: opportunitiesAsync.when(
            data: (opportunities) {
              if (opportunities.isEmpty) {
                return const Center(child: Text('No opportunities found'));
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                scrollDirection: Axis.horizontal,
                itemCount: opportunities.length,
                itemBuilder: (context, index) {
                  return _BasketOpportunityCard(
                    opportunity: opportunities[index],
                    onTap: () {
                      context.push('/portfolio/basket/preview', extra: {
                        'etfIsin': opportunities[index].etfIsin,
                        'userId': userId,
                        'portfolioId': portfolioId,
                      });
                    },
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error: $err')),
          ),
        ),
      ],
    );
  }
}

class _BasketOpportunityCard extends StatelessWidget {
  final BasketOpportunity opportunity;
  final VoidCallback onTap;

  const _BasketOpportunityCard({
    required this.opportunity,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      width: 180,
      margin: const EdgeInsets.only(right: 12.0, bottom: 8.0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${opportunity.matchScore.toStringAsFixed(0)}% Match',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  opportunity.etfName,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                Row(
                  children: [
                     Icon(
                      Icons.inventory_2_outlined,
                      size: 16,
                      color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${opportunity.missingCount} missing',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (opportunity.readyToReplicate)
                Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8)
                    ),
                    child: Center(
                        child: Text("Replicate",
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.white)
                        )
                    )
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
