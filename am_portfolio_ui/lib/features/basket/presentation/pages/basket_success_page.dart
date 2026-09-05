import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';
import '../../domain/models/basket_opportunity.dart';
import '../basket_navigation.dart';
import '../widgets/shared/basket_flow_step.dart';
import '../widgets/shared/basket_flow_stepper.dart';
import '../utils/basket_allocation_math.dart';
import '../utils/basket_responsive.dart';

class BasketSuccessPage extends StatelessWidget {
  final BasketOpportunity opportunity;
  final String basketName;
  final String basketId;
  final String userId;
  final String portfolioId;

  const BasketSuccessPage({
    super.key,
    required this.opportunity,
    required this.basketName,
    required this.basketId,
    required this.userId,
    required this.portfolioId,
  });

  @override
  Widget build(BuildContext context) {
    final investAmount = opportunity.investmentAmount ?? 0.0;
    final customWeightSum = investAmount > 0
        ? BasketAllocationMath.totalCustomWeightPercent(
            opportunity.composition,
            investAmount,
            opportunity.excludedSymbols.toSet(),
          )
        : 0.0;
    final customValue = investAmount > 0
        ? BasketAllocationMath.totalCustomInvestment(
            opportunity.composition,
            investAmount,
            opportunity.excludedSymbols.toSet(),
          )
        : 0.0;

    final compact = BasketResponsive.useCompactPreview(context);
    final pagePad = BasketResponsive.pagePadding(context);

    return Scaffold(
      backgroundColor: context.colors.surface,
      body: Column(
        children: [
          const BasketFlowStepper(currentStep: BasketFlowStep.confirm),
          Expanded(
            child: SafeArea(
              top: false,
              child: Padding(
                padding: pagePad.copyWith(
                  top: compact ? AppSpacing.md : AppSpacing.xl,
                  bottom: compact ? AppSpacing.md : AppSpacing.xl,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      decoration: BoxDecoration(
                        color: ModuleColors.portfolio.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.celebration,
                        size: 64,
                        color: ModuleColors.portfolio,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    Text(
                      'Your basket is ready',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: context.colors.textPrimary,
                            fontSize: compact ? 22 : null,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      basketName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: context.colors.textSecondary,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: context.colors.cardSurface,
                        borderRadius: AppRadii.card,
                        border: Border.all(color: context.colors.border),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Match Score',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: context.colors.textSecondary,
                                    ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Text(
                                '${opportunity.replicaScore.toStringAsFixed(1)}%',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: ModuleColors.portfolio,
                                    ),
                              ),
                            ],
                          ),
                          if (investAmount > 0) ...[
                            const SizedBox(height: AppSpacing.md),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Column(
                                  children: [
                                    Text(
                                      'Allocation Wt',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: context.colors.textSecondary,
                                      ),
                                    ),
                                    Text(
                                      '${customWeightSum.toStringAsFixed(1)}%',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ],
                                ),
                                Column(
                                  children: [
                                    Text(
                                      'From Holdings',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: context.colors.textSecondary,
                                      ),
                                    ),
                                    Text(
                                      '₹${customValue.toStringAsFixed(0)}',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const Spacer(),
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 400),
                        child: Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: () {
                                  BasketNavigation.returnToMyBaskets(
                                    context,
                                    userId: userId,
                                  );
                                },
                                style: FilledButton.styleFrom(
                                  backgroundColor: ModuleColors.portfolio,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: AppSpacing.md,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppRadii.md),
                                  ),
                                ),
                                child: const Text(
                                  'View in Portfolio',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: () {
                                  BasketNavigation.clearBasketSession(userId);
                                  BasketNavigation.openDashboard(
                                    context,
                                    basketId: basketId,
                                    userId: userId,
                                    portfolioId: portfolioId,
                                    fromCreationFlow: true,
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: ModuleColors.portfolio,
                                  side: BorderSide(
                                    color: ModuleColors.portfolio
                                        .withValues(alpha: 0.55),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: AppSpacing.md,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppRadii.md),
                                  ),
                                ),
                                child: const Text('View Basket'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
