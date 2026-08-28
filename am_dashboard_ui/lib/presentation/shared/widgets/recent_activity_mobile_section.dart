import 'package:am_dashboard_ui/domain/models/activity_item.dart';
import 'package:am_dashboard_ui/presentation/shared/widgets/recent_activity_mobile_card.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';

/// Mobile Recent Activity section — header + individual cards on dashboard bg.
class RecentActivityMobileSection extends StatelessWidget {
  const RecentActivityMobileSection({
    super.key,
    required this.activities,
    required this.totalItems,
    required this.pageSize,
    this.onViewAll,
  });

  final List<ActivityItem> activities;
  final int totalItems;
  final int pageSize;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    final onSurface = context.colors.textPrimary;
    final onSurfaceVariant = context.colors.textSecondary;
    final accent = context.colors.actionPrimaryBg;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Activity',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: onSurface,
                fontFamily: 'Inter',
              ),
            ),
            if (totalItems > pageSize)
              InkWell(
                onTap: onViewAll,
                borderRadius: BorderRadius.circular(6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'View All ($totalItems)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: accent,
                        fontFamily: 'Inter',
                      ),
                    ),
                    Icon(Icons.chevron_right, size: 16, color: accent),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (activities.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Text(
                'No recent activity',
                style: TextStyle(color: onSurfaceVariant, fontFamily: 'Inter'),
              ),
            ),
          )
        else
          ...activities.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: RecentActivityMobileCard(item: item),
            ),
          ),
      ],
    );
  }
}
