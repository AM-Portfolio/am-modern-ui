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

    final theme = Theme.of(context);
    final isDesktop = MediaQuery.sizeOf(context).width >= AmBreakpoints.tablet;
    final args = widget.args;

    final heldCount = _validatedItems.where((i) => i.status == ItemStatus.held).length;
    final subCount = _validatedItems.where((i) => i.status == ItemStatus.substitute).length;

    // Calculate unallocated
    final unallocated = math.max(
        0.0,
        args.investmentAmount -
            (_validatedOpportunity.actualInvestmentCost ??
                args.investmentAmount));

    final actualCost = _validatedOpportunity.actualInvestmentCost ?? 0.0;

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
                            finalItems: _validatedItems,
                            replicaScore: _validatedOpportunity.replicaScore,
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
            coverage: _validatedOpportunity.replicaScore,
            onConfirm: _confirmAndCreate,
            isSubmitting: _isSubmitting,
          ),
        ],
      ),
    );
  }
}
