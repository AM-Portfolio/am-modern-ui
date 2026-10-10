import 'package:am_design_system/am_design_system.dart';
import 'package:am_market_ui/features/ipo/models/ipo_models.dart';
import 'package:am_market_ui/features/ipo/providers/ipo_providers.dart';
import 'package:am_market_ui/features/ipo/widgets/ipo_board_badge.dart';
import 'package:am_market_ui/features/ipo/widgets/ipo_documents_card.dart';
import 'package:am_market_ui/features/ipo/widgets/ipo_eligible_investors_card.dart';
import 'package:am_market_ui/features/ipo/widgets/ipo_overview_header_card.dart';
import 'package:am_market_ui/features/ipo/widgets/ipo_registrar_card.dart';
import 'package:am_market_ui/features/ipo/widgets/ipo_subscription_status_card.dart';
import 'package:am_market_ui/features/ipo/widgets/ipo_timeline_stepper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class IpoDetailsScreen extends ConsumerStatefulWidget {
  final String ipoId;

  /// When true (Market IPO Center host), skip outer Scaffold/SafeArea so the
  /// Market module navbar and app chrome stay visible.
  final bool embedded;

  const IpoDetailsScreen({
    super.key,
    required this.ipoId,
    this.embedded = false,
  });

  @override
  ConsumerState<IpoDetailsScreen> createState() => _IpoDetailsScreenState();
}

