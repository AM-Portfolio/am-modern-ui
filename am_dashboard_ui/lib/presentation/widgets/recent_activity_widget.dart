import 'package:am_dashboard_ui/domain/models/activity_item.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RecentActivityWidget extends StatelessWidget {
  final List<ActivityItem> activities;

  const RecentActivityWidget({
    super.key,
    required this.activities,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Recent Activity',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          if (activities.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(child: Text('No recent activity')),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: activities.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final activity = activities[index];
                return _buildActivityTile(context, activity);
              },
            ),
          // "See All" button could go here
        ],
      ),
    );
  }

  Widget _buildActivityTile(BuildContext context, ActivityItem activity) {
    IconData icon;
    Color color;

    switch (activity.type) {
      case 'TRADE':
        icon = Icons.swap_horiz;
        color = Colors.blue;
        break;
      case 'DEPOSIT':
        icon = Icons.add_circle_outline;
        color = AppColors.profit;
        break;
      case 'WITHDRAWAL':
        icon = Icons.remove_circle_outline;
        color = AppColors.loss;
        break;
      case 'ALERT':
        icon = Icons.notifications_none;
        color = Colors.orange;
        break;
      default:
        icon = Icons.info_outline;
        color = Colors.grey;
    }

    final timeFormat = DateFormat.jm().add_MMMEd();

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.1),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(activity.title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(
        '${activity.description}\n${timeFormat.format(activity.timestamp)}',
        style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 12),
      ),
      isThreeLine: true,
      trailing: (activity.amount?.isNotEmpty ?? false)
          ? Text(
              activity.amount!,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: activity.isPositive ? AppColors.profit : AppColors.loss,
              ),
            )
          : null,
    );
  }
}
