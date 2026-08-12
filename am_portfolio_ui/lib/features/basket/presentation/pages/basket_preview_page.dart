import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:am_design_system/am_design_system.dart';
import '../providers/basket_providers.dart';
import '../basket_navigation.dart';
import '../widgets/basket_section_header.dart';
import '../../domain/models/basket_opportunity.dart';
import '../widgets/substitute_selector.dart';
import '../../domain/models/stock_search_result.dart';

class BasketPreviewPage extends ConsumerWidget {
  final String etfIsin;
  final String userId;
  final String portfolioId;
  final bool embedded;

  const BasketPreviewPage({
    super.key,
    required this.etfIsin,
    required this.userId,
    required this.portfolioId,
    this.embedded = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final opportunityAsync = ref.watch(basketPreviewProvider(
      etfIsin: etfIsin,
      userId: userId,
      portfolioId: portfolioId,
    ));

    final body = opportunityAsync.when(
      data: (opportunity) => _BasketContent(
        initial: opportunity,
        etfIsin: etfIsin,
        userId: userId,
        portfolioId: portfolioId,
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );

    if (embedded) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BasketSectionHeader(
            title: 'Basket Preview',
            onBack: () => Navigator.of(context).pop(),
          ),
          Expanded(child: body),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Basket Preview'),
        centerTitle: false,
      ),
      body: body,
    );
  }
}

class _BasketContent extends ConsumerStatefulWidget {
  final BasketOpportunity initial;
  final String etfIsin;
  final String userId;
  final String portfolioId;

  const _BasketContent({
    required this.initial,
    required this.etfIsin,
    required this.userId,
    required this.portfolioId,
  });

  @override
  ConsumerState<_BasketContent> createState() => _BasketContentState();
}

class _BasketContentState extends ConsumerState<_BasketContent> {
  late BasketOpportunity _opportunity;
  final List<Map<String, String>> _assignments = [];
  bool _applying = false;

  @override
  void initState() {
    super.initState();
    _opportunity = widget.initial;
  }

