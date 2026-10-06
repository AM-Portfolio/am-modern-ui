import 'package:am_design_system/am_design_system.dart';
import 'package:am_market_ui/features/ipo/models/ipo_models.dart';
import 'package:am_market_ui/features/ipo/providers/ipo_providers.dart';
import 'package:am_market_ui/features/ipo/widgets/ipo_filter_toolbar.dart';
import 'package:am_market_ui/features/ipo/widgets/ipo_kpi_stats_bar.dart';
import 'package:am_market_ui/features/ipo/widgets/ipo_summary_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class IpoLandingScreen extends ConsumerWidget {
  const IpoLandingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countsAsync = ref.watch(ipoCountsProvider);
    final filteredIposAsync = ref.watch(filteredIposProvider);

    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(ipoCountsProvider);
            ref.invalidate(allIposProvider);
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            slivers: [
              // 1. Header Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          if (Navigator.of(context).canPop()) ...[
                            const AmBackButton(),
                            const SizedBox(width: 8),
                          ],
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'IPOs',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: context.textPrimary,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Live & upcoming public issues',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: context.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      _buildCalendarButton(context),
                    ],
                  ),
                ),
              ),

              // 2. KPI Summary Metrics Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: countsAsync.when(
                    data: (counts) => IpoKpiStatsBar(counts: counts),
                    loading: () => const _KpiSkeleton(),
                    error: (_, __) => IpoKpiStatsBar(counts: AsraxIpoCountsDto()),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 18)),

              // 3. Filter & Search Toolbar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: countsAsync.when(
                    data: (counts) => IpoFilterToolbar(counts: counts),
                    loading: () => const SizedBox(height: 40),
                    error: (_, __) => IpoFilterToolbar(counts: AsraxIpoCountsDto()),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 18)),

              // 4. Responsive Card Grid
              filteredIposAsync.when(
                data: (ipos) {
                  if (ipos.isEmpty) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off_rounded, size: 48, color: context.textTertiary),
                            const SizedBox(height: 12),
                            Text(
                              'No IPOs match your criteria',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: context.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Try clearing filters or search query',
                              style: TextStyle(
                                fontSize: 13,
                                color: context.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextButton.icon(
                              onPressed: () {
                                ref.read(ipoFilterStateProvider.notifier).reset();
                              },
                              icon: const Icon(Icons.refresh_rounded, size: 16),
                              label: const Text('Reset Filters'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    sliver: SliverLayoutBuilder(
                      builder: (context, constraints) {
                        int crossAxisCount = 1;
                        if (constraints.crossAxisExtent >= 1150) {
                          crossAxisCount = 3;
                        } else if (constraints.crossAxisExtent >= 720) {
                          crossAxisCount = 2;
                        }

                        if (crossAxisCount == 1) {
                          return SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) => Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: IpoSummaryCard(ipo: ipos[index]),
                              ),
                              childCount: ipos.length,
                            ),
                          );
                        }

                        return SliverGrid(
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            mainAxisExtent: 268,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => IpoSummaryCard(ipo: ipos[index]),
                            childCount: ipos.length,
                          ),
                        );
                      },
                    ),
                  );
                },
                loading: () => const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (err, _) => SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline_rounded, size: 42, color: context.statusError),
                        const SizedBox(height: 12),
                        Text(
                          'Failed to load IPO data',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: context.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: () {
                            ref.invalidate(allIposProvider);
                            ref.invalidate(ipoCountsProvider);
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarButton(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: isDark ? IpoColors.darkCardBg.withValues(alpha: 0.6) : context.surfaceColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? IpoColors.darkCardBorder : context.borderColor,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.calendar_month_outlined, size: 16, color: context.textPrimary),
          const SizedBox(width: 8),
          Text(
            'IPO Calendar',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: context.textPrimary,
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right_rounded, size: 16, color: context.textTertiary),
        ],
      ),
    );
  }
}

class _KpiSkeleton extends StatelessWidget {
  const _KpiSkeleton();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: isDark ? IpoColors.darkCardBg.withValues(alpha: 0.4) : context.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? IpoColors.darkCardBorder : context.borderColor,
        ),
      ),
      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
    );
  }
}
