import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:intl/intl.dart';
import '../providers/basket_providers.dart';
import '../basket_navigation.dart';
import '../../domain/models/basket_opportunity.dart';
import '../../domain/models/basket_enums.dart';

// New Modular Widgets
import '../widgets/preview/preview_hero_header.dart';
import '../widgets/preview/preview_section_header.dart';
import '../widgets/preview/preview_stock_row.dart';

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
    final opportunityAsync = ref.watch(enhancedBasketPreviewProvider(
      etfIsin: etfIsin,
      userId: userId,
      portfolioId: portfolioId,
    ));

    final body = opportunityAsync.when(
      data: (opportunity) => _BasketContent(
        initialOpportunity: opportunity,
        userId: userId,
        portfolioId: portfolioId,
      ),
      loading: () => _buildSkeletonLoader(context),
      error: (err, stack) => _buildErrorState(context, err.toString(), ref),
    );

    // Apply Dark Theme override for this specific page to match premium aesthetic
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
      ),
      backgroundColor: context.colors.scaffoldBackground,
      body: body,
    );
  }

  Widget _buildSkeletonLoader(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildErrorState(BuildContext context, String errorMsg, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text('Failed to load basket preview', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(errorMsg, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                ref.invalidate(enhancedBasketPreviewProvider(
                  etfIsin: etfIsin,
                  userId: userId,
                  portfolioId: portfolioId,
                ));
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _BasketContent extends ConsumerStatefulWidget {
  final BasketOpportunity initialOpportunity;
  final String userId;
  final String portfolioId;

  const _BasketContent({
    required this.initialOpportunity,
    required this.userId,
    required this.portfolioId,
  });

  @override
  ConsumerState<_BasketContent> createState() => _BasketContentState();
}

class _BasketContentState extends ConsumerState<_BasketContent> {
  late BasketOpportunity _opportunity;
  final Set<String> _swappingSymbols = {};

  @override
  void initState() {
    super.initState();
    _opportunity = widget.initialOpportunity;
  }

  Future<void> _handleSwap(BasketItem item, Alternative selectedAlt) async {
    setState(() {
      _swappingSymbols.add(item.stockSymbol);
    });

    try {
      final request = {
        'userId': widget.userId,
        'portfolioId': widget.portfolioId,
        'etfIsin': _opportunity.etfIsin,
        'currentOpportunity': _opportunity.toJson(),
        'assignments': [
          {
            'missingIsin': item.isin ?? item.stockSymbol, // Fallback logic
            'substituteIsin': selectedAlt.isin ?? selectedAlt.symbol,
            'reason': 'User selected swap'
          }
        ],
      };

      final updatedOpportunity = await ref.read(applySubstitutesProvider(request: request).future);
      
      setState(() {
        _opportunity = updatedOpportunity;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item.stockSymbol} substituted with ${selectedAlt.symbol}'),
            backgroundColor: context.colors.statusSuccess,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to swap: $e'),
            backgroundColor: context.colors.statusError,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _swappingSymbols.remove(item.stockSymbol);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: _buildScrollableContent(context),
        ),
        _BottomActionBar(
          totalValue: _opportunity.totalPortfolioValue ?? 0,
          onPressed: () => BasketNavigation.openCreator(
            context,
            opportunity: _opportunity, // Pass the mutable updated state!
            userId: widget.userId,
            portfolioId: widget.portfolioId,
          ),
        ),
      ],
    );
  }

  Widget _buildScrollableContent(BuildContext context) {
    final heldItems = _opportunity.composition
        .where((item) => item.status == ItemStatus.held)
        .toList();
    final substituteItems = _opportunity.composition
        .where((item) => item.status == ItemStatus.substitute)
        .toList();
    final missingItems = _opportunity.composition
        .where((item) => item.status == ItemStatus.missing)
        .toList();

    // Order of sections: Held -> Substituted -> Missing
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: PreviewHeroHeader(opportunity: _opportunity),
        ),
        
        // Held Section
        if (heldItems.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: PreviewSectionHeader(
              title: 'Held in Portfolio',
              subtitle: '\ Stocks',
              statusType: ItemStatus.held,
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final item = heldItems[index];
                return PreviewStockRow(
                  item: item,
                  isSwapping: _swappingSymbols.contains(item.stockSymbol),
                  onSwapSelected: _handleSwap,
                );
              },
              childCount: heldItems.length,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
        ],

        // Substituted Section
        if (substituteItems.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: PreviewSectionHeader(
              title: 'Automatically Substituted',
              subtitle: '\ Stocks',
              statusType: ItemStatus.substitute,
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final item = substituteItems[index];
                return PreviewStockRow(
                  item: item,
                  isSwapping: _swappingSymbols.contains(item.stockSymbol),
                  onSwapSelected: _handleSwap,
                );
              },
              childCount: substituteItems.length,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
        ],

        // Missing Section
        if (missingItems.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: PreviewSectionHeader(
              title: 'Missing / Swap Required',
              subtitle: '\ Stocks',
              statusType: ItemStatus.missing,
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final item = missingItems[index];
                return PreviewStockRow(
                  item: item,
                  isSwapping: _swappingSymbols.contains(item.stockSymbol),
                  onSwapSelected: _handleSwap,
                );
              },
              childCount: missingItems.length,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
        ],
      ],
    );
  }
}

class _BottomActionBar extends StatelessWidget {
  final double totalValue;
  final VoidCallback onPressed;

  const _BottomActionBar({
    required this.totalValue,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(locale: 'en_IN', symbol: '?', decimalDigits: 0);
    String formattedValue = formatter.format(totalValue);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border(
          top: BorderSide(color: context.colors.border),
        ),
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Total Held Value',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.colors.textDisabled),
                ),
                Text(
                  formattedValue,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            FilledButton(
              onPressed: onPressed,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Customize & Calculation'),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_ios, size: 14),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
