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

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          _EntryHeroCard(opportunity: opportunity),
          Container(
             margin: const EdgeInsets.symmetric(horizontal: 16),
             decoration: BoxDecoration(
               border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
             ),
             child: TabBar(
               labelColor: AppColors.primary,
               unselectedLabelColor: Theme.of(context).hintColor,
               indicatorColor: AppColors.primary,
               indicatorWeight: 3,
               labelStyle: const TextStyle(fontWeight: FontWeight.bold),
               tabs: [
                 Tab(text: "Your Match (${heldItems.length})"),
                 Tab(text: "The Gap (${missingItems.length})"),
               ],
             ),
           ),
          Expanded(
            child: TabBarView(
              children: [
                _HeldItemsList(items: heldItems),
                _MissingItemsList(items: missingItems),
              ],
            ),
          ),
          _BottomActionBar(
            onPressed: () {
              // Navigate to Manual Creator
               context.push('/portfolio/basket/creator', extra: {
                  'opportunity': opportunity,
                  'userId': userId,
                  'portfolioId': portfolioId,
                });
            },
          ),
        ],
      ),
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
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
                 const SizedBox(height: 12),
                 Row(
                   children: [
                     _ScoreBadge(label: "Match Score", score: opportunity.matchScore, color: AppColors.primary),
                     const SizedBox(width: 12),
                     _ScoreBadge(label: "Replica Score", score: opportunity.replicaScore, color: AppColors.success),
                   ],
                 )
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  final String label;
  final double score;
  final Color color;

  const _ScoreBadge({required this.label, required this.score, required this.color});

  @override
  Widget build(BuildContext context) {
     return Container(
       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
       decoration: BoxDecoration(
         color: color.withOpacity(0.1),
         borderRadius: BorderRadius.circular(8),
         border: Border.all(color: color.withOpacity(0.3)),
       ),
       child: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
           Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color)),
           Text("${score.toStringAsFixed(1)}%", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: color)),
         ],
       ),
     );
  }
}

class _BasketItemHeader extends StatelessWidget {
  const _BasketItemHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).canvasColor,
        border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        children: [
          Expanded(flex: 4, child: Text("Instrument", style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).hintColor))),
          Expanded(flex: 1, child: Text("ETF %", textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).hintColor))),
          Expanded(flex: 1, child: Text("Your %", textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).hintColor))),
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
      return const Center(child: Padding(
        padding: EdgeInsets.all(20.0),
        child: Text('No held items match this basket.'),
      ));
    }
    return Column(
      children: [
        const _BasketItemHeader(),
        Expanded(
          child: ListView.separated(
            itemCount: items.length,
            separatorBuilder: (c, i) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = items[index];
              final isSubstitute = item.status == ItemStatus.substitute;
              
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: isSubstitute ? AppColors.info.withOpacity(0.05) : null,
                child: Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.stockSymbol, style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text(
                            "${item.sector} ${item.marketCapCategory != null ? '• ${item.marketCapCategory}' : ''}",
                            style: Theme.of(context).textTheme.bodySmall
                          ),
                          if (isSubstitute)
                             Padding(
                               padding: const EdgeInsets.only(top: 4.0),
                               child: Text("Using: ${item.userHoldingSymbol} (Sub)", style: TextStyle(fontSize: 11, color: AppColors.info, fontStyle: FontStyle.italic)),
                             )
                        ],
                      )
                    ),
                    Expanded(
                      flex: 1,
                      child: Text("${item.etfWeight.toStringAsFixed(2)}%", textAlign: TextAlign.right)
                    ),
                     Expanded(
                      flex: 1,
                      child: Text("${item.userWeight.toStringAsFixed(2)}%", textAlign: TextAlign.right, 
                        style: TextStyle(fontWeight: FontWeight.bold, color: item.userWeight < item.etfWeight ? AppColors.warning : AppColors.success))
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MissingItemsList extends StatelessWidget {
  final List<BasketItem> items;

  const _MissingItemsList({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(20.0),
        child: Text('You have all items!'),
      ));
    }
    return Column(
      children: [
        const _BasketItemHeader(),
        Expanded(
          child: ListView.separated(
            itemCount: items.length,
            separatorBuilder: (c, i) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = items[index];
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.stockSymbol, style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text(
                             "${item.sector} ${item.marketCapCategory != null ? '• ${item.marketCapCategory}' : ''}",
                             style: Theme.of(context).textTheme.bodySmall
                          ),
                        ],
                      )
                    ),
                     Expanded(
                      flex: 1,
                      child: Text("${item.etfWeight.toStringAsFixed(2)}%", textAlign: TextAlign.right)
                    ),
                    Expanded(
                      flex: 1,
                      child: Text("-", textAlign: TextAlign.right, style: TextStyle(color: Theme.of(context).disabledColor))
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
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
