import 'package:am_design_system/am_design_system.dart';
import 'package:am_market_ui/features/ipo/models/ipo_models.dart';
import 'package:am_market_ui/core/styles/market_theme_extension.dart';
import 'package:flutter/material.dart';

class IpoDetailsHeader extends StatelessWidget {
  final AsraxIpoDetailsDto details;

  const IpoDetailsHeader({super.key, required this.details});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLogo(context),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                details.companyName ?? 'Unknown Company',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: context.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  _buildStatusBadge(context),
                  if (details.issueType != null) ...[
                    const SizedBox(width: AppSpacing.sm),
                    _buildIssueTypeBadge(context),
                  ]
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLogo(BuildContext context) {
    String initials = 'IPO';
    if (details.companyName != null && details.companyName!.isNotEmpty) {
      final parts = details.companyName!.split(' ');
      if (parts.length > 1) {
        initials = '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      } else {
        initials = details.companyName!.substring(0, 2).toUpperCase();
      }
    }

    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: context.borderColor),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: context.textPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    Color badgeColor;
    Color textColor = context.surfaceColor;
    String label = details.status?.toUpperCase() ?? 'UNKNOWN';

    switch (details.status?.toLowerCase()) {
      case 'open':
        badgeColor = context.marketTheme.positive;
        break;
      case 'upcoming':
        badgeColor = ModuleColors.market;
        break;
      case 'closed':
      case 'listed':
        badgeColor = context.statusWarning; 
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
  
  Widget _buildIssueTypeBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        border: Border.all(color: context.borderColor),
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: Text(
        details.issueType?.toUpperCase() ?? '',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: context.textSecondary,
        ),
      ),
    );
  }
}
