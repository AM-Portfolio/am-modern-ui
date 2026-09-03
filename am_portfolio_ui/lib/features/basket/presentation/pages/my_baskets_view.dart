import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:intl/intl.dart';
import '../../domain/models/basket_enums.dart';
import '../../domain/models/tracking_basket.dart';
import '../../domain/models/basket_draft.dart';
import '../providers/basket_providers.dart';
import '../basket_navigation.dart';
import '../utils/basket_portfolio_sync.dart';
import '../utils/basket_api_errors.dart';
import '../flow/basket_flow_controller.dart';

enum _MyBasketsFilter { all, active, drafts }

class MyBasketsView extends ConsumerStatefulWidget {
  final String userId;
  final String portfolioId;

  const MyBasketsView({
    super.key,
    required this.userId,
    required this.portfolioId,
  });

  @override
  ConsumerState<MyBasketsView> createState() => _MyBasketsViewState();
}

class _MyBasketsViewState extends ConsumerState<MyBasketsView> {
  _MyBasketsFilter _filter = _MyBasketsFilter.all;

  Future<void> _refresh() async {
    ref.invalidate(
        myBasketsProvider(userId: widget.userId, portfolioId: ''));
    ref.invalidate(basketDraftsProvider((
      userId: widget.userId,
      portfolioId: widget.portfolioId,
    )));
    await Future.wait([
      ref.read(myBasketsProvider(userId: widget.userId, portfolioId: '').future),
      ref.read(basketDraftsProvider((
        userId: widget.userId,
        portfolioId: widget.portfolioId,
      )).future),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final basketsAsync = ref.watch(
      myBasketsProvider(userId: widget.userId, portfolioId: ''),
    );
    final draftsAsync = ref.watch(basketDraftsProvider((
      userId: widget.userId,
      portfolioId: widget.portfolioId,
    )));

    if (basketsAsync.isLoading && draftsAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (basketsAsync.hasError && draftsAsync.hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: AppSpacing.md),
            Text('Failed to load baskets',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            TextButton(onPressed: _refresh, child: const Text('Retry')),
          ],
        ),
      );
    }

    final baskets = basketsAsync.asData?.value ?? const <TrackingBasket>[];
    final draftResult = draftsAsync.asData?.value;
    final drafts = draftResult?.drafts ?? const <BasketDraftSummary>[];
    final draftCount = draftResult?.draftCount ?? drafts.length;
    final draftLimit = draftResult?.draftLimit ?? 5;

    final showDrafts = _filter != _MyBasketsFilter.active;
    final showActive = _filter != _MyBasketsFilter.drafts;
    final visibleDrafts = showDrafts ? drafts : const <BasketDraftSummary>[];
    final visibleActive = showActive ? baskets : const <TrackingBasket>[];

    if (visibleDrafts.isEmpty && visibleActive.isEmpty) {
      return Column(
        children: [
          _buildFilterBar(context, draftCount, draftLimit),
          Expanded(child: _buildEmptyState(context)),
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final int crossAxisCount;
        if (constraints.maxWidth >= 1050) {
          crossAxisCount = 3;
        } else if (constraints.maxWidth >= 680) {
          crossAxisCount = 2;
        } else {
          crossAxisCount = 1;
        }

        return RefreshIndicator(
          onRefresh: _refresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _buildFilterBar(context, draftCount, draftLimit),
              ),
              if (visibleDrafts.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.sm),
                    child: Text(
                      'Drafts',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: AppSpacing.md,
                      mainAxisSpacing: AppSpacing.md,
                      childAspectRatio: crossAxisCount == 1 ? 1.4 : 1.05,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _DraftBasketCard(
                        draft: visibleDrafts[index],
                        userId: widget.userId,
                        portfolioId: widget.portfolioId,
                        onChanged: _refresh,
                      ),
                      childCount: visibleDrafts.length,
                    ),
                  ),
                ),
              ],
              if (visibleActive.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md, AppSpacing.lg, AppSpacing.md, AppSpacing.sm),
                    child: Text(
                      'Active',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: AppSpacing.md,
                      mainAxisSpacing: AppSpacing.md,
                      childAspectRatio: crossAxisCount == 1 ? 1.4 : 1.05,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _TrackingBasketCard(
                        basket: visibleActive[index],
                        userId: widget.userId,
                        portfolioId: widget.portfolioId,
                      ),
                      childCount: visibleActive.length,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterBar(BuildContext context, int draftCount, int draftLimit) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: AppSpacing.sm,
              children: [
                ChoiceChip(
                  label: const Text('All'),
                  selected: _filter == _MyBasketsFilter.all,
                  onSelected: (_) =>
                      setState(() => _filter = _MyBasketsFilter.all),
                ),
                ChoiceChip(
                  label: const Text('Active'),
                  selected: _filter == _MyBasketsFilter.active,
                  onSelected: (_) =>
                      setState(() => _filter = _MyBasketsFilter.active),
                ),
                ChoiceChip(
                  label: const Text('Drafts'),
                  selected: _filter == _MyBasketsFilter.drafts,
                  onSelected: (_) =>
                      setState(() => _filter = _MyBasketsFilter.drafts),
                ),
              ],
            ),
          ),
          Text(
            'Drafts $draftCount/$draftLimit',
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(color: context.colors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final isDraftsOnly = _filter == _MyBasketsFilter.drafts;
    final isActiveOnly = _filter == _MyBasketsFilter.active;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_basket_outlined,
              size: 64, color: context.colors.textDisabled),
          const SizedBox(height: AppSpacing.md),
          Text(
            isDraftsOnly
                ? 'No Drafts'
                : isActiveOnly
                    ? 'No Active Baskets'
                    : 'No Baskets Tracked',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: context.colors.textDisabled),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            isDraftsOnly
                ? 'Save a draft from Customize to continue later.'
                : 'Create a basket to see it tracked here.',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: context.colors.textDisabled),
          ),
        ],
      ),
    );
  }
}

