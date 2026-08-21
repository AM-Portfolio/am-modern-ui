import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';
import '../../domain/models/basket_opportunity.dart';
import 'package:go_router/go_router.dart';
import '../basket_navigation.dart';

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
    return Scaffold(
      backgroundColor: context.colors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  color: context.statusSuccess.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.celebration,
                  size: 64,
                  color: context.statusSuccess,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Text(
                'Basket Created!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: context.colors.textPrimary,
                    ),
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
                child: Row(
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
                      '${opportunity.matchScore.toStringAsFixed(0)}%',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: context.statusSuccess,
                          ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    // Navigate to portfolio or pop to root
                    if (GoRouter.maybeOf(context) != null) {
                      context.go('/portfolio');
                    } else {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    }
                  },
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  ),
                  child: const Text('View in Portfolio'),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                     BasketNavigation.openDashboard(
                       context,
                       basketId: basketId,
                       userId: userId,
                       portfolioId: portfolioId,
                     );
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  ),
                  child: const Text('View Basket'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