class _IpoDetailsScreenState extends ConsumerState<IpoDetailsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detailsAsync = ref.watch(ipoDetailsProvider(widget.ipoId));

    final body = detailsAsync.when(
      data: (ipo) => _buildContent(context, ipo),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: context.statusError,
            ),
            const SizedBox(height: 12),
            Text(
              'Failed to load IPO details',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () =>
                  ref.invalidate(ipoDetailsProvider(widget.ipoId)),
              child: const Text('Retry'),
            ),
          ],
        ),
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

  Widget _buildContent(BuildContext context, AsraxIpoDetailsDto ipo) {
    final width = MediaQuery.sizeOf(context).width;
    final isCompact = width < AmBreakpoints.mobile;

    if (!isCompact) {
      return SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBackButton(context),
            const SizedBox(height: 12),
            IpoOverviewHeaderCard(ipo: ipo),
            const SizedBox(height: 16),
            IpoTimelineStepper(
              timeline: ipo.timeline,
              dailyStartTime: ipo.dailyStartTime,
              dailyEndTime: ipo.dailyEndTime,
              listingExchange: ipo.listingExchange,
            ),
            const SizedBox(height: 16),
            _buildDesktopCards(context, ipo),
          ],
        ),
      );
    }

    // Mobile: compact identity + section tabs (no nested scroll views).
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 12, 0),
          child: _buildMobileIdentityHeader(context, ipo),
        ),
        TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: ModuleColors.market,
          unselectedLabelColor: context.textSecondary,
          indicatorColor: ModuleColors.market,
          indicatorWeight: 2.5,
          labelStyle: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
          ),
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Lot Size'),
            Tab(text: 'Documents'),
          ],
        ),
        Divider(height: 1, color: context.dividerColor),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _MobileScroll(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    IpoOverviewHeaderCard(ipo: ipo, metricsOnly: true),
                    const SizedBox(height: 12),
                    IpoTimelineStepper(
                      timeline: ipo.timeline,
                      dailyStartTime: ipo.dailyStartTime,
                      dailyEndTime: ipo.dailyEndTime,
                      listingExchange: ipo.listingExchange,
                    ),
                    const SizedBox(height: 12),
                    IpoSubscriptionStatusCard(
                      totalSubscription: ipo.totalSubscription,
                      eligibleInvestors: ipo.eligibleInvestors ?? const [],
                    ),
                    const SizedBox(height: 12),
                    IpoEligibleInvestorsCard(
                      eligibleInvestors: ipo.eligibleInvestors,
                    ),
                    const SizedBox(height: 12),
                    IpoRegistrarCard(registrar: ipo.registrarInfo),
                  ],
                ),
              ),
              _MobileScroll(
                child: IpoOverviewHeaderCard(ipo: ipo, lotSizeOnly: true),
              ),
              _MobileScroll(
                child: IpoDocumentsCard(
                  rhpUrl: ipo.rhpUrl,
                  drhpUrl: ipo.drhpUrl,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileIdentityHeader(
    BuildContext context,
    AsraxIpoDetailsDto ipo,
  ) {
    final status = (ipo.status ?? 'OPEN').toUpperCase();
    final statusColor = _statusColor(context, status);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final initials = _getInitials(ipo.companyName ?? ipo.symbol ?? 'IP');
    final avatarColor = IpoColors.avatarColorFor(initials);

    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded, size: 22),
          visualDensity: VisualDensity.compact,
        ),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: avatarColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            initials,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: avatarColor,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ipo.companyName ?? 'IPO Details',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: context.textPrimary,
                  letterSpacing: -0.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  if (ipo.symbol != null && ipo.symbol!.isNotEmpty) ...[
                    Flexible(
                      child: Text(
                        ipo.symbol!,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: context.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      ' • ',
                      style: TextStyle(
                        fontSize: 11,
                        color: context.textTertiary,
                      ),
                    ),
                  ],
                  IpoBoardBadge(issueType: ipo.issueType),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: isDark ? 0.18 : 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: statusColor.withValues(alpha: isDark ? 0.45 : 0.35),
              width: 0.9,
            ),
          ),
          child: Text(
            status,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: statusColor,
              letterSpacing: 0.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopCards(BuildContext context, AsraxIpoDetailsDto ipo) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 780;

        if (isWide) {
          return Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: IpoDocumentsCard(
                      rhpUrl: ipo.rhpUrl,
                      drhpUrl: ipo.drhpUrl,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: IpoRegistrarCard(registrar: ipo.registrarInfo),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: IpoSubscriptionStatusCard(
                      totalSubscription: ipo.totalSubscription,
                      eligibleInvestors: ipo.eligibleInvestors ?? const [],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: IpoEligibleInvestorsCard(
                      eligibleInvestors: ipo.eligibleInvestors,
                    ),
                  ),
                ],
              ),
            ],
          );
        }

        return Column(
          children: [
            IpoDocumentsCard(
              rhpUrl: ipo.rhpUrl,
              drhpUrl: ipo.drhpUrl,
            ),
            const SizedBox(height: 16),
            IpoRegistrarCard(registrar: ipo.registrarInfo),
            const SizedBox(height: 16),
            IpoSubscriptionStatusCard(
              totalSubscription: ipo.totalSubscription,
              eligibleInvestors: ipo.eligibleInvestors ?? const [],
            ),
            const SizedBox(height: 16),
            IpoEligibleInvestorsCard(
              eligibleInvestors: ipo.eligibleInvestors,
            ),
          ],
        );
      },
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: IconButton(
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(Icons.arrow_back_rounded, size: 22),
        visualDensity: VisualDensity.compact,
        tooltip: 'Back',
      ),
    );
  }

  Color _statusColor(BuildContext context, String status) {
    switch (status) {
      case 'OPEN':
        return context.colors.statusSuccess;
      case 'UPCOMING':
        return context.colors.statusWarning;
      default:
        return context.colors.statusError;
    }
  }

  String _getInitials(String name) {
    final clean = name
        .replaceAll(RegExp(r'(IPO|Limited|Ltd|\.)', caseSensitive: false), '')
        .trim();
    final parts =
        clean.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'IP';
    if (parts.length == 1) {
      return parts[0].substring(0, parts[0].length.clamp(1, 2)).toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}

class _MobileScroll extends StatelessWidget {
  const _MobileScroll({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 28),
      child: child,
    );
  }
}
