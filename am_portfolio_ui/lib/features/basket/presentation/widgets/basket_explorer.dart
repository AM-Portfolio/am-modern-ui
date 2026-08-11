import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:am_library/am_library.dart';
import '../providers/basket_providers.dart';
import '../basket_navigation.dart';
import '../../domain/models/basket_opportunity.dart';
import 'etf_search_bar.dart';

class BasketExplorer extends ConsumerStatefulWidget {
  final String userId;
  final String portfolioId;

  const BasketExplorer({
    super.key,
    required this.userId,
    required this.portfolioId,
  });

  @override
  ConsumerState<BasketExplorer> createState() => _BasketExplorerState();
}

class _BasketExplorerState extends ConsumerState<BasketExplorer> {
  String? _query;
  bool _emittedEmpty = false;
  String? _lastEmptyQuery;
  String? _selectedThemeId;

  void _updateQuery({String? query, String? themeId}) {
    setState(() {
      _query = query;
      _selectedThemeId = themeId;
      _emittedEmpty = false;
      _lastEmptyQuery = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final catalogAsync = ref.watch(basketCatalogProvider);

    return catalogAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => _ErrorState(
        title: 'Couldn’t load baskets',
        message: err.toString(),
        onRetry: () => ref.invalidate(basketCatalogProvider),
      ),
      data: (catalog) {
        final activeQuery = (_query != null && _query!.isNotEmpty)
            ? _query!
            : catalog.defaultQuery;
        if (activeQuery.isEmpty) {
          return _ErrorState(
            title: 'Couldn’t load baskets',
            message: 'No default basket query is configured yet.',
            onRetry: () => ref.invalidate(basketCatalogProvider),
          );
        }

        final opportunitiesAsync = ref.watch(basketOpportunitiesProvider(
          userId: widget.userId,
          portfolioId: widget.portfolioId,
          query: activeQuery,
        ));

        final themes = catalog.themes.where((t) => t.featured && t.query.isNotEmpty).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.xs,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Smart Baskets',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Match your holdings to ETF baskets and see what you already own.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: context.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm + AppSpacing.xs,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: EtfSearchBar(
                onEtfSelected: (selection) {
                  if (selection.isin != null) {
                    if (selection.isin!.contains(',')) {
                      _updateQuery(query: selection.isin!, themeId: null);
                    } else {
                      BasketNavigation.openPreview(
                        context,
                        etfIsin: selection.isin!,
                        userId: widget.userId,
                        portfolioId: widget.portfolioId,
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Selected ETF has no ISIN')),
                    );
                  }
                },
                onCleared: () {
                  _updateQuery(query: catalog.defaultQuery, themeId: null);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: _ThemeChipScroller(
                child: Row(
                  children: [
                    _ThemeChip(
                      label: 'Top picks',
                      selected: _selectedThemeId == null,
                      onTap: () {
                        _updateQuery(query: catalog.defaultQuery, themeId: null);
                      },
                    ),
                    ...themes.map((entry) {
                      final isSelected = _selectedThemeId == entry.id;
                      return Padding(
                        padding: const EdgeInsets.only(left: AppSpacing.sm),
                        child: _ThemeChip(
                          label: entry.label,
                          selected: isSelected,
                          onTap: () {
                            if (isSelected) {
                              _updateQuery(query: catalog.defaultQuery, themeId: null);
                            } else {
                              _updateQuery(query: entry.query, themeId: entry.id);
                            }
                          },
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
            Expanded(
              child: opportunitiesAsync.when(
                data: (opportunities) {
                  if (opportunities.isEmpty) {
                    if (!_emittedEmpty || _lastEmptyQuery != activeQuery) {
                      _emittedEmpty = true;
                      _lastEmptyQuery = activeQuery;
                      ProductTelemetry.instance.emptyState('basket_opportunities_empty');
                    }
                    return _EmptyState(
                      themeSelected: _selectedThemeId != null,
                      onReset: () {
                        _updateQuery(query: catalog.defaultQuery, themeId: null);
                      },
                    );
                  }
                  _emittedEmpty = false;
                  _lastEmptyQuery = null;
                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.xs,
                      AppSpacing.md,
                      AppSpacing.md,
                    ),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 340,
                      mainAxisExtent: 220,
                      crossAxisSpacing: AppSpacing.md,
                      mainAxisSpacing: AppSpacing.md,
                    ),
                    itemCount: opportunities.length,
                    itemBuilder: (context, index) {
                      final opp = opportunities[index];
                      return TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration: Duration(milliseconds: 280 + (index * 40).clamp(0, 200)),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(0, 12 * (1 - value)),
                              child: child,
                            ),
                          );
                        },
                        child: _BasketOpportunityCard(
                          opportunity: opp,
                          onTap: () {
                            ProductTelemetry.instance.featureAction(
                              'basket_open_preview',
                              tag: 'basket',
                              metadata: {'etf_isin': opp.etfIsin},
                            );
                            BasketNavigation.openPreview(
                              context,
                              etfIsin: opp.etfIsin,
                              userId: widget.userId,
                              portfolioId: widget.portfolioId,
                            );
                          },
                        ),
                      );
                    },
                  );
                },
                loading: () => const _SkeletonGrid(),
                error: (err, stack) => _ErrorState(
                  title: 'Couldn’t load opportunities',
                  message: err.toString(),
                  onRetry: () => ref.invalidate(basketOpportunitiesProvider(
                    userId: widget.userId,
                    portfolioId: widget.portfolioId,
                    query: activeQuery,
                  )),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ThemeChip extends StatelessWidget {
  const _ThemeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = context.colors.actionPrimaryBg;
    return Material(
      color: selected
          ? primary.withValues(alpha: 0.12)
          : context.colors.surface.withValues(alpha: 0.5),
      borderRadius: AppRadii.button,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.button,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md - 2,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: AppRadii.button,
            border: Border.all(
              color: selected
                  ? primary.withValues(alpha: 0.45)
                  : context.dividerColor.withValues(alpha: 0.35),
            ),
          ),
          child: Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: selected ? primary : null,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _BasketOpportunityCard extends StatelessWidget {
  final BasketOpportunity opportunity;
  final VoidCallback onTap;

  /// Compact score ring — must stay small inside fixed-height grid cards.
  static const double _scoreRingSize = AppSpacing.xxl + AppSpacing.xs; // 52

  const _BasketOpportunityCard({
    required this.opportunity,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final score = opportunity.matchScore.clamp(0, 100);
    final scoreColor = score >= 70
        ? context.statusSuccess
        : score >= 40
            ? context.statusWarning
            : context.statusError;

    return Material(
      color: context.cardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadii.card,
        side: BorderSide(color: context.dividerColor.withValues(alpha: 0.4)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.card,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      opportunity.etfName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (opportunity.readyToReplicate)
                    Container(
                      margin: const EdgeInsets.only(left: AppSpacing.sm),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: context.statusSuccess.withValues(alpha: 0.12),
                        borderRadius: AppRadii.button,
                      ),
                      child: Text(
                        'Ready',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: context.statusSuccess,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: _scoreRingSize,
                    height: _scoreRingSize,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: score / 100),
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, _) {
                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            CircularProgressIndicator(
                              value: value,
                              strokeWidth: 5,
                              backgroundColor: scoreColor.withValues(alpha: 0.15),
                              color: scoreColor,
                            ),
                            Text(
                              '${score.toStringAsFixed(0)}%',
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: scoreColor,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Portfolio match',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: context.textSecondary,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '${opportunity.heldCount} held · ${opportunity.missingCount} missing',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (opportunity.totalItems > 0) ...[
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            '${opportunity.totalItems} constituents',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: context.textTertiary,
                              height: 1.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onTap,
                  style: FilledButton.styleFrom(
                    backgroundColor: context.colors.actionPrimaryBg,
                    foregroundColor: context.colors.actionPrimaryFg,
                    minimumSize: const Size.fromHeight(AppSpacing.xl),
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    shape: RoundedRectangleBorder(borderRadius: AppRadii.button),
                  ),
                  child: const Text('Preview basket'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkeletonGrid extends StatelessWidget {
  const _SkeletonGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 340,
        mainAxisExtent: 220,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
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

class _ThemeChipScroller extends StatelessWidget {
  const _ThemeChipScroller({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.only(right: 28),
          child: child,
        ),
        Positioned(
          right: 0,
          top: 0,
          bottom: 0,
          child: IgnorePointer(
            child: Container(
              width: 36,
              alignment: Alignment.centerRight,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    context.backgroundColor.withValues(alpha: 0),
                    context.backgroundColor.withValues(alpha: 0.92),
                  ],
                ),
              ),
              child: Icon(
                Icons.chevron_right,
                size: 20,
                color: context.textTertiary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.onReset,
    this.themeSelected = false,
  });

  final VoidCallback onReset;
  final bool themeSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = themeSelected ? 'No baskets for this theme' : 'No baskets matched';
    final body = themeSelected
        ? 'Holdings data may be unavailable for this ETF theme yet. Try Top picks, another theme, or search by symbol/ISIN.'
        : 'Try Top picks or search for an ETF by name or ISIN.';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shopping_basket_outlined,
                size: 48, color: context.textTertiary),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
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
            OutlinedButton(onPressed: onReset, child: const Text('Reset filters')),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 44, color: context.statusError),
            const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
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
    );
  }
}
