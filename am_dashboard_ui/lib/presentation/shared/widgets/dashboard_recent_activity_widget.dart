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

    final onSurface = isDark ? Colors.white : const Color(0xFF111827);
    final onSurfaceVariant = isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280);
    final primary = isDark ? const Color(0xFF60A5FA) : const Color(0xFF2E3192);

    return AmGlassCard(
      padding: const EdgeInsets.all(24),
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
              TextButton(
                onPressed: () {},
                child: Text(
                  'VIEW ALL',
                  style: TextStyle(
                    color: primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Activity list
          if (activities.isEmpty)
            _buildEmptyState(onSurfaceVariant)
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 350),
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
    // Custom formatting to match the design EXACTLY
    final timeFormat = DateFormat('h:mm a').format(activity.timestamp);
    final dayFormat = DateFormat('EEE, MMM d').format(activity.timestamp).toUpperCase();

    // USING REAL BACKEND DATA (no mocking)
    final subtitle = activity.description;

    final iconBgColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFF4F6F8);
    final borderColor = isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Grey circular icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
              border: Border.all(color: borderColor),
            ),
            child: Icon(Icons.info_outline, color: onSurfaceVariant, size: 16),
          ),
          const SizedBox(width: 16),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title.toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: onSurface,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: onSurfaceVariant,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$timeFormat $dayFormat',
                  style: TextStyle(
                    fontSize: 9,
                    color: onSurfaceVariant.withValues(alpha: 0.6),
                    fontFamily: 'Inter',
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          // Amount badge
          if (activity.amount?.isNotEmpty ?? false)
            Text(
              activity.amount!,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: onSurface, // In design, price is black, not colored
                fontFamily: 'Inter',
              ),
            ),
        ],
      ),
    );
  }
}
