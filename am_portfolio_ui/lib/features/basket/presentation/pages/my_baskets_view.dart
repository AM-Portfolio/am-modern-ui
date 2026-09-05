import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:intl/intl.dart';
import '../../domain/models/basket_enums.dart';
import '../../domain/models/tracking_basket.dart';
import '../../domain/models/basket_draft.dart';
import '../providers/basket_providers.dart';
import '../basket_navigation.dart';
import '../shared/basket_panel_styles.dart';
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
        Widget draftSection() {
          if (visibleDrafts.isEmpty) return const SizedBox.shrink();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
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
              ...visibleDrafts.map(
                (d) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: _DraftBasketCard(
                    draft: d,
                    userId: widget.userId,
                    portfolioId: widget.portfolioId,
                    onChanged: _refresh,
                  ),
                ),
              ),
            ],
          );
        }

        Widget activeSection() {
          if (visibleActive.isEmpty) return const SizedBox.shrink();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
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
              ...visibleActive.map(
                (b) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: _TrackingBasketCard(
                    basket: b,
                    userId: widget.userId,
                    portfolioId: widget.portfolioId,
                  ),
                ),
              ),
            ],
          );
        }

        return RefreshIndicator(
          onRefresh: _refresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _buildFilterBar(context, draftCount, draftLimit),
              ),
              SliverToBoxAdapter(child: draftSection()),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: activeSection(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterBar(BuildContext context, int draftCount, int draftLimit) {
    final accent = ModuleColors.portfolio;

    Widget filterChip({
      required String label,
      required bool selected,
      required VoidCallback onSelected,
    }) {
      return Theme(
        data: BasketPanelStyles.accentTheme(context),
        child: ChoiceChip(
          label: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: selected ? accent : context.colors.textSecondary,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
          ),
          selected: selected,
          onSelected: (_) => onSelected(),
          showCheckmark: selected,
          selectedColor: accent.withValues(alpha: 0.18),
          backgroundColor: context.colors.cardSurface,
          checkmarkColor: accent,
          side: BorderSide(
            color: selected
                ? accent.withValues(alpha: 0.45)
                : context.colors.border,
          ),
          shape: RoundedRectangleBorder(borderRadius: AppRadii.button),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: AppSpacing.sm,
              children: [
                filterChip(
                  label: 'All',
                  selected: _filter == _MyBasketsFilter.all,
                  onSelected: () =>
                      setState(() => _filter = _MyBasketsFilter.all),
                ),
                filterChip(
                  label: 'Active',
                  selected: _filter == _MyBasketsFilter.active,
                  onSelected: () =>
                      setState(() => _filter = _MyBasketsFilter.active),
                ),
                filterChip(
                  label: 'Drafts',
                  selected: _filter == _MyBasketsFilter.drafts,
                  onSelected: () =>
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
    final theme = Theme.of(context);
    final colors = context.colors;
    // Prefer ETF name so cards read like Discover.
    final title =
        draft.etfName ?? draft.basketName ?? 'Untitled draft';
    final initial = title.isNotEmpty ? title[0].toUpperCase() : 'D';
    final money = NumberFormat('#,##,##0');
    final planned = draft.investmentAmount != null
        ? '₹${money.format(draft.investmentAmount!)}'
        : '—';
    final score = (draft.replicaScore ?? 0).clamp(0, 100);
    final scoreColor = score >= 70
        ? context.statusSuccess
        : score >= 40
            ? context.statusWarning
            : context.statusError;
    final dateLabel = draft.updatedAt != null
        ? DateFormat('MMM dd, yyyy').format(draft.updatedAt!)
        : null;
    final metaParts = <String>[
      'Draft',
      if (dateLabel != null) dateLabel,
    ];

    Widget metric({
      required String label,
      required String value,
      Color? valueColor,
    }) {
      return Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colors.textTertiary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: valueColor ?? colors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: colors.cardSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.card,
          side: BorderSide(color: colors.border),
        ),
        child: InkWell(
          onTap: () => _continue(context, ref),
          onLongPress: () => _confirmDelete(context, ref),
          borderRadius: AppRadii.card,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor:
                          ModuleColors.portfolio.withValues(alpha: 0.15),
                      child: Text(
                        initial,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: ModuleColors.portfolio,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm + 2),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            metaParts.join(' · '),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm + 2),
                Row(
                  children: [
                    metric(
                      label: 'Coverage',
                      value: draft.replicaScore != null
                          ? '${score.toStringAsFixed(0)}%'
                          : '—',
                      valueColor: draft.replicaScore != null
                          ? scoreColor
                          : colors.textTertiary,
                    ),
                    metric(
                      label: 'Invested',
                      value: planned,
                    ),
                    metric(
                      label: 'P&L',
                      value: '—',
                      valueColor: colors.textTertiary,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Continue customize',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: ModuleColors.portfolio,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: ModuleColors.portfolio,
                      size: 20,
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
    final theme = Theme.of(context);
    final colors = context.colors;
    final statusText = _getStatusText(basket.status);
    final title = basket.etfName ?? 'Unnamed Basket';
    final initial = title.isNotEmpty ? title[0].toUpperCase() : 'B';
    final money = NumberFormat('#,##,##0');
    final pct = NumberFormat('+0.00;-0.00');

    final coverage = basket.displayCoveragePercent.clamp(0, 100);
    final coverageColor = coverage >= 70
        ? context.statusSuccess
        : coverage >= 40
            ? context.statusWarning
            : context.statusError;

    final investedLabel = basket.investmentAmount != null
        ? '₹${money.format(basket.investmentAmount!)}'
        : '—';

    final pnl = basket.totalPnL;
    final pnlPct = basket.pnlPercent;
    final hasPnl = pnl != null;
    final pnlColor = !hasPnl
        ? colors.textTertiary
        : pnl! >= 0
            ? context.statusSuccess
            : context.statusError;
    final pnlLabel = !hasPnl
        ? '—'
        : '${pnl >= 0 ? '+' : '-'}₹${money.format(pnl.abs())}';
    final pnlPctLabel = pnlPct != null ? '${pct.format(pnlPct)}%' : null;

    final dateLabel = basket.createdAt != null
        ? DateFormat('MMM dd, yyyy').format(basket.createdAt!)
        : null;
    final metaParts = <String>[
      statusText.toLowerCase(),
      if (dateLabel != null) dateLabel,
    ];

    Widget metric({
      required String label,
      required String value,
      Color? valueColor,
      String? subtitle,
    }) {
      return Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colors.textTertiary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: valueColor ?? colors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (subtitle != null)
              Text(
                subtitle,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: valueColor ?? colors.textTertiary,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: colors.cardSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.card,
          side: BorderSide(color: colors.border),
        ),
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
          onLongPress: () => _confirmDelete(context, ref),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor:
                          ModuleColors.portfolio.withValues(alpha: 0.15),
                      child: Text(
                        initial,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: ModuleColors.portfolio,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm + 2),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            metaParts.join(' · '),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm + 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    metric(
                      label: 'Coverage',
                      value: '${coverage.toStringAsFixed(0)}%',
                      valueColor: coverageColor,
                    ),
                    metric(
                      label: 'Invested',
                      value: investedLabel,
                    ),
                    metric(
                      label: 'P&L',
                      value: pnlLabel,
                      valueColor: pnlColor,
                      subtitle: hasPnl ? pnlPctLabel : null,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'View details',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: ModuleColors.portfolio,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: ModuleColors.portfolio,
                      size: 20,
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
