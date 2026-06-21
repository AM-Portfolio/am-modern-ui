import 'package:am_dashboard_ui/domain/models/activity_item.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'glass_card.dart';

/// Pixel-perfect Lumina recent activity widget matching the image.
/// Now dynamically scales with backend data and allows scrolling if needed.
class DashboardRecentActivityWidget extends StatelessWidget {
  final List<ActivityItem> activities;

  const DashboardRecentActivityWidget({
    super.key,
    required this.activities,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final onSurface = isDark ? Colors.white : const Color(0xFF0F172A);
    final onSurfaceVariant = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final primary = isDark ? const Color(0xFF60A5FA) : const Color(0xFF2E3192);

    return AmGlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
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
              InkWell(
                onTap: () {},
                hoverColor: Colors.transparent,
                child: Text(
                  'View All →',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2E3192),
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Table Headers
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: isDark ? Colors.transparent : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 100,
                  child: Text(
                    'Symbol',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: onSurfaceVariant,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Units',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: onSurfaceVariant,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
                SizedBox(
                  width: 100,
                  child: Text(
                    'Date',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: onSurfaceVariant,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: Text(
                    'Amount',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: onSurfaceVariant,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF1F5F9)),
          const SizedBox(height: 8),

          // Activity list
          if (activities.isEmpty)
            _buildEmptyState(onSurfaceVariant)
          else
            SizedBox(
              height: 220,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: activities.length,
                itemBuilder: (context, index) {
                  return _buildActivityItem(context, activities[index], isDark, onSurface, onSurfaceVariant);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(Color onSurfaceVariant) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Center(
        child: Text(
          'No recent activity',
          style: TextStyle(
            color: onSurfaceVariant,
            fontWeight: FontWeight.w500,
            fontFamily: 'Inter',
          ),
        ),
      ),
    );
  }

  Widget _buildActivityItem(
    BuildContext context, 
    ActivityItem activity, 
    bool isDark, 
    Color onSurface, 
    Color onSurfaceVariant
  ) {
    final dateFormat = DateFormat('MMM d, yyyy').format(activity.timestamp);
    final subtitle = activity.description; 

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
        hoverColor: isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Symbol
              SizedBox(
                width: 100,
                child: Tooltip(
                  message: activity.title,
                  child: Text(
                    activity.title.toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: onSurface,
                      fontFamily: 'Inter',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              // Action / Units
              Expanded(
                child: Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: onSurfaceVariant,
                    fontFamily: 'Inter',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Date
              SizedBox(
                width: 100,
                child: Text(
                  dateFormat,
                  style: TextStyle(
                    fontSize: 11,
                    color: onSurfaceVariant,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
              // Amount
              SizedBox(
                width: 80,
                child: Text(
                  activity.amount ?? '',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: onSurface,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
