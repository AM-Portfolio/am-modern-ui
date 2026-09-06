import 'package:am_dashboard_ui/domain/models/activity_item.dart';
import 'package:am_dashboard_ui/presentation/shared/widgets/activity_status_filter.dart';
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
    this.currentPage = 0,
    this.totalPages = 1,
    this.statusFilter = ActivityStatusFilter.all,
    this.onStatusFilterChanged,
    this.onViewAll,
    this.onPageChanged,
  });

  final List<ActivityItem> activities;
  final int totalItems;
  final int pageSize;
  final int currentPage;
  final int totalPages;
  final ActivityStatusFilter statusFilter;
  final ValueChanged<ActivityStatusFilter>? onStatusFilterChanged;
  final VoidCallback? onViewAll;
  final ValueChanged<int>? onPageChanged;

  @override
  Widget build(BuildContext context) {
    final onSurface = context.colors.textPrimary;
    final onSurfaceVariant = context.colors.textSecondary;
    final accent = context.colors.actionPrimaryBg;
    final showPaging = totalItems > pageSize;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Activity',
              style: context.text.sectionTitle(compact: true).copyWith(
                    color: onSurface,
                  ),
            ),
            if (showPaging)
              InkWell(
                onTap: onViewAll,
                borderRadius: BorderRadius.circular(AppRadii.xs + 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'View All ($totalItems)',
                      style: context.text.link(compact: true).copyWith(
                            color: accent,
                          ),
                    ),
                    Icon(Icons.chevron_right, size: 16, color: accent),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: [
            for (final entry in [
              (ActivityStatusFilter.all, 'All'),
              (ActivityStatusFilter.win, 'Win'),
              (ActivityStatusFilter.loss, 'Loss'),
              (ActivityStatusFilter.neutral, 'Neutral'),
            ])
              FilterChip(
                label: Text(entry.$2, style: context.text.caption()),
                selected: statusFilter == entry.$1,
                onSelected: (_) => onStatusFilterChanged?.call(entry.$1),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm + 4),
        if (activities.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
            child: Center(
              child: Text(
                'No recent activity',
                style: context.text
                    .bodyMuted()
                    .copyWith(color: onSurfaceVariant),
              ),
            ),
          )
        else
          ...activities.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm + 2),
              child: RecentActivityMobileCard(item: item),
            ),
          ),
        if (showPaging) ...[
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, size: 20),
                onPressed: currentPage > 0
                    ? () => onPageChanged?.call(currentPage - 1)
                    : null,
              ),
              Text(
                '${currentPage + 1}/$totalPages',
                style: context.text.caption().copyWith(color: onSurfaceVariant),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, size: 20),
                onPressed: currentPage < totalPages - 1
                    ? () => onPageChanged?.call(currentPage + 1)
                    : null,
              ),
              if (totalPages > 1)
                TextButton(
                  onPressed: () => onPageChanged?.call(0),
                  child: Text(
                    'Latest',
                    style: context.text.caption().copyWith(color: accent),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