  Future<void> _applyAssignments() async {
    setState(() => _applying = true);
    try {
      final repo = await ref.read(basketRepositoryProvider.future);
      final updated = await repo.applySubstitutes(
        etfIsin: widget.etfIsin,
        userId: widget.userId,
        portfolioId: widget.portfolioId,
        assignments: _assignments,
        currentOpportunity: _opportunity,
      );
      if (mounted) {
        setState(() => _opportunity = updated);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Swap failed: $e'), backgroundColor: context.statusError),
        );
      }
    } finally {
      if (mounted) setState(() => _applying = false);
    }
  }

  Future<void> _acceptSwap(BasketItem missing, Alternative alt) async {
    _assignments.removeWhere((a) => a['missingIsin'] == missing.isin);
    _assignments.add({
      'missingIsin': missing.isin,
      'substituteIsin': alt.isin,
    });
    await _applyAssignments();
  }

  Future<void> _showSwapSheet(BasketItem item) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.lg)),
      ),
      builder: (ctx) {
        final hasAlts = item.alternatives.isNotEmpty;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  hasAlts
                      ? 'Cover ${item.stockSymbol} with a holding you own'
                      : 'No pre-calculated alternatives for ${item.stockSymbol}',
                  style: Theme.of(ctx).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  hasAlts
                      ? 'Sector proxy — raises Match %, not an exact stock match. '
                          'Cross-sector picks are allowed when same-sector peers are used up.'
                      : 'You can manually search your portfolio for a holding to use as a substitute. This will increase your Match %.',
                  style: Theme.of(ctx).textTheme.bodySmall?.copyWith(color: ctx.textSecondary),
                ),
                const SizedBox(height: AppSpacing.md),
                if (hasAlts)
                  ...item.alternatives.map((alt) => ListTile(
                        title: Text(alt.symbol),
                        subtitle: Text(
                          'Weight ${alt.userWeight.toStringAsFixed(1)}%'
                          '${alt.quantity != null ? ' · Qty ${alt.quantity!.toStringAsFixed(0)}' : ''}',
                        ),
                        trailing: FilledButton(
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            _acceptSwap(item, alt);
                          },
                          child: const Text('Use this holding'),
                        ),
                      )),
                if (!hasAlts)
                  FilledButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      _openManualSubstituteSelector(item);
                    },
                    child: const Text('Swap Manually'),
                  ),
                if (!hasAlts) const SizedBox(height: AppSpacing.sm),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(hasAlts ? 'Cancel' : 'Got it'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openManualSubstituteSelector(BasketItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SubstituteSelector(
          originalSymbol: item.stockSymbol,
          requiredMarketCap: '', 
          onSelected: (StockSearchResult newStock) {
            Navigator.of(context).pop();
            // We need a BasketAlternative to pass to _acceptSwap.
            // Since it's a manual swap, we use the user's selected stock as the alternative.
            // Note: SubstituteSelector returns a StockSearchResult, which might not have the user's holding quantity.
            // The backend's applySubstitutes endpoint handles resolving it against userHoldings.
            final alt = Alternative(
              isin: newStock.isin ?? newStock.symbol, 
              symbol: newStock.symbol,
              userWeight: 100.0, // Backend will recalculate
              quantity: null,
            );
            _acceptSwap(item, alt);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final heldItems = _opportunity.composition
        .where((item) => item.status == ItemStatus.held)
        .toList();
    final substituteItems = _opportunity.composition
        .where((item) => item.status == ItemStatus.substitute)
        .toList();
    final missingItems = _opportunity.composition
        .where((item) => item.status == ItemStatus.missing)
        .toList();

    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          if (_applying) const LinearProgressIndicator(),
          _EntryHeroCard(opportunity: _opportunity),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
            ),
            child: TabBar(
              labelColor: context.colors.actionPrimaryBg,
              unselectedLabelColor: context.textSecondary,
              indicatorColor: context.colors.actionPrimaryBg,
              indicatorWeight: 3,
              isScrollable: true,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              tabs: [
                Tab(text: 'Held (${heldItems.length})'),
                Tab(text: 'Substitute (${substituteItems.length})'),
                Tab(text: 'Missing (${missingItems.length})'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _HeldItemsList(items: heldItems),
                _SubstituteItemsList(
                  items: substituteItems,
                  onUndo: (item) {
                    // User-applied only: remove from assignments if present
                    _assignments.removeWhere((a) => a['missingIsin'] == item.isin);
                    _applyAssignments();
                  },
                ),
                _MissingItemsList(
                  items: missingItems,
                  onSuggestSwap: _showSwapSheet,
                ),
              ],
            ),
          ),
          _BottomActionBar(
            onPressed: () {
              BasketNavigation.openCreator(
                context,
                opportunity: _opportunity,
                userId: widget.userId,
                portfolioId: widget.portfolioId,
              );
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
      margin: const EdgeInsets.all(AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            context.colors.actionPrimaryBg.withValues(alpha: 0.1),
            Theme.of(context).scaffoldBackgroundColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(opportunity.etfName, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              _ScoreChip(label: 'Match', value: '${opportunity.matchScore.toStringAsFixed(0)}%'),
              const SizedBox(width: AppSpacing.sm),
              _ScoreChip(label: 'Replica', value: '${opportunity.replicaScore.toStringAsFixed(0)}%'),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScoreChip extends StatelessWidget {
  final String label;
  final String value;
  const _ScoreChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text('$label $value'),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _HeldItemsList extends StatelessWidget {
  final List<BasketItem> items;
  final String? emptyMessage;

  const _HeldItemsList({required this.items, this.emptyMessage});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Text(emptyMessage ?? 'No held items'),
        ),
      );
    }
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = items[index];
        return ListTile(
          title: Text(item.stockSymbol, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(
            '${item.sector}${item.marketCapCategory != null ? ' • ${item.marketCapCategory}' : ''}'
            '${item.status == ItemStatus.substitute ? ' · Sector proxy' : ''}',
          ),
          trailing: Text('${item.etfWeight.toStringAsFixed(2)}%'),
        );
      },
    );
  }
}

class _SubstituteItemsList extends StatelessWidget {
  final List<BasketItem> items;
  final ValueChanged<BasketItem> onUndo;

  const _SubstituteItemsList({required this.items, required this.onUndo});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Text('No substitute holdings for this basket.'),
        ),
      );
    }
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = items[index];
        return ListTile(
          title: Text(item.stockSymbol, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(
            'Covered by ${item.userHoldingSymbol ?? '—'} · Sector proxy',
          ),
          trailing: item.reason?.startsWith('User swap') == true
              ? TextButton(onPressed: () => onUndo(item), child: const Text('Remove swap'))
              : Text('${item.etfWeight.toStringAsFixed(2)}%'),
        );
      },
    );
  }
}

class _MissingItemsList extends StatelessWidget {
  final List<BasketItem> items;
  final ValueChanged<BasketItem> onSuggestSwap;

  const _MissingItemsList({required this.items, required this.onSuggestSwap});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Text('You have all items!'),
        ),
      );
    }
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = items[index];
        final hasAlts = item.alternatives.isNotEmpty;
        return ListTile(
          title: Text(item.stockSymbol, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(
            hasAlts
                ? '${item.sector} · Tap Suggest swap'
                : '${item.sector} · No auto-alternatives (Tap Swap)',
          ),
          trailing: TextButton(
            onPressed: () => onSuggestSwap(item),
            child: const Text('Swap'),
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
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: context.textPrimary.withValues(alpha: 0.05),
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
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
            ),
            child: const Text('Customize & Create Portfolio'),
          ),
        ),
      ),
    );
  }
}
