import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:intl/intl.dart';
import 'package:am_common/am_common.dart';
import '../../domain/models/basket_enums.dart';
import '../../domain/models/tracking_basket.dart';
import '../providers/basket_providers.dart';
import '../basket_navigation.dart';

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

    return Card(
      shape: RoundedRectangleBorder(borderRadius: AppRadii.card),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      color: colors.surface,
      child: InkWell(
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
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 1. Top Row: Title + Status
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          basket.etfName ?? 'Unnamed Basket',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                height: 1.2,
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: statusColor.withOpacity(0.4), width: 1),
                        ),
                        child: Text(
                          statusText,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (basket.etfIsin != null && basket.etfIsin!.isNotEmpty) ...[
                        Text(
                          'ISIN: ${basket.etfIsin}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: colors.textSecondary,
                                fontSize: 11,
                              ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                      ],
                      if (basket.createdAt != null)
                        Text(
                          DateFormat('MMM dd, yyyy').format(basket.createdAt!),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: colors.textSecondary,
                                fontSize: 11,
                              ),
                        ),
                    ],
                  ),
                ],
              ),

              // 2. Middle Value Section
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Value',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: colors.textSecondary,
                            fontSize: 11,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '₹${basket.totalValue != null ? NumberFormat('#,##,##0.00').format(basket.totalValue!) : '0.00'}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                    ),
                  ],
                ),
              ),

              // 3. Progress Section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Fill Progress',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: colors.textSecondary,
                              fontSize: 11,
                            ),
                      ),
                      Text(
                        '${basket.activeLines} / ${basket.totalLines} lines',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: basket.totalLines == 0 ? 0 : basket.activeLines / basket.totalLines,
                      backgroundColor: colors.border,
                      valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),

              // 4. Bottom Row: Action / Details & Delete
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        'View Dashboard',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(width: 2),
                      Icon(Icons.arrow_forward_ios, size: 10, color: Theme.of(context).colorScheme.primary),
                    ],
                  ),
                  InkWell(
                    onTap: () => _confirmDelete(context, ref),
                    borderRadius: BorderRadius.circular(6),
                    child: const Padding(
                      padding: EdgeInsets.all(4.0),
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, color: Colors.redAccent, size: 16),
                          SizedBox(width: 2),
                          Text(
                            'Delete',
                            style: TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
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
