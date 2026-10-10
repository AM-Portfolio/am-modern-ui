import 'package:am_design_system/am_design_system.dart';
import 'package:am_market_ui/features/ipo/models/ipo_models.dart';
import 'package:am_market_ui/features/ipo/providers/ipo_providers.dart';
import 'package:am_market_ui/features/ipo/widgets/ipo_documents_card.dart';
import 'package:am_market_ui/features/ipo/widgets/ipo_eligible_investors_card.dart';
import 'package:am_market_ui/features/ipo/widgets/ipo_overview_header_card.dart';
import 'package:am_market_ui/features/ipo/widgets/ipo_registrar_card.dart';
import 'package:am_market_ui/features/ipo/widgets/ipo_subscription_status_card.dart';
import 'package:am_market_ui/features/ipo/widgets/ipo_timeline_stepper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class IpoDetailsScreen extends ConsumerWidget {
  final String ipoId;

  const IpoDetailsScreen({super.key, required this.ipoId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailsAsync = ref.watch(ipoDetailsProvider(ipoId));

    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: SafeArea(
        child: detailsAsync.when(
          data: (ipo) => _buildContent(context, ipo),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline_rounded,
                    size: 48, color: context.statusError),
                const SizedBox(height: 12),
                Text(
                  'Failed to load IPO details',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: context.textPrimary),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => ref.invalidate(ipoDetailsProvider(ipoId)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, AsraxIpoDetailsDto ipo) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Breadcrumb Navigation
          _buildBreadcrumbs(context, ipo.companyName ?? 'IPO Details'),
          const SizedBox(height: 16),

          // 2. Main Overview Header Card
          IpoOverviewHeaderCard(ipo: ipo),
          const SizedBox(height: 16),

          // 3. Important Dates Timeline Card
          IpoTimelineStepper(
            timeline: ipo.timeline,
            dailyStartTime: ipo.dailyStartTime,
            dailyEndTime: ipo.dailyEndTime,
            listingExchange: ipo.listingExchange,
          ),
          const SizedBox(height: 16),

          // 4. 2x2 Grid of Detail Cards
          LayoutBuilder(
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
                            eligibleInvestors:
                                ipo.eligibleInvestors ?? const [],
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

              // Single Column for Mobile
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
          ),
        ],
      ),
    );
  }

  Widget _buildBreadcrumbs(BuildContext context, String companyName) {
    return Row(
      children: [
        InkWell(
          onTap: () => Navigator.of(context).pop(),
          borderRadius: BorderRadius.circular(6),
          child: const Padding(
            padding: EdgeInsets.all(4),
            child: Icon(Icons.arrow_back_rounded, size: 20),
          ),
        ),
        const SizedBox(width: 8),
        InkWell(
          onTap: () => Navigator.of(context).pop(),
          child: Text(
            'Market',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: context.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Icon(Icons.chevron_right_rounded,
            size: 16, color: context.textTertiary),
        const SizedBox(width: 6),
        InkWell(
          onTap: () => Navigator.of(context).pop(),
          child: Text(
            'IPOs',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: context.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Icon(Icons.chevron_right_rounded,
            size: 16, color: context.textTertiary),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            companyName,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: context.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
