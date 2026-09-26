import 'package:am_design_system/am_design_system.dart';
import 'package:am_market_ui/features/ipo/models/ipo_models.dart';
import 'package:am_market_ui/features/ipo/providers/ipo_providers.dart';
import 'package:am_market_ui/features/ipo/widgets/ipo_details_header.dart';
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
      appBar: AppBar(
        backgroundColor: context.backgroundColor,
        elevation: 0,
        leading: const AmBackButton(),
        title: Text(
          'IPO Details',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: context.textPrimary,
          ),
        ),
      ),
      body: detailsAsync.when(
        data: (details) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(ipoDetailsProvider(ipoId));
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IpoDetailsHeader(details: details),
                const SizedBox(height: AppSpacing.lg),
                _buildSectionTitle(context, 'Issue Details'),
                const SizedBox(height: AppSpacing.sm),
                _buildIssueDetailsCard(context, details),
                const SizedBox(height: AppSpacing.lg),
                _buildSectionTitle(context, 'Timeline'),
                const SizedBox(height: AppSpacing.sm),
                _buildTimelineCard(context, details.timeline),
                const SizedBox(height: AppSpacing.lg),
                _buildSectionTitle(context, 'About Company'),
                const SizedBox(height: AppSpacing.sm),
                _buildAboutCard(context, details),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Failed to load IPO details', style: TextStyle(color: context.statusError)),
              const SizedBox(height: AppSpacing.sm),
              ElevatedButton(
                onPressed: () => ref.invalidate(ipoDetailsProvider(ipoId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: context.textPrimary,
      ),
    );
  }

  Widget _buildIssueDetailsCard(BuildContext context, AsraxIpoDetailsDto details) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          _buildDetailRow(context, 'Bidding Dates', 
            details.biddingStartDate != null && details.biddingEndDate != null
              ? '${_formatDate(details.biddingStartDate!)} - ${_formatDate(details.biddingEndDate!)}'
              : 'TBA'),
          const Divider(),
          _buildDetailRow(context, 'Minimum Investment', 
            details.cutOffPrice != null && details.lotSize != null 
              ? '₹${(details.cutOffPrice! * details.lotSize!).toStringAsFixed(0)} (${details.lotSize} shares)'
              : 'TBA'),
          const Divider(),
          _buildDetailRow(context, 'Price Range', 
            details.minimumPrice != null && details.maximumPrice != null 
              ? '₹${details.minimumPrice} - ₹${details.maximumPrice}'
              : 'TBA'),
          const Divider(),
          _buildDetailRow(context, 'Lot Size', '${details.lotSize ?? '--'} Shares'),
          const Divider(),
          _buildDetailRow(context, 'Issue Size', '${details.issueSizeCr ?? '--'} Cr'),
          const Divider(),
          _buildDetailRow(context, 'Subscription', details.totalSubscription != null ? '${details.totalSubscription}x' : '--'),
        ],
      ),
    );
  }

  Widget _buildTimelineCard(BuildContext context, AsraxIpoTimelineDto? timeline) {
    if (timeline == null) return const AppCard(child: Padding(padding: EdgeInsets.all(AppSpacing.md), child: Text('No timeline available.')));
    
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          _buildTimelineRow(context, 'Bidding Starts', timeline.biddingStartDate),
          _buildTimelineRow(context, 'Bidding Ends', timeline.biddingEndDate),
          _buildTimelineRow(context, 'Allotment', timeline.allotmentDate),
          _buildTimelineRow(context, 'Refund Initiation', timeline.refundInitiationDate),
          _buildTimelineRow(context, 'Demat Transfer', timeline.dematTransferDate),
          _buildTimelineRow(context, 'Listing Date', timeline.listingDate, isLast: true),
        ],
      ),
    );
  }

  Widget _buildTimelineRow(BuildContext context, String title, String? dateStr, {bool isLast = false}) {
    final hasDate = dateStr != null && dateStr.isNotEmpty;
    
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: hasDate ? ModuleColors.market : context.borderColor,
                  shape: BoxShape.circle,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: context.borderColor,
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: context.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasDate ? _formatDate(dateStr) : 'TBA',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutCard(BuildContext context, AsraxIpoDetailsDto details) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow(context, 'Industry', details.industry ?? '--'),
          if (details.registrarInfo != null) ...[
            const Divider(),
            _buildDetailRow(context, 'Registrar', details.registrarInfo!.name ?? '--'),
          ],
          if (details.rhpUrl != null || details.drhpUrl != null) ...[
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Documents',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.textSecondary),
                ),
                Row(
                  children: [
                    if (details.drhpUrl != null)
                      TextButton(
                        onPressed: () {},
                        child: const Text('DRHP'),
                      ),
                    if (details.rhpUrl != null)
                      TextButton(
                        onPressed: () {},
                        child: const Text('RHP'),
                      ),
                  ],
                ),
              ],
            )
          ]
        ],
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.textSecondary),
          ),
          Flexible(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.textPrimary, fontWeight: FontWeight.w500),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (e) {
      return dateStr;
    }
  }
}
