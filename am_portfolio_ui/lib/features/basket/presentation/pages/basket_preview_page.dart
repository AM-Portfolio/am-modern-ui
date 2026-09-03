import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:intl/intl.dart';
import '../providers/basket_providers.dart';
import '../utils/basket_api_errors.dart';
import '../basket_navigation.dart';
import '../../domain/models/basket_opportunity.dart';

// New Modular Widgets
import '../widgets/preview/preview_hero_header.dart';
import '../widgets/preview/preview_section_header.dart';
import '../widgets/preview/preview_stock_row.dart';
import '../widgets/shared/basket_flow_step.dart';
import '../widgets/shared/basket_flow_stepper.dart';
import '../widgets/shared/basket_sticky_action_bar.dart';

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
      data: (opportunity) => Column(
        children: [
          const BasketFlowStepper(currentStep: BasketFlowStep.preview),
          Expanded(
            child: _BasketContent(
              initialOpportunity: opportunity,
              userId: userId,
              portfolioId: portfolioId,
            ),
          ),
        ],
      ),
      loading: () => _buildSkeletonLoader(context),
      error: (err, stack) => AmErrorWidget(
        message: err.toString(),
        onRetry: () {
          ref.invalidate(basketPreviewProvider(
            etfIsin: etfIsin,
            userId: userId,
            portfolioId: portfolioId,
          ));
        },
      ),
    );

    if (embedded) {
      return ColoredBox(
        color: context.colors.scaffoldBackground,
        child: body,
      );
    }

    return Scaffold(
      backgroundColor: context.colors.scaffoldBackground,
      body: body,
    );
  }

  Widget _buildSkeletonLoader(BuildContext context) {
    return Column(
      children: [
        const BasketFlowStepper(currentStep: BasketFlowStep.preview),
        const Expanded(
          child: Center(child: CircularProgressIndicator()),
        ),
      ],
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
            'missingIsin': item.isin,
            'substituteIsin': selectedAlt.isin,
            'reason': 'User selected swap'
          }
        ],
      };

      final updatedOpportunity = await ref.read(applySubstitutesProvider(request: request).future);
      
      setState(() {
        _opportunity = updatedOpportunity;
      });
      
      if (mounted) {
        final applied = updatedOpportunity.appliedSubstituteCount ?? 1;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              substituteApplyMessage(
                appliedCount: applied,
                warnings: updatedOpportunity.substituteWarnings,
              ),
            ),
            backgroundColor: applied > 0 ? context.colors.statusSuccess : context.statusWarning,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to swap: ${basketApiErrorMessage(e)}'),
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
    final available =
        _opportunity.remainingPortfolioValue ?? _opportunity.totalPortfolioValue ?? 0;
    final formatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Column(
      children: [
        Expanded(child: _buildScrollableContent(context)),
        BasketStickyActionBar(
          stats: [
            BasketStatItem(label: 'Available to Invest', value: formatter.format(available)),
            BasketStatItem(
              label: 'Match',
              value: '${_opportunity.replicaScore.toStringAsFixed(0)}%',
              highlight: _opportunity.replicaScore >= 70,
            ),
          ],
          onBack: () {
            if (Navigator.canPop(context)) Navigator.pop(context);
          },
          primaryLabel: 'Customize Basket',
          primaryIcon: Icons.arrow_forward,
          onPrimary: () => BasketNavigation.openCreator(
            context,
            opportunity: _opportunity,
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
        if (heldItems.isNotEmpty)
          SliverToBoxAdapter(
            child: PreviewSectionCard(
              child: Column(
                children: [
                  PreviewSectionHeader(
                    title: 'Held in Portfolio',
                    subtitle: 'Direct ETF matches — your holdings align with ETF targets',
                    statusType: ItemStatus.held,
                    itemCount: heldItems.length,
                  ),
                  ...heldItems.map(
                    (item) => PreviewStockRow(
                      item: item,
                      isSwapping: _swappingSymbols.contains(item.stockSymbol),
                      onSwapSelected: _handleSwap,
                      sectorialBasket: _opportunity.sectorialBasket ?? false,
                      dominantSector: _opportunity.dominantSector,
                      etfName: _opportunity.etfName,
                      etfConstituentIsins: _opportunity.etfConstituentIsins,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Substituted Section
        if (substituteItems.isNotEmpty)
          SliverToBoxAdapter(
            child: PreviewSectionCard(
              child: Column(
                children: [
                  PreviewSectionHeader(
                    title: 'Automatically Substituted',
                    subtitle: 'ETF slots covered by similar holdings in your portfolio',
                    statusType: ItemStatus.substitute,
                    itemCount: substituteItems.length,
                  ),
                  ...substituteItems.map(
                    (item) => PreviewStockRow(
                      item: item,
                      isSwapping: _swappingSymbols.contains(item.stockSymbol),
                      onSwapSelected: _handleSwap,
                      sectorialBasket: _opportunity.sectorialBasket ?? false,
                      dominantSector: _opportunity.dominantSector,
                      etfName: _opportunity.etfName,
                      etfConstituentIsins: _opportunity.etfConstituentIsins,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Missing Section
        if (missingItems.isNotEmpty)
          SliverToBoxAdapter(
            child: PreviewSectionCard(
              child: Column(
                children: [
                  PreviewSectionHeader(
                    title: 'Missing / Swap Required',
                    subtitle: 'Tap a row to pick a substitute from your portfolio',
                    statusType: ItemStatus.missing,
                    itemCount: missingItems.length,
                  ),
                  ...missingItems.map(
                    (item) => PreviewStockRow(
                      item: item,
                      isSwapping: _swappingSymbols.contains(item.stockSymbol),
                      onSwapSelected: _handleSwap,
                      sectorialBasket: _opportunity.sectorialBasket ?? false,
                      dominantSector: _opportunity.dominantSector,
                      etfName: _opportunity.etfName,
                      etfConstituentIsins: _opportunity.etfConstituentIsins,
                    ),
                  ),
                ],
              ),
            ),
          ),

        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
      ],
    );
  }
}
