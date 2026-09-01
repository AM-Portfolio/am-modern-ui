import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:intl/intl.dart';
import '../basket_navigation.dart';
import 'basket_success_page.dart';
import '../providers/basket_providers.dart';
import '../../domain/models/basket_opportunity.dart';
import '../widgets/final_preview/fp_etf_panel.dart';
import '../widgets/final_preview/fp_basket_panel.dart';
import '../widgets/shared/basket_flow_step.dart';
import '../widgets/shared/basket_flow_stepper.dart';
import '../widgets/shared/basket_sticky_action_bar.dart';
import '../utils/basket_allocation_math.dart';
import '../utils/basket_responsive.dart';
import '../utils/basket_portfolio_sync.dart';

class BasketFinalPreviewPage extends ConsumerStatefulWidget {
  final BasketFinalPreviewArgs args;

  const BasketFinalPreviewPage({
    super.key,
    required this.args,
  });

  @override
  ConsumerState<BasketFinalPreviewPage> createState() => _BasketFinalPreviewPageState();
}

class _BasketFinalPreviewPageState extends ConsumerState<BasketFinalPreviewPage> {
  bool _isSubmitting = false;
  bool _isLoading = true;
  String? _error;
  late BasketOpportunity _validatedOpportunity;
  late List<BasketItem> _validatedItems;

  @override
  void initState() {
    super.initState();
    _validateFinalPreview();
  }

