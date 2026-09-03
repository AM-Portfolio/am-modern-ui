import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:intl/intl.dart';
import '../providers/basket_providers.dart';
import '../utils/basket_api_errors.dart';
import '../basket_navigation.dart';
import '../../domain/models/basket_opportunity.dart';
import '../flow/basket_flow_controller.dart';

// New Modular Widgets
import '../widgets/preview/preview_hero_header.dart';
import '../widgets/preview/preview_comparison_panels.dart';
import '../widgets/preview/preview_layout.dart';
import '../widgets/shared/basket_flow_step.dart';
import '../widgets/shared/basket_flow_stepper.dart';
import '../widgets/shared/basket_sticky_action_bar.dart';

class BasketPreviewPage extends ConsumerWidget {
  final String etfIsin;
  final String userId;
  final String portfolioId;
  final BasketOpportunity? seededOpportunity;
  final bool embedded;

  const BasketPreviewPage({
    super.key,
    required this.etfIsin,
    required this.userId,
    required this.portfolioId,
    this.seededOpportunity,
    this.embedded = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final opportunityAsync = ref.watch(basketPreviewProvider(
      etfIsin: etfIsin,
      userId: userId,
      portfolioId: portfolioId,
      seededOpportunity: seededOpportunity,
    ));

    final body = opportunityAsync.when(
      data: (opportunity) => LayoutBuilder(
        builder: (ctx, constraints) {
          final bounded =
              constraints.maxHeight.isFinite && constraints.maxHeight > 0;
          final content = _BasketContent(
            initialOpportunity: opportunity,
            userId: userId,
            portfolioId: portfolioId,
          );
          return Column(
            children: [
              const BasketFlowStepper(currentStep: BasketFlowStep.preview),
              if (bounded)
                Expanded(child: content)
              else
                content,
            ],
          );
        },
      ),
      loading: () => LayoutBuilder(
        builder: (ctx, constraints) {
          final bounded =
              constraints.maxHeight.isFinite && constraints.maxHeight > 0;
          return Column(
            children: [
              const BasketFlowStepper(currentStep: BasketFlowStep.preview),
              if (bounded)
                const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                const Center(child: CircularProgressIndicator()),
            ],
          );
        },
      ),
      error: (err, stack) => AmErrorWidget(
        message: basketApiErrorMessage(err),
        onRetry: () {
          ref.invalidate(basketPreviewProvider(
            etfIsin: etfIsin,
            userId: userId,
            portfolioId: portfolioId,
            seededOpportunity: seededOpportunity,
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final flow = ref.read(basketFlowControllerProvider);
      final flowNotifier = ref.read(basketFlowControllerProvider.notifier);
      final sameEtf =
          flow.currentOpportunity?.etfIsin == widget.initialOpportunity.etfIsin;
      if (flow.isEmpty || !sameEtf) {
        if (!flow.isEmpty && !sameEtf) {
          flowNotifier.resetFlow();
        }
        flowNotifier.startFlow(widget.initialOpportunity);
      } else {
        flowNotifier.updateOpportunity(widget.initialOpportunity);
      }
    });
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
      ref.read(basketFlowControllerProvider.notifier).updateOpportunity(updatedOpportunity);

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
        PreviewHeroHeader(opportunity: _opportunity),
        const SizedBox(height: PreviewLayout.sectionGap),
        Expanded(
          child: PreviewComparisonPanels(
            opportunity: _opportunity,
            swappingSymbols: _swappingSymbols,
            onSwapSelected: _handleSwap,
            sectorialBasket: _opportunity.sectorialBasket ?? false,
            dominantSector: _opportunity.dominantSector,
            etfName: _opportunity.etfName,
            etfConstituentIsins: _opportunity.etfConstituentIsins,
          ),
        ),
        BasketStickyActionBar(
          stats: [
            BasketStatItem(
                label: 'Available to Invest',
                value: formatter.format(available)),
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
          onPrimary: () {
            final flow = ref.read(basketFlowControllerProvider);
            final opportunity = (flow.currentOpportunity?.etfIsin ==
                    _opportunity.etfIsin)
                ? (flow.currentOpportunity ?? _opportunity)
                : _opportunity;
            BasketNavigation.openCreator(
              context,
              opportunity: opportunity,
              userId: widget.userId,
              portfolioId: widget.portfolioId,
            );
          },
        ),
      ],
    );
  }
}
