import 'package:am_design_system/am_design_system.dart';
import 'package:am_market_ui/features/ipo/ipo_layout.dart';
import 'package:am_market_ui/features/ipo/models/ipo_models.dart';
import 'package:am_market_ui/features/ipo/providers/ipo_providers.dart';
import 'package:am_market_ui/features/ipo/widgets/ipo_filter_toolbar.dart';
import 'package:am_market_ui/features/ipo/widgets/ipo_kpi_stats_bar.dart';
import 'package:am_market_ui/features/ipo/widgets/ipo_summary_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class IpoLandingScreen extends ConsumerStatefulWidget {
  const IpoLandingScreen({
    super.key,
    this.embedded = false,
  });

  /// When true (Market shell host), skip outer Scaffold/SafeArea.
  final bool embedded;

  static const int pageSize = 20;

  @override
  ConsumerState<IpoLandingScreen> createState() => _IpoLandingScreenState();
}

class _IpoLandingScreenState extends ConsumerState<IpoLandingScreen> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final countsAsync = ref.watch(ipoCountsProvider);
    final filteredIposAsync = ref.watch(filteredIposProvider);
    final width = MediaQuery.sizeOf(context).width;
    final isCompactMobile = width < AmBreakpoints.mobile;
    final hPad = isCompactMobile ? 12.0 : 14.0;

    ref.listen<IpoFilterState>(ipoFilterStateProvider, (prev, next) {
      if (_page != 0) {
        setState(() => _page = 0);
      }
    });

    final body = RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(ipoCountsProvider);
        ref.invalidate(allIposProvider);
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          if (!(widget.embedded && isCompactMobile))
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  hPad,
                  widget.embedded ? 8 : 16,
                  hPad,
                  16,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          if (!widget.embedded &&
                              Navigator.of(context).canPop()) ...[
                            const AmBackButton(),
                            const SizedBox(width: 8),
                          ],
                          Expanded(
                            child: Column(
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
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Live & upcoming public issues',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: context.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!isCompactMobile) ...[
                      const SizedBox(width: 8),
                      _buildCalendarButton(context),
                    ],
                  ],
                ),
              ),
            ),

          if (!isCompactMobile) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: hPad),
                child: countsAsync.when(
                  data: (counts) => IpoKpiStatsBar(counts: counts),
                  loading: () => const _KpiSkeleton(),
                  error: (_, __) =>
                      IpoKpiStatsBar(counts: AsraxIpoCountsDto()),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 14)),
          ] else
            SliverToBoxAdapter(
              child: SizedBox(height: widget.embedded ? 8 : 12),
            ),

          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: hPad),
              child: countsAsync.when(
                data: (counts) => IpoFilterToolbar(counts: counts),
                loading: () => const SizedBox(height: 40),
                error: (_, __) =>
                    IpoFilterToolbar(counts: AsraxIpoCountsDto()),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: SizedBox(height: isCompactMobile ? 12 : 14),
          ),

          ...filteredIposAsync.when(
            data: (ipos) => _buildIpoSlivers(context, ipos, hPad),
            loading: () => const [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              ),
            ],
            error: (err, _) => [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        size: 42,
                        color: context.statusError,
                      ),
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
            ],
          ),
        ],
      ),
    );

    if (widget.embedded) {
      return ColoredBox(
        color: context.backgroundColor,
        child: body,
      );
    }

    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: SafeArea(child: body),
    );
  }

  List<Widget> _buildIpoSlivers(
    BuildContext context,
    List<AsraxIpoSummaryDto> ipos,
    double hPad,
  ) {
    if (ipos.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off_rounded,
                  size: 48,
                  color: context.textTertiary,
                ),
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
        ),
      ];
    }

    final window = ipoPageWindow(
      ipos,
      page: _page,
      pageSize: IpoLandingScreen.pageSize,
    );
    if (window.page != _page) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _page = window.page);
      });
    }
    final pageItems = window.items;

    return [
      SliverPadding(
        padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 8),
        sliver: SliverLayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount =
                columnsForIpoGrid(constraints.crossAxisExtent);

            if (crossAxisCount == 1) {
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: IpoSummaryCard(
                      ipo: pageItems[index],
                      compact: true,
                    ),
                  ),
                  childCount: pageItems.length,
                ),
              );
            }

            return SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                mainAxisExtent: 104,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => Align(
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    width: double.infinity,
                    child: IpoSummaryCard(
                      ipo: pageItems[index],
                      compact: true,
                    ),
                  ),
                ),
                childCount: pageItems.length,
              ),
            );
          },
        ),
      ),
      if (ipos.length > IpoLandingScreen.pageSize)
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(hPad, 4, hPad, 20),
            child: _IpoPaginationFooter(
              from: window.from,
              to: window.to,
              total: ipos.length,
              page: window.page,
              totalPages: window.totalPages,
              onPrev: window.page > 0
                  ? () => setState(() => _page = window.page - 1)
                  : null,
              onNext: window.page < window.totalPages - 1
                  ? () => setState(() => _page = window.page + 1)
                  : null,
            ),
          ),
        )
      else
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
    ];
  }

  Widget _buildCalendarButton(BuildContext context) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: context.borderColor,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.calendar_month_outlined,
            size: 16,
            color: context.textPrimary,
          ),
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
          Icon(
            Icons.chevron_right_rounded,
            size: 16,
            color: context.textTertiary,
          ),
        ],
      ),
    );
  }
}

class _IpoPaginationFooter extends StatelessWidget {
  const _IpoPaginationFooter({
    required this.from,
    required this.to,
    required this.total,
    required this.page,
    required this.totalPages,
    required this.onPrev,
    required this.onNext,
  });

  final int from;
  final int to;
  final int total;
  final int page;
  final int totalPages;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.borderColor),
      ),
      child: Row(
        children: [
          Text(
            '$from–$to of $total',
            style: TextStyle(
              fontSize: 12,
              color: context.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: onPrev,
            icon: const Icon(Icons.chevron_left_rounded, size: 22),
            tooltip: 'Previous',
            visualDensity: VisualDensity.compact,
            color: ModuleColors.market,
          ),
          Text(
            '${page + 1} / $totalPages',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: context.textPrimary,
            ),
          ),
          IconButton(
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right_rounded, size: 22),
            tooltip: 'Next',
            visualDensity: VisualDensity.compact,
            color: ModuleColors.market,
          ),
        ],
      ),
    );
  }
}

class _KpiSkeleton extends StatelessWidget {
  const _KpiSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.borderColor,
        ),
      ),
      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
    );
  }
}
