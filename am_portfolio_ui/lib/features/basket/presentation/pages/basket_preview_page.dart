import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:am_design_system/am_design_system.dart';
import '../providers/basket_providers.dart';
import '../basket_navigation.dart';
import '../../domain/models/basket_opportunity.dart';
import '../../domain/models/basket_enums.dart';

// New Modular Widgets
import '../widgets/preview/preview_hero_header.dart';
import '../widgets/preview/preview_section_header.dart';
import '../widgets/preview/preview_stock_row.dart';
import '../widgets/preview/preview_summary_sidebar.dart';

class BasketPreviewPage extends ConsumerWidget {
  final String etfIsin;
  final String userId;
  final String portfolioId;
  final bool embedded;

  const BasketPreviewPage({
    super.key,
    required this.etfIsin,
    required this.userId,
    required this.portfolioId,
    this.embedded = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final opportunityAsync = ref.watch(enhancedBasketPreviewProvider(
      etfIsin: etfIsin,
      userId: userId,
      portfolioId: portfolioId,
    ));

    final body = opportunityAsync.when(
      data: (opportunity) => _BasketContent(
        opportunity: opportunity,
        userId: userId,
        portfolioId: portfolioId,
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );

    // Apply Dark Theme override for this specific page to match premium aesthetic
    return Theme(
      data: AppTheme.darkTheme,
      child: Builder(
        builder: (innerContext) => Scaffold(
          backgroundColor: innerContext.colors.scaffoldBackground,
          appBar: embedded
              ? null
              : AppBar(
                  title: const Text('Basket Preview'),
                  centerTitle: false,
                  backgroundColor: innerContext.colors.surface,
                  elevation: 0,
                ),
          body: body,
        ),
      ),
    );
  }
}

class _BasketContent extends StatelessWidget {
  final BasketOpportunity opportunity;
  final String userId;
  final String portfolioId;

  const _BasketContent({
    required this.opportunity,
    required this.userId,
    required this.portfolioId,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 800;

        if (isDesktop) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Pane: Hero + Grouped Lists
              Expanded(
                flex: 65,
                child: _buildScrollableContent(context, isDesktop),
              ),
              // Right Pane: Sticky Summary Sidebar
              Container(
                width: 350,
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(color: context.colors.border),
                  ),
                ),
                child: SingleChildScrollView(
                  child: PreviewSummarySidebar(
                    opportunity: opportunity,
                    onCustomizeTap: () => BasketNavigation.openCreator(
                      context,
                      opportunity: opportunity,
                      userId: userId,
                      portfolioId: portfolioId,
                    ),
                  ),
                ),
              ),
            ],
          );
        } else {
          // Mobile: Stacked view with sticky CTA at bottom
          return Column(
            children: [
              Expanded(
                child: _buildScrollableContent(context, isDesktop),
              ),
              _BottomActionBar(
                onPressed: () => BasketNavigation.openCreator(
                  context,
                  opportunity: opportunity,
                  userId: userId,
                  portfolioId: portfolioId,
                ),
              ),
            ],
          );
        }
      },
    );
  }

  Widget _buildScrollableContent(BuildContext context, bool isDesktop) {
    final heldItems = opportunity.composition
        .where((item) => item.status == ItemStatus.held)
        .toList();
    final substituteItems = opportunity.composition
        .where((item) => item.status == ItemStatus.substitute)
        .toList();
    final missingItems = opportunity.composition
        .where((item) => item.status == ItemStatus.missing)
        .toList();

    return CustomScrollView(
      slivers: [
        if (!isDesktop) // Standard AppBar handles this on Desktop if not embedded, but we just use HeroHeader
          SliverToBoxAdapter(
            child: PreviewHeroHeader(opportunity: opportunity),
          ),
        if (isDesktop)
          SliverToBoxAdapter(
            child: PreviewHeroHeader(opportunity: opportunity),
          ),
        
        // Missing Section
        if (missingItems.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: PreviewSectionHeader(
              title: 'Missing / Swap Required',
              subtitle: '${missingItems.length} Stocks',
              statusType: ItemStatus.missing,
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => PreviewStockRow(item: missingItems[index]),
              childCount: missingItems.length,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
        ],

        // Substituted Section
        if (substituteItems.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: PreviewSectionHeader(
              title: 'Automatically Substituted',
              subtitle: '${substituteItems.length} Stocks',
              statusType: ItemStatus.substitute,
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => PreviewStockRow(item: substituteItems[index]),
              childCount: substituteItems.length,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
        ],

        // Held Section
        if (heldItems.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: PreviewSectionHeader(
              title: 'Held in Portfolio',
              subtitle: '${heldItems.length} Stocks',
              statusType: ItemStatus.held,
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => PreviewStockRow(item: heldItems[index]),
              childCount: heldItems.length,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
        ],
      ],
    );
  }
}

class _BottomActionBar extends StatelessWidget {
  final VoidCallback onPressed;

  const _BottomActionBar({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border(
          top: BorderSide(color: context.colors.border),
        ),
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: onPressed,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            ),
            child: const Text('Customize & Create Portfolio'),
          ),
        ),
      ),
    );
  }
}