  Future<void> _validateFinalPreview() async {
    try {
      final args = widget.args;
      final request = {
        'investmentAmount': args.investmentAmount,
        'opportunity': args.finalOpportunity.copyWith(composition: args.finalItems).toJson(),
        'includeHeld': true,
        'excludedSymbols': args.excludedItems.toList(),
      };
      
      final freshOpportunity = await ref.read(calculateBasketQuantitiesFinalPreviewProvider(request: request).future);
      
      if (mounted) {
        setState(() {
          _validatedOpportunity = freshOpportunity;
          _validatedItems = freshOpportunity.composition;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _confirmAndCreate() async {
    setState(() => _isSubmitting = true);
    try {
      final args = widget.args;
      final request = {
        'userId': args.userId,
        'sourcePortfolioId': args.portfolioId,
        'etfIsin': args.originalOpportunity.etfIsin,
        'etfName': args.originalOpportunity.etfName,
        'basketName': args.basketName,
        'idempotencyKey': args.idempotencyKey,
        'investmentAmount': args.investmentAmount,
        'replicaScore': _validatedOpportunity.replicaScore,
        'coverageAfterCreation': _validatedOpportunity.replicaScore,
        'remainingMissingCount': _validatedItems.where((c) => c.status == ItemStatus.missing).length,
        'remainingMissing': _validatedItems
            .where((c) => c.status == ItemStatus.missing)
            .map((c) => c.stockSymbol)
            .toList(),
        'lines': _validatedItems.map((item) {
          final lineWeight = item.replicaWeight > 0
              ? item.replicaWeight
              : (item.rebalancedWeight ?? item.etfWeight);
          final isHeldOrSub =
              item.status == ItemStatus.held || item.status == ItemStatus.substitute;
          final avgCost = isHeldOrSub
              ? (item.heldAveragePrice ?? item.lastPrice)
              : item.lastPrice;
          return {
            'status': item.status.toString().split('.').last.toUpperCase(),
            'etfIsin': item.isin,
            'etfSymbol': item.stockSymbol,
            'etfWeight': lineWeight,
            'holdingIsin': isHeldOrSub
                ? (item.userHoldingIsin ?? item.isin)
                : item.isin,
            'holdingSymbol': isHeldOrSub
                ? (item.userHoldingSymbol ?? item.stockSymbol)
                : item.stockSymbol,
            'quantity': item.buyQuantity,
            'heldQuantity': (item.heldQuantity != null && item.targetQuantity != null)
                ? math.min(item.heldQuantity!, item.targetQuantity!)
                : item.heldQuantity,
            'averageBuyingPrice': avgCost,
            'lastKnownPrice': item.lastPrice,
          };
        }).toList(),
      };

      final newBasketId = await ref.read(createBasketPortfolioProvider(request: request).future);
      
      if (!mounted) return;
      ref.invalidate(myBasketsProvider(userId: args.userId, portfolioId: ''));
      await BasketPortfolioSync.afterBasketMutation(context);

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => BasketSuccessPage(
            opportunity: _validatedOpportunity,
            basketName: args.basketName,
            basketId: newBasketId,
            userId: args.userId,
            portfolioId: args.portfolioId,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to create basket: $e'),
        backgroundColor: context.statusError,
      ));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: context.backgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: context.backgroundColor,
        body: Center(
          child: Text('Failed to load final preview: $_error',
              style: TextStyle(color: context.statusError)),
        ),
      );
    }

    final isDesktop = BasketResponsive.isDesktop(context);
    final pagePad = BasketResponsive.pagePadding(context);
    final args = widget.args;

    final heldCount = _validatedItems.where((i) => i.status == ItemStatus.held).length;
    final subCount = _validatedItems.where((i) => i.status == ItemStatus.substitute).length;

    final actualCost = _validatedOpportunity.actualInvestmentCost ?? 0.0;
    final fmtValue = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final excluded = args.excludedItems;
    final targetSum = BasketAllocationMath.targetWeightSum(_validatedItems, excluded);
    final customWeightSum = BasketAllocationMath.totalCustomWeightPercent(
      _validatedItems,
      args.investmentAmount,
      excluded,
    );
    final customValue = BasketAllocationMath.totalCustomInvestment(
      _validatedItems,
      args.investmentAmount,
      excluded,
    );

    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: Column(
        children: [
          const BasketFlowStepper(currentStep: BasketFlowStep.finalReview),
          Expanded(
            child: SingleChildScrollView(
              padding: pagePad.copyWith(
                top: AppSpacing.lg,
                bottom: AppSpacing.lg,
              ),
              child: isDesktop
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: FpEtfPanel(originalOpportunity: args.originalOpportunity)),
                        const SizedBox(width: AppSpacing.xl),
                        Expanded(
                          child: FpBasketPanel(
                            finalItems: _validatedItems,
                            replicaScore: _validatedOpportunity.replicaScore,
                            investmentAmount: args.investmentAmount,
                            actualInvestmentCost: actualCost,
                            heldCount: heldCount,
                            subCount: subCount,
                          ),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        FpEtfPanel(originalOpportunity: args.originalOpportunity),
                        const SizedBox(height: AppSpacing.xl),
                        FpBasketPanel(
                          finalItems: _validatedItems,
                          replicaScore: _validatedOpportunity.replicaScore,
                          investmentAmount: args.investmentAmount,
                          actualInvestmentCost: actualCost,
                          heldCount: heldCount,
                          subCount: subCount,
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BasketStickyActionBar(
        stats: [
          BasketStatItem(
            label: 'Target Wt',
            value: '${targetSum.toStringAsFixed(1)}%',
          ),
          BasketStatItem(
            label: 'Allocation Wt',
            value: '${customWeightSum.toStringAsFixed(1)}%',
            highlight: customWeightSum >= 80,
          ),
          BasketStatItem(
            label: 'From Holdings',
            value: fmtValue.format(customValue),
          ),
          BasketStatItem(
            label: 'Match Score',
            value: '${_validatedOpportunity.replicaScore.toStringAsFixed(0)}%',
            highlight: _validatedOpportunity.replicaScore >= 80,
          ),
        ],
        primaryLabel: 'Confirm & Create Basket',
        primaryIcon: Icons.check,
        primaryColor: context.statusSuccess,
        onBack: () => Navigator.of(context).maybePop(),
        onPrimary: _confirmAndCreate,
        isLoading: _isSubmitting,
      ),
    );
  }
}
