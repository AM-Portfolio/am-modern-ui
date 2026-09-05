import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:am_design_system/am_design_system.dart';
import '../basket_navigation.dart';
import '../../domain/services/basket_currency_formatter.dart';
import 'basket_success_page.dart';
import '../providers/basket_providers.dart';
import '../../domain/models/basket_opportunity.dart';
import '../../domain/mappers/create_portfolio_request_mapper.dart';
import '../widgets/final_preview/fp_etf_panel.dart';
import '../widgets/final_preview/fp_basket_panel.dart';
import '../widgets/shared/basket_flow_step.dart';
import '../widgets/shared/basket_flow_stepper.dart';
import '../widgets/shared/basket_sticky_action_bar.dart';
import '../utils/basket_allocation_math.dart';
import '../utils/basket_api_errors.dart';
import '../utils/basket_responsive.dart';
import '../utils/basket_portfolio_sync.dart';
import '../flow/basket_flow_controller.dart';

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
  /// 0 = Your Basket (default), 1 = Original ETF — mobile only.
  int _mobilePanelIndex = 0;

  @override
  void initState() {
    super.initState();
    _validateFinalPreview();
  }

  Future<void> _validateFinalPreview() async {
    final args = widget.args;
    if (args.trustCustomizeOutput) {
      if (mounted) {
        setState(() {
          _validatedOpportunity =
              args.finalOpportunity.copyWith(composition: args.finalItems);
          _validatedItems = args.finalItems;
          _isLoading = false;
        });
      }
      return;
    }

    try {
      final request = {
        'investmentAmount': args.investmentAmount,
        'opportunity': args.finalOpportunity.copyWith(composition: args.finalItems).toJson(),
        'includeHeld': true,
        'excludedSymbols': args.excludedItems.toList(),
      };

      final freshOpportunity = await ref.read(
        calculateBasketQuantitiesFinalPreviewProvider(request: request).future,
      );

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
          _error = basketApiErrorMessage(e);
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _confirmAndCreate() async {
    setState(() => _isSubmitting = true);
    try {
      final args = widget.args;
      final request = CreatePortfolioRequestMapper.toRequest(
        userId: args.userId,
        portfolioId: args.portfolioId,
        originalOpportunity: args.originalOpportunity,
        validatedOpportunity: _validatedOpportunity,
        validatedItems: _validatedItems,
        basketName: args.basketName,
        idempotencyKey: args.idempotencyKey,
        investmentAmount: args.investmentAmount,
        draftId: args.draftId,
      );

      final newBasketId = await ref.read(createBasketPortfolioProvider(request: request).future);

      if (!mounted) return;
      ref.read(basketFlowControllerProvider.notifier).resetFlow();
      BasketNavigation.clearBasketSession(args.userId);
      ref.invalidate(myBasketsProvider(userId: args.userId, portfolioId: ''));
      ref.invalidate(basketDraftsProvider((
        userId: args.userId,
        portfolioId: args.portfolioId,
      )));
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
        content: Text('Failed to create basket: ${basketApiErrorMessage(e)}'),
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
                        SegmentedButton<int>(
                          segments: const [
                            ButtonSegment(
                              value: 0,
                              label: Text('Your Basket'),
                              icon: Icon(Icons.shopping_basket_outlined, size: 16),
                            ),
                            ButtonSegment(
                              value: 1,
                              label: Text('Original ETF'),
                              icon: Icon(Icons.auto_awesome, size: 16),
                            ),
                          ],
                          selected: {_mobilePanelIndex},
                          onSelectionChanged: (s) {
                            setState(() => _mobilePanelIndex = s.first);
                          },
                          style: ButtonStyle(
                            visualDensity: VisualDensity.compact,
                            textStyle: WidgetStatePropertyAll(
                              Theme.of(context).textTheme.labelMedium,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        if (_mobilePanelIndex == 0)
                          FpBasketPanel(
                            finalItems: _validatedItems,
                            replicaScore: _validatedOpportunity.replicaScore,
                            investmentAmount: args.investmentAmount,
                            actualInvestmentCost: actualCost,
                            heldCount: heldCount,
                            subCount: subCount,
                          )
                        else
                          FpEtfPanel(
                            originalOpportunity: args.originalOpportunity,
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
            value: BasketCurrencyFormatter.formatInr(customValue),
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
