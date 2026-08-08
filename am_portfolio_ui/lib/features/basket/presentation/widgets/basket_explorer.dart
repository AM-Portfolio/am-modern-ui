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
  String? _selectedThemeId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final catalogAsync = ref.watch(basketCatalogProvider);

    return catalogAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => _ErrorState(
        message: err.toString(),
        onRetry: () => ref.invalidate(basketCatalogProvider),
      ),
      data: (catalog) {
        final activeQuery = (_query != null && _query!.isNotEmpty)
            ? _query!
            : catalog.defaultQuery;
        if (activeQuery.isEmpty) {
          return _EmptyState(
            themeSelected: false,
            onReset: () {
              setState(() {
                _selectedThemeId = null;
                _query = catalog.defaultQuery;
              });
            },
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
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
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
                  const SizedBox(height: 4),
                  Text(
                    'Match your holdings to ETF baskets and see what you already own.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.65),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: EtfSearchBar(
                onEtfSelected: (selection) {
                  if (selection.isin != null) {
                    if (selection.isin!.contains(',')) {
                      setState(() {
                        _query = selection.isin!;
                        _selectedThemeId = null;
                      });
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
                  setState(() {
                    _query = catalog.defaultQuery;
                    _selectedThemeId = null;
                  });
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _ThemeChipScroller(
                child: Row(
                  children: [
                    _ThemeChip(
                      label: 'Top picks',
                      selected: _selectedThemeId == null,
                      onTap: () {
                        setState(() {
                          _selectedThemeId = null;
                          _query = catalog.defaultQuery;
                        });
                      },
                    ),
                    ...themes.map((entry) {
                      final isSelected = _selectedThemeId == entry.id;
                      return Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: _ThemeChip(
                          label: entry.label,
                          selected: isSelected,
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _selectedThemeId = null;
                                _query = catalog.defaultQuery;
                              } else {
                                _selectedThemeId = entry.id;
                                _query = entry.query;
                              }
                            });
                          },
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: opportunitiesAsync.when(
                data: (opportunities) {
                  if (opportunities.isEmpty) {
                    if (!_emittedEmpty) {
                      _emittedEmpty = true;
                      ProductTelemetry.instance.emptyState('basket_opportunities_empty');
                    }
                    return _EmptyState(
                      themeSelected: _selectedThemeId != null,
                      onReset: () {
                        setState(() {
                          _selectedThemeId = null;
                          _query = catalog.defaultQuery;
                        });
                      },
                    );
                  }
                  _emittedEmpty = false;
                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 340,
                      mainAxisExtent: 210,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
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
    return Material(
      color: selected
          ? theme.colorScheme.primary.withOpacity(0.12)
          : theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? theme.colorScheme.primary.withOpacity(0.45)
                  : theme.dividerColor.withOpacity(0.35),
            ),
          ),
          child: Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: selected ? theme.colorScheme.primary : null,
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

  const _BasketOpportunityCard({
    required this.opportunity,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final score = opportunity.matchScore.clamp(0, 100);
    final scoreColor = score >= 70
        ? AppColors.success
        : score >= 40
            ? Colors.orange.shade700
            : theme.colorScheme.error;

    return Material(
      color: theme.colorScheme.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.dividerColor.withOpacity(0.4)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      opportunity.etfName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (opportunity.readyToReplicate)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Ready',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  SizedBox(
                    width: 52,
                    height: 52,
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
                              backgroundColor: scoreColor.withOpacity(0.15),
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
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Portfolio match',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.55),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${opportunity.heldCount} held · ${opportunity.missingCount} missing',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (opportunity.totalItems > 0) ...[
                          const SizedBox(height: 2),
                          Text(
                            '${opportunity.totalItems} constituents',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.5),
                            ),
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
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
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
        mainAxisExtent: 210,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.45),
            borderRadius: BorderRadius.circular(16),
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
    final theme = Theme.of(context);
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
                    theme.scaffoldBackgroundColor.withOpacity(0),
                    theme.scaffoldBackgroundColor.withOpacity(0.92),
                  ],
                ),
              ),
              child: Icon(
                Icons.chevron_right,
                size: 20,
                color: theme.colorScheme.onSurface.withOpacity(0.45),
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
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shopping_basket_outlined,
                size: 48, color: theme.colorScheme.onSurface.withOpacity(0.35)),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton(onPressed: onReset, child: const Text('Reset filters')),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 44, color: theme.colorScheme.error),
            const SizedBox(height: 12),
            Text(
              'Couldn’t load opportunities',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.55),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
