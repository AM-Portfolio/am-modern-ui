import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:am_design_system/am_design_system.dart';
import '../basket_navigation.dart';
import 'basket_success_page.dart';
import '../providers/basket_providers.dart';
import '../../../portfolio/providers/portfolio_providers.dart';
import '../../domain/models/basket_opportunity.dart';
import '../widgets/final_preview/fp_stepper.dart';
import '../widgets/final_preview/fp_etf_panel.dart';
import '../widgets/final_preview/fp_basket_panel.dart';
import '../widgets/final_preview/fp_summary_bar.dart';

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
        'replicaScore': args.finalOpportunity.replicaScore,
        'coverageAfterCreation': args.finalOpportunity.replicaScore,
        'remainingMissingCount': args.finalItems.where((c) => c.status == ItemStatus.missing).length,
        'remainingMissing': args.finalItems
            .where((c) => c.status == ItemStatus.missing)
            .map((c) => c.stockSymbol)
            .toList(),
        'lines': args.finalItems.map((item) {
          return {
            'status': item.status.toString().split('.').last.toUpperCase(),
            'etfIsin': item.isin,
            'etfSymbol': item.stockSymbol,
            'holdingIsin': (item.status == ItemStatus.substitute || item.status == ItemStatus.held)
                ? (item.userHoldingIsin ?? item.isin)
                : item.isin,
            'holdingSymbol': (item.status == ItemStatus.substitute || item.status == ItemStatus.held)
                ? (item.userHoldingSymbol ?? item.stockSymbol)
                : item.stockSymbol,
            'quantity': item.buyQuantity,
            'heldQuantity': (item.heldQuantity != null && item.targetQuantity != null)
                ? math.min(item.heldQuantity!, item.targetQuantity!)
                : item.heldQuantity,
            'averageBuyingPrice': item.lastPrice,
          };
        }).toList(),
      };

      final newBasketId = await ref.read(createBasketPortfolioProvider(request: request).future);
      
      if (!mounted) return;
      ref.invalidate(myBasketsProvider(userId: args.userId, portfolioId: ''));

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => BasketSuccessPage(
            opportunity: args.finalOpportunity,
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
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.sizeOf(context).width >= AmBreakpoints.tablet;
    final args = widget.args;

    final heldCount = args.finalItems.where((i) => i.status == ItemStatus.held).length;
    final subCount = args.finalItems.where((i) => i.status == ItemStatus.substitute).length;

    // Calculate unallocated
    final unallocated = (args.finalOpportunity.budgetVariance ?? 0) > 0 
        ? args.finalOpportunity.budgetVariance! 
        : 0.0;

    final actualCost = args.finalOpportunity.actualInvestmentCost ?? 0.0;

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Final Review: ${args.basketName}',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        backgroundColor: context.cardColor,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: context.colors.textPrimary),
      ),
      body: Column(
        children: [
          const FpStepper(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: isDesktop
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: FpEtfPanel(originalOpportunity: args.originalOpportunity)),
                        const SizedBox(width: AppSpacing.xl),
                        Expanded(
                          child: FpBasketPanel(
                            finalItems: args.finalItems,
                            replicaScore: args.finalOpportunity.replicaScore,
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
                          finalItems: args.finalItems,
                          replicaScore: args.finalOpportunity.replicaScore,
                          actualInvestmentCost: actualCost,
                          heldCount: heldCount,
                          subCount: subCount,
                        ),
                      ],
                    ),
            ),
          ),
          FpSummaryBar(
            intendedAmount: args.investmentAmount,
            actualCost: actualCost,
            unallocated: unallocated,
            coverage: args.finalOpportunity.replicaScore,
            onConfirm: _confirmAndCreate,
            isSubmitting: _isSubmitting,
          ),
        ],
      ),
    );
  }
}
