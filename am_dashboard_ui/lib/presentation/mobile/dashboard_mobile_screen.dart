import 'package:am_dashboard_ui/presentation/layout/dashboard_customize_sheet.dart';
import 'package:am_dashboard_ui/presentation/layout/dashboard_layout_provider.dart';
import 'package:am_dashboard_ui/presentation/layout/dashboard_layout_renderer.dart';
import 'package:am_dashboard_ui/presentation/layout/dashboard_layout_store.dart';
import 'package:am_dashboard_ui/presentation/providers/dashboard_provider.dart';
import 'package:am_dashboard_ui/presentation/providers/dashboard_timeframe_provider.dart';
import 'package:am_dashboard_ui/presentation/providers/has_demo_portfolio_provider.dart';
import 'package:am_dashboard_ui/presentation/widgets/paper_trading_nav_chip.dart';
import 'package:am_common/am_common.dart';
import '../shared/widgets/glass_card.dart';
import 'package:am_design_system/am_design_system.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';

bool _dashboardDataMarkedMobile = false;

/// Pixel-perfect Lumina mobile dashboard screen with Glassmorphism and Dark Theme.
class DashboardMobileScreen extends ConsumerStatefulWidget {
  final String userId;
  final VoidCallback? onOpenDocIntel;
  final VoidCallback? onOpenPaper;
  final ValueChanged<GlobalAddActionKind>? onQuickAdd;

  const DashboardMobileScreen({
    super.key,
    required this.userId,
    this.onOpenDocIntel,
    this.onOpenPaper,
    this.onQuickAdd,
  });

  @override
  ConsumerState<DashboardMobileScreen> createState() =>
      _DashboardMobileScreenState();
}

