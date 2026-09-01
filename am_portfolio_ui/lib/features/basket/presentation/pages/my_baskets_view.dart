import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:intl/intl.dart';
import 'package:am_common/am_common.dart';
import '../../domain/models/basket_enums.dart';
import '../../domain/models/tracking_basket.dart';
import '../providers/basket_providers.dart';
import '../basket_navigation.dart';
import '../utils/basket_portfolio_sync.dart';

class MyBasketsView extends ConsumerWidget {
  final String userId;
  final String portfolioId;

  const MyBasketsView({
    super.key,
    required this.userId,
    required this.portfolioId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final basketsAsyncValue = ref.watch(
      myBasketsProvider(userId: userId, portfolioId: ''),
    );

    return basketsAsyncValue.when(
      data: (baskets) {
        if (baskets.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shopping_basket_outlined, size: 64, color: context.colors.textDisabled),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'No Baskets Tracked',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: context.colors.textDisabled),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Create a basket to see it tracked here.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.colors.textDisabled),
                ),
              ],
            ),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            // 3 columns on desktop/web, 2 on tablet, 1 on mobile
            final int crossAxisCount;
            if (constraints.maxWidth >= 1050) {
              crossAxisCount = 3;
            } else if (constraints.maxWidth >= 680) {
              crossAxisCount = 2;
            } else {
              crossAxisCount = 1;
            }

            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(myBasketsProvider(userId: userId, portfolioId: ''));
                return ref.read(myBasketsProvider(userId: userId, portfolioId: '').future);
              },
              child: GridView.builder(
                padding: const EdgeInsets.all(AppSpacing.md),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: AppSpacing.md,
                  mainAxisSpacing: AppSpacing.md,
                  childAspectRatio: crossAxisCount == 1 ? 1.4 : 1.05,
                ),
                itemCount: baskets.length,
                itemBuilder: (context, index) {
                  final basket = baskets[index];
                  return _TrackingBasketCard(
                    basket: basket,
                    userId: userId,
                    portfolioId: portfolioId,
                  );
                },
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: AppSpacing.md),
            Text('Failed to load baskets', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: () => ref.invalidate(myBasketsProvider(userId: userId, portfolioId: '')),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrackingBasketCard extends ConsumerWidget {
  final TrackingBasket basket;
  final String userId;
  final String portfolioId;

  const _TrackingBasketCard({
    required this.basket,
    required this.userId,
    required this.portfolioId,
  });

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete Basket?'),
        content: const Text('Are you sure you want to delete this basket? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.of(c).pop();
              try {
                await ref.read(deleteBasketProvider(basketId: basket.basketId, userId: userId).future);
                ref.invalidate(myBasketsProvider(userId: userId, portfolioId: ''));
                if (context.mounted) {
                  await BasketPortfolioSync.afterBasketMutation(
                    context,
                    deletedBasketId: basket.basketId,
                  );
                }
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Basket deleted'), backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete basket: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final statusColor = _getStatusColor(basket.status);
    final statusText = _getStatusText(basket.status);

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppRadii.card,
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: AppRadii.card,
          onTap: () {
            if (basket.basketId.isNotEmpty) {
              BasketNavigation.openDashboard(
                context,
                basketId: basket.basketId,
                userId: userId,
                portfolioId: portfolioId,
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Top Section (Status + ISIN)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: statusColor.withOpacity(0.3)),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (basket.etfIsin != null && basket.etfIsin!.isNotEmpty)
                      Text(
                        basket.etfIsin!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.textSecondary),
                      ),
                  ],
                ),
                
                const SizedBox(height: AppSpacing.md),

                // 2. Title Section
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        basket.etfName ?? 'Unnamed Basket',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, height: 1.2),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      if (basket.createdAt != null)
                        Text(
                          'Created on ${DateFormat('MMM dd, yyyy').format(basket.createdAt!)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.textSecondary, fontSize: 11),
                        ),
                    ],
                  ),
                ),

                // 3. Value Section
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Value',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(color: colors.textSecondary, fontSize: 11),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '₹${basket.totalValue != null ? NumberFormat('#,##,##0.00').format(basket.totalValue!) : '0.00'}',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, letterSpacing: -0.5),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.md),
                Divider(height: 1, color: colors.border.withOpacity(0.5)),
                const SizedBox(height: AppSpacing.md),

                // 4. Action Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          'View Details',
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.arrow_forward, size: 14, color: Theme.of(context).colorScheme.primary),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                      onPressed: () => _confirmDelete(context, ref),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(BasketStatus status) {
    switch (status) {
      case BasketStatus.active:
      case BasketStatus.completed:
        return Colors.green;
      case BasketStatus.partially_filled:
        return Colors.orange;
      case BasketStatus.failed:
        return Colors.red;
      case BasketStatus.pending:
        return Colors.blue;
      default:
        return Colors.green;
    }
  }

  String _getStatusText(BasketStatus status) {
    switch (status) {
      case BasketStatus.active:
        return 'ACTIVE';
      case BasketStatus.completed:
        return 'COMPLETED';
      case BasketStatus.partially_filled:
        return 'UNDERFUNDED';
      case BasketStatus.failed:
        return 'FAILED';
      case BasketStatus.pending:
        return 'PENDING';
      default:
        return 'ACTIVE';
    }
  }
}
