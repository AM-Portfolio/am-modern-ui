import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:go_router/go_router.dart';
import '../providers/basket_providers.dart';
import '../../domain/models/basket_opportunity.dart';
import 'etf_search_bar.dart';

class BasketExplorer extends ConsumerStatefulWidget {
  final String userId;
  final String portfolioId;

  const BasketExplorer({
    super.key,
    required this.userId,
    required this.portfolioId,
  });

  @override
  ConsumerState<BasketExplorer> createState() => _BasketExplorerState();
}

class _BasketExplorerState extends ConsumerState<BasketExplorer> {
  String _query = 'Nifty 50,Nifty Bank,Nifty IT'; // Default query
  
  final Map<String, String> _categories = {
    'Nifty 50': 'NIFTY 50',
    'Bank': 'NIFTY BANK', 
    'IT': 'NIFTY IT',
    'Auto': 'NIFTY AUTO',
    'Metal': 'NIFTY METAL',
    'FMCG': 'NIFTY FMCG',
    'Pharma': 'NIFTY PHARMA',
    'Gold': 'GOLD',
    'PSU Bank': 'NIFTY PSU BANK',
  };
    
  String? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    // Use the current query state
    final opportunitiesAsync = ref.watch(basketOpportunitiesProvider(
      userId: widget.userId,
      portfolioId: widget.portfolioId,
      query: _query,
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
                  // Reset query to default
                  setState(() {
                    _query = 'Nifty 50,Nifty Bank,Nifty IT';
                    _selectedCategory = null;
                  });
                },
                child: const Text('Reset'),
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
                if (selection.isin!.contains(',')) {
                   // If multiple ISINs, update the list
                   setState(() {
                     _query = selection.isin!;
                   });
                } else {
                  // If single ISIN, navigate to preview
                  context.push('/portfolio/basket/preview', extra: {
                    'etfIsin': selection.isin,
                    'userId': widget.userId,
                    'portfolioId': widget.portfolioId,
                  });
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Error: Selected ETF has no ISIN')),
                );
              }
            },
          ),
        ),

        // Quick Select Categories
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Wrap(
              spacing: 8.0,
              children: _categories.entries.map((entry) {
                final isSelected = _selectedCategory == entry.key;
                return FilterChip(
                  label: Text(entry.key),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedCategory = entry.key;
                        _query = entry.value;
                      } else {
                        // If unselected, go back to default or keep current?
                        // Usually resetting to default makes sense
                        _selectedCategory = null;
                        _query = 'Nifty 50,Nifty Bank,Nifty IT';
                      }
                    });
                  },
                  backgroundColor: Theme.of(context).cardColor,
                  selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: isSelected ? Theme.of(context).primaryColor : null,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected 
                          ? Theme.of(context).primaryColor 
                          : Theme.of(context).dividerColor.withOpacity(0.5),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        const SizedBox(height: 12),
        Expanded(
          child: opportunitiesAsync.when(
            data: (opportunities) {
              if (opportunities.isEmpty) {
                return const Center(child: Text('No opportunities found'));
              }
              return GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 300,
                  mainAxisExtent: 180, // Fixed height for cards
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: opportunities.length,
                itemBuilder: (context, index) {
                  return _BasketOpportunityCard(
                    opportunity: opportunities[index],
                    onTap: () {
                      context.push('/portfolio/basket/preview', extra: {
                        'etfIsin': opportunities[index].etfIsin,
                        'userId': widget.userId,
                        'portfolioId': widget.portfolioId,
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
    return Card(
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
    );
  }
}