class _DashboardMobileScreenState
    extends ConsumerState<DashboardMobileScreen> {
  late final PageController _pageController;
  bool _searchOpen = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    PortfolioDataRefresh.instance.addListener(_onHoldingsImported);
  }

  @override
  void dispose() {
    PortfolioDataRefresh.instance.removeListener(_onHoldingsImported);
    _pageController.dispose();
    super.dispose();
  }

  void _onHoldingsImported() {
    if (!mounted) return;
    final id = widget.userId;
    if (id.isEmpty) return;
    ref.invalidate(portfolioOverviewsProvider(id));
    ref.invalidate(hasDemoPortfolioProvider);
    ref.invalidate(dashboardStreamProvider(id));
  }

  Widget _buildLoadingCard(double height, {String? label}) {
    return AmGlassCard(
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Expanded(
              child: ShimmerLoading(
                child: SkeletonBox(
                  width: double.infinity,
                  height: double.infinity,
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
              ),
            ),
            if (label != null) ...[
              const SizedBox(height: 12),
              Text(
                label,
                style: context.text.caption().copyWith(
                      color: context.colors.textSecondary,
                    ),
              ),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }

  void _listenDashboardFirstData(WidgetRef ref, String tfCode) {
    void markIfReady(AsyncValue<dynamic> next) {
      if (!_dashboardDataMarkedMobile && next.hasValue) {
        _dashboardDataMarkedMobile = true;
        BootTrace.instance.mark('dashboard_first_data');
      }
    }

    ref.listen(dashboardStreamProvider(widget.userId), (_, next) => markIfReady(next));
    ref.listen(
      moversStreamProvider(widget.userId, timeFrame: tfCode),
      (_, next) => markIfReady(next),
    );
    ref.listen(
      recentActivityProvider(widget.userId, page: 0, size: 10),
      (_, next) => markIfReady(next),
    );
    ref.listen(portfolioOverviewsProvider(widget.userId), (_, next) => markIfReady(next));
  }

  Widget _buildStickyHeader({
    required Color onSurface,
    required bool showDemoBadge,
  }) {
    final scope = MobileSearchScope.maybeOf(context);
    final shellHandlesSearch = scope?.liveSearch != null;
    if (_searchOpen && !shellHandlesSearch) {
      return MobileInlineSearchField(
        items: MobileSearchScope.itemsOf(context),
        onClose: () {
          MobileSearchScope.setOpen(context, false);
          setState(() => _searchOpen = false);
        },
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = ModuleColors.dashboard;
    const trackHeight = 58.0;
    const segmentHeight = 50.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
      child: NavigationChrome.glass(
        context: context,
        isDark: isDark,
        borderRadius: 24,
        child: SizedBox(
          height: trackHeight,
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Row(
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    if (MobileSearchScope.tryOpenGlobalSearch(context)) return;
                    MobileSearchScope.setOpen(context, true);
                    setState(() => _searchOpen = true);
                  },
                  child: SizedBox(
                    width: 44,
                    height: segmentHeight,
                    child: Icon(
                      Icons.search_rounded,
                      color: accent,
                      size: 22,
                    ),
                  ),
                ),
                if (showDemoBadge) ...[
                  const SizedBox(width: 4),
                  const DemoAccountBadge(),
                ],
                const Spacer(),
                if (kDashboardCustomizeEnabled)
                  IconButton(
                    tooltip: 'Customize dashboard',
                    onPressed: () => DashboardCustomizeSheet.show(context),
                    icon: Icon(Icons.tune, color: onSurface, size: 22),
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 40, minHeight: 40),
                  ),
                if (widget.onOpenPaper != null) ...[
                  PaperTradingNavChip(onTap: widget.onOpenPaper!),
                  const SizedBox(width: 6),
                ],
                const GlobalTimeFrameBar(
                  variant: GlobalTimeFrameVariant.dropdown,
                ),
                if (widget.onQuickAdd != null)
                  SyncQuickActionsControl(
                    accentColor: accent,
                    iconColor: onSurface,
                    actions: buildGlobalAddMenuActions(widget.onQuickAdd!),
                    showSubtitles: false,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = widget.userId;
    ref.watch(dashboardStreamingSessionProvider(userId));
    ref.listen(appTimeFrameProvider, (previous, next) {
      if (previous != next) {
        onDashboardTimeFrameChanged(ref, userId, next);
      }
    });
    final timeFrame = ref.watch(appTimeFrameProvider);
    final tfCode = timeFrame.code;

    final layout = ref.watch(dashboardLayoutProvider);

    ref.watch(dashboardParallelKickoffProvider(userId, timeFrame: tfCode));
    _listenDashboardFirstData(ref, tfCode);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = Theme.of(context).colorScheme.surface;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    Future<void> refresh() async {
      retryDashboardSummary(ref, userId);
      ref.invalidate(portfolioOverviewsProvider(userId));
      ref.invalidate(hasDemoPortfolioProvider);
    }

    final showDemoBanner =
        ref.watch(hasDemoPortfolioProvider).asData?.value ?? false;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          if (isDark) ...[
            Positioned(
              top: -100,
              left: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      context.colors.actionPrimaryBg.withValues(alpha: 0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -50,
              right: -50,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      context.colors.actionPrimaryBg.withValues(alpha: 0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                child: Container(color: Colors.transparent),
              ),
            ),
          ],
          SafeArea(
            child: Column(
              children: [
                // Sticky top: Sync / paper / timeframe
                _buildStickyHeader(
                  onSurface: onSurface,
                  showDemoBadge: showDemoBanner,
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: refresh,
                    color: ModuleColors.dashboard,
                    backgroundColor: context.colors.surface,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: EdgeInsets.fromLTRB(
                        16,
                        8,
                        16,
                        PlatformConstants.globalBottomNavReserve(context) + 16,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          DashboardLayoutRenderer(
                            userId: userId,
                            layout: layout,
                            timeFrameCode: tfCode,
                            onOpenDocIntel: widget.onOpenDocIntel,
                            onOpenPaper: widget.onOpenPaper,
                            compactBreakpoint: 99999,
                            chartHeight: 350,
                            mobileChartHeight: 350,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
