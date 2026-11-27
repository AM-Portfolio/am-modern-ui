import 'package:am_dashboard_ui/presentation/layout/dashboard_layout_provider.dart';
import 'package:am_dashboard_ui/presentation/layout/dashboard_layout_renderer.dart';
import 'package:am_dashboard_ui/presentation/providers/dashboard_provider.dart';
import 'package:am_dashboard_ui/presentation/providers/dashboard_timeframe_provider.dart';
import 'package:am_dashboard_ui/presentation/providers/has_demo_portfolio_provider.dart';
import 'package:am_dashboard_ui/presentation/widgets/dashboard_toolbar.dart';
import 'package:am_common/am_common.dart';
import 'package:am_design_system/am_design_system.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

bool _dashboardDataMarkedMobile = false;

/// Pixel-perfect Lumina mobile dashboard screen with Glassmorphism and Dark Theme.
class DashboardMobileScreen extends ConsumerStatefulWidget {
  final String userId;
  final VoidCallback? onOpenDocIntel;
  final VoidCallback? onOpenPaper;
  final VoidCallback? onOpenUsers;
  final ValueChanged<GlobalAddActionKind>? onQuickAdd;
  final VoidCallback? onProfileTap;
  final Widget? profileLeading;
  final String brandLabel;

  const DashboardMobileScreen({
    super.key,
    required this.userId,
    this.onOpenDocIntel,
    this.onOpenPaper,
    this.onOpenUsers,
    this.onQuickAdd,
    this.onProfileTap,
    this.profileLeading,
    this.brandLabel = 'AM Investment',
  });

  @override
  ConsumerState<DashboardMobileScreen> createState() =>
      _DashboardMobileScreenState();
}

class _DashboardMobileScreenState extends ConsumerState<DashboardMobileScreen> {
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
    ref.invalidate(accountsHubProvider(id));
    ref.invalidate(portfolioOverviewsProvider(id));
    ref.invalidate(hasDemoPortfolioProvider);
    ref.invalidate(dashboardStreamProvider(id));
  }

  void _listenDashboardFirstData(WidgetRef ref, String tfCode) {
    void markIfReady(AsyncValue<dynamic> next) {
      if (!_dashboardDataMarkedMobile && next.hasValue) {
        _dashboardDataMarkedMobile = true;
        BootTrace.instance.mark('dashboard_first_data');
      }
    }

    ref.listen(
      dashboardStreamProvider(widget.userId),
      (_, next) => markIfReady(next),
    );
    ref.listen(
      moversStreamProvider(widget.userId, timeFrame: tfCode),
      (_, next) => markIfReady(next),
    );
    ref.listen(
      recentActivityProvider(widget.userId, page: 0, size: 10),
      (_, next) => markIfReady(next),
    );
    ref.listen(
      portfolioOverviewsProvider(widget.userId),
      (_, next) => markIfReady(next),
    );
  }

  Widget _buildStickyHeader({required Color onSurface}) {
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

    return DashboardToolbar(
      userId: widget.userId,
      onSurface: onSurface,
      brandLabel: widget.brandLabel,
      profileLeading: widget.profileLeading,
      onProfileTap: widget.onProfileTap,
      onOpenPaper: widget.onOpenPaper,
      onOpenUsers: widget.onOpenUsers,
      onQuickAdd: widget.onQuickAdd,
      onSearch: () {
        if (MobileSearchScope.tryOpenGlobalSearch(context)) return;
        MobileSearchScope.setOpen(context, true);
        setState(() => _searchOpen = true);
      },
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
      ref.invalidate(accountsHubProvider(userId));
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
          ],
          SafeArea(
            child: Column(
              children: [
                // Sticky top: Sync / paper / timeframe
                _buildStickyHeader(onSurface: onSurface),
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
                          if (showDemoBanner) ...[
                            const _MobileDemoAccountCard(),
                            const SizedBox(height: AppSpacing.md),
                          ],
                          DashboardLayoutRenderer(
                            userId: userId,
                            layout: layout,
                            timeFrameCode: tfCode,
                            onOpenDocIntel: widget.onOpenDocIntel,
                            onOpenPaper: widget.onOpenPaper,
                            onOpenUsers: widget.onOpenUsers,
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

class _MobileDemoAccountCard extends StatelessWidget {
  const _MobileDemoAccountCard();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const accent = Color(0xFFE0B93A);
    final accentText = isDark
        ? const Color(0xFFF2D56B)
        : const Color(0xFF765300);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accent.withValues(alpha: isDark ? 0.18 : 0.16),
            accent.withValues(alpha: isDark ? 0.08 : 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: accent.withValues(alpha: 0.55)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
            child: Icon(Icons.explore_outlined, color: accentText, size: 21),
          ),
          const SizedBox(width: AppSpacing.sm + 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Demo Account',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: accentText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Explore the sample portfolio above, or tap + to add your own.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    height: 1.35,
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
