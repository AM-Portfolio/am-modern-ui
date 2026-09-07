import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';

import 'discover_layout.dart';

class DiscoverSkeletonGrid extends StatelessWidget {
  const DiscoverSkeletonGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
        AppSpacing.md,
      ),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 360,
        mainAxisExtent: DiscoverLayout.cardHeight,
        crossAxisSpacing: DiscoverLayout.gridGap,
        mainAxisSpacing: DiscoverLayout.gridGap,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: context.colors.surface.withValues(alpha: 0.45),
            borderRadius: AppRadii.card,
          ),
        );
      },
    );
  }
}

class DiscoverEmptyState extends StatelessWidget {
  const DiscoverEmptyState({
    super.key,
    required this.onReset,
    this.onRetry,
    this.themeSelected = false,
  });

  final VoidCallback onReset;
  final VoidCallback? onRetry;
  final bool themeSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title =
        themeSelected ? 'No baskets for this theme' : 'No baskets matched';
    final body = themeSelected
        ? 'Holdings data may be unavailable for this ETF theme yet. Try Top picks, another theme, or search by symbol/ISIN.'
        : 'Try Top picks or search for an ETF by name or ISIN.';
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_basket_outlined,
                      size: 48, color: context.textTertiary),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    title,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    body,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: context.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg - 4),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    alignment: WrapAlignment.center,
                    children: [
                      OutlinedButton(
                          onPressed: onReset,
                          child: const Text('Reset filters')),
                      if (onRetry != null)
                        FilledButton(
                            onPressed: onRetry, child: const Text('Retry')),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class DiscoverErrorState extends StatelessWidget {
  const DiscoverErrorState({
    super.key,
    required this.message,
    required this.onRetry,
    this.title = 'Couldn’t load opportunities',
  });

  final String title;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 44, color: context.statusError),
                  const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
                  Text(
                    title,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: context.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  FilledButton(onPressed: onRetry, child: const Text('Retry')),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