class _DraftBasketCard extends ConsumerWidget {
  final BasketDraftSummary draft;
  final String userId;
  final String portfolioId;
  final Future<void> Function() onChanged;

  const _DraftBasketCard({
    required this.draft,
    required this.userId,
    required this.portfolioId,
    required this.onChanged,
  });

  Future<void> _continue(BuildContext context, WidgetRef ref) async {
    final flow = ref.read(basketFlowControllerProvider);
    if (flow.isDirty &&
        flow.currentOpportunity != null &&
        flow.currentOpportunity!.etfIsin != draft.etfIsin) {
      final keep = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Unsaved changes'),
          content: const Text(
              'You have unsaved edits on another basket. Discard them and continue this draft?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(c).pop(false),
              child: const Text('Keep editing'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(c).pop(true),
              child: const Text('Discard'),
            ),
          ],
        ),
      );
      if (keep != true) return;
    }

    if (draft.sourcePortfolioId.isNotEmpty &&
        draft.sourcePortfolioId != portfolioId) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'This draft belongs to a different portfolio. Switch portfolio to continue.'),
          ),
        );
      }
      return;
    }

    try {
      final repository = await ref.read(basketRepositoryProvider.future);
      final detail =
          await repository.getDraft(draftId: draft.id, userId: userId);
      final opportunity = detail.opportunity;
      if (opportunity == null) {
        throw Exception('Draft is missing composition snapshot');
      }

      ref.read(basketFlowControllerProvider.notifier).restoreFromDraft(
            opportunity: opportunity,
            excludedSymbols: detail.excludedSymbols.toSet(),
            manualQtyOverrides: detail.manualQtyOverrides,
            investmentAmount: detail.investmentAmount ?? 0,
            basketName: detail.basketName ?? 'My ${detail.etfName ?? 'ETF'} Basket',
            hasCalculated: detail.hasCalculated,
            draftId: detail.id,
          );

      if (!context.mounted) return;
      BasketNavigation.openCreatorFromDraft(
        context,
        opportunity: opportunity,
        userId: userId,
        portfolioId: portfolioId,
        draftId: detail.id,
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(basketApiErrorMessage(e)),
          backgroundColor: context.statusError,
        ),
      );
    }
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete Draft?'),
        content: const Text('Are you sure you want to delete this draft?'),
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
                final repository =
                    await ref.read(basketRepositoryProvider.future);
                await repository.deleteDraft(draftId: draft.id, userId: userId);
                final flow = ref.read(basketFlowControllerProvider);
                if (flow.draftId == draft.id) {
                  ref.read(basketFlowControllerProvider.notifier).resetFlow();
                }
                await onChanged();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Draft deleted'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(basketApiErrorMessage(e)),
                      backgroundColor: Colors.red,
                    ),
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
    const draftColor = Colors.amber;

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
          onTap: () => _continue(context, ref),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: draftColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: draftColor.withOpacity(0.4)),
                      ),
                      child: const Text(
                        'DRAFT',
                        style: TextStyle(
                          color: Color(0xFFB45309),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (draft.etfIsin.isNotEmpty)
                      Text(
                        draft.etfIsin,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: colors.textSecondary),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        draft.basketName ??
                            draft.etfName ??
                            'Untitled draft',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold, height: 1.2),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      if (draft.updatedAt != null)
                        Text(
                          'Saved on ${DateFormat('MMM dd, yyyy').format(draft.updatedAt!)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: colors.textSecondary,
                                fontSize: 11,
                              ),
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Planned investment',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: colors.textSecondary,
                            fontSize: 11,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '₹${draft.investmentAmount != null ? NumberFormat('#,##,##0').format(draft.investmentAmount!) : '—'}',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                    ),
                    if (draft.replicaScore != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Match ${draft.replicaScore!.toStringAsFixed(0)}%',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: colors.textSecondary,
                            ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Divider(height: 1, color: colors.border.withOpacity(0.5)),
                const SizedBox(height: AppSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Continue customize',
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.arrow_forward,
                            size: 14,
                            color: Theme.of(context).colorScheme.primary),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: Colors.redAccent, size: 20),
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
        content: const Text(
            'Are you sure you want to delete this basket? This cannot be undone.'),
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
                await ref.read(deleteBasketProvider(
                        basketId: basket.basketId, userId: userId)
                    .future);
                ref.invalidate(
                    myBasketsProvider(userId: userId, portfolioId: ''));
                if (context.mounted) {
                  await BasketPortfolioSync.afterBasketMutation(
                    context,
                    deletedBasketId: basket.basketId,
                  );
                }
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Basket deleted'),
                        backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            'Failed to delete basket: ${basketApiErrorMessage(e)}'),
                        backgroundColor: Colors.red),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: statusColor.withOpacity(0.3)),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                            color: statusColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (basket.etfIsin != null && basket.etfIsin!.isNotEmpty)
                      Text(
                        basket.etfIsin!,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: colors.textSecondary),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        basket.etfName ?? 'Unnamed Basket',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold, height: 1.2),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      if (basket.createdAt != null)
                        Text(
                          'Created on ${DateFormat('MMM dd, yyyy').format(basket.createdAt!)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: colors.textSecondary,
                                fontSize: 11,
                              ),
                        ),
                    ],
                  ),
                ),
                Column(
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
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Divider(height: 1, color: colors.border.withOpacity(0.5)),
                const SizedBox(height: AppSpacing.md),
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
                        Icon(Icons.arrow_forward,
                            size: 14,
                            color: Theme.of(context).colorScheme.primary),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: Colors.redAccent, size: 20),
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
