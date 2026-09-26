import 'package:am_design_system/am_design_system.dart';
import 'package:am_market_ui/features/ipo/models/ipo_models.dart';
import 'package:am_market_ui/features/ipo/screens/ipo_details_screen.dart';
import 'package:am_market_ui/core/styles/market_theme_extension.dart';
import 'package:flutter/material.dart';

class IpoSummaryCard extends StatelessWidget {
  final AsraxIpoSummaryDto ipo;

  const IpoSummaryCard({super.key, required this.ipo});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => IpoDetailsScreen(ipoId: ipo.id),
          ),
        );
      },
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildCompanyLogo(context),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ipo.companyName ?? 'Unknown',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: context.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      ipo.biddingStartDate != null && ipo.biddingEndDate != null
                          ? '${_formatDate(ipo.biddingStartDate!)} - ${_formatDate(ipo.biddingEndDate!)}'
                          : 'Dates TBA',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(context),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMetricColumn(context, 'Issue Size', _formatIssueSize(ipo.issueSizeCr)),
              _buildMetricColumn(context, 'Price Band', _formatPriceBand(ipo.minimumPrice, ipo.maximumPrice)),
              _buildMetricColumn(context, 'Min Invest', _formatMinInvest(ipo.minimumPrice)), // Simplified for summary
            ],
          ),
        ],
      ),
    ));
  }

  Widget _buildCompanyLogo(BuildContext context) {
    // Generate initials from company name
    String initials = 'IPO';
    if (ipo.companyName != null && ipo.companyName!.isNotEmpty) {
      final parts = ipo.companyName!.split(' ');
      if (parts.length > 1) {
        initials = '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      } else {
        initials = ipo.companyName!.substring(0, 2).toUpperCase();
      }
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: context.borderColor),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: context.textPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    Color badgeColor;
    Color textColor = context.surfaceColor;
    String label = ipo.status?.toUpperCase() ?? 'UNKNOWN';

    switch (ipo.status?.toLowerCase()) {
      case 'open':
        badgeColor = context.marketTheme.positive;
        break;
      case 'upcoming':
        badgeColor = ModuleColors.market;
        break;
      case 'closed':
        badgeColor = context.statusWarning; // Or generic grey if preferred
        break;
      default:
        badgeColor = context.borderColor;
        textColor = context.textPrimary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildMetricColumn(BuildContext context, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: context.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: context.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _formatDate(String dateStr) {
    // Basic formatting from YYYY-MM-DD to DD MMM
    try {
      final date = DateTime.parse(dateStr);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${date.day} ${months[date.month - 1]}';
    } catch (e) {
      return dateStr;
    }
  }

  String _formatIssueSize(double? size) {
    if (size == null) return '₹--';
    return '₹${size.toStringAsFixed(0)} Cr';
  }

  String _formatPriceBand(double? min, double? max) {
    if (min == null && max == null) return '₹--';
    if (min != null && max != null) return '₹${min.toStringAsFixed(0)} - ₹${max.toStringAsFixed(0)}';
    final single = min ?? max;
    return '₹${single?.toStringAsFixed(0)}';
  }

  String _formatMinInvest(double? minPrice) {
    // Summary doesn't have lot size, so we show minimum price roughly.
    // If we wanted exact, we'd need lotSize in summary.
    if (minPrice == null) return '₹--';
    return '₹${minPrice.toStringAsFixed(0)} /sh';
  }
}
