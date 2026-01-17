
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../am_common.dart'; // Assuming export exists, or import relative
import '../providers/notification_provider.dart';
import '../domain/notification_entity.dart';
import 'package:intl/intl.dart';

class NotificationBell extends ConsumerWidget {
  final Color? iconColor;
  final double iconSize;

  const NotificationBell({
    Key? key,
    this.iconColor,
    this.iconSize = 24.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationProvider);
    final unreadCount = state.unreadCount;

    return PopupMenuButton<String>(
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(
            Icons.notifications_outlined,
            color: iconColor ?? Theme.of(context).iconTheme.color,
            size: iconSize,
          ),
          if (unreadCount > 0)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                child: Text(
                  unreadCount > 9 ? '9+' : unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (context) {
        if (state.notifications.isEmpty) {
          return [
            const PopupMenuItem(
              enabled: false,
              child: SizedBox(
                width: 300,
                height: 100,
                child: Center(
                  child: Text('No notifications'),
                ),
              ),
            ),
          ];
        } else {
          return [
            PopupMenuItem(
              enabled: false,
              child: Container(
                width: 300,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Notifications',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    if (unreadCount > 0)
                      TextButton(
                        onPressed: () {
                          ref.read(notificationProvider.notifier).markAllAsRead();
                          Navigator.pop(context);
                        },
                        child: const Text('Mark all read'),
                      ),
                  ],
                ),
              ),
            ),
            const PopupMenuDivider(),
            ...state.notifications.take(5).map((notification) {
              return PopupMenuItem<String>(
                value: notification.id,
                onTap: () {
                   ref.read(notificationProvider.notifier).markAsRead(notification.id);
                   
                   // Handle navigation if actionUrl is present
                   if (notification.actionUrl != null) {
                     // Use WidgetsBinding to navigate after the popup closes
                     WidgetsBinding.instance.addPostFrameCallback((_) {
                       Navigator.of(context).pushNamed(notification.actionUrl!);
                     });
                   }
                },
                child: _NotificationItem(notification: notification),
              );
            }).toList(),
            if (state.notifications.length > 5)
              const PopupMenuItem(
                value: 'view_all',
                child: Center(child: Text('View All')),
              ),
          ];
        }
      },
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final NotificationEntity notification;

  const _NotificationItem({required this.notification});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, h:mm a');
    
    return Container(
      width: 300,
      padding: const EdgeInsets.symmetric(vertical: 4),
      color: notification.isRead ? null : Theme.of(context).primaryColor.withOpacity(0.05),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(right: 12, top: 4),
            child: Icon(
              _getIconForType(notification.type),
              size: 20,
              color: _getColorForType(context, notification.type),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title,
                  style: TextStyle(
                    fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  notification.message,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  dateFormat.format(notification.timestamp),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).hintColor,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          if (!notification.isRead)
            Container(
              margin: const EdgeInsets.only(left: 8, top: 8),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }

  IconData _getIconForType(NotificationType type) {
    switch (type) {
      case NotificationType.success:
        return Icons.check_circle_outline;
      case NotificationType.warning:
        return Icons.warning_amber_rounded;
      case NotificationType.error:
        return Icons.error_outline;
      case NotificationType.opportunity:
        return Icons.lightbulb_outline;
      case NotificationType.info:
      default:
        return Icons.info_outline;
    }
  }

  Color _getColorForType(BuildContext context, NotificationType type) {
    switch (type) {
      case NotificationType.success:
        return Colors.green;
      case NotificationType.warning:
        return Colors.orange;
      case NotificationType.error:
        return Colors.red;
      case NotificationType.opportunity:
        return Colors.purple; // Premium/Opportunity color
      case NotificationType.info:
      default:
        return Theme.of(context).primaryColor;
    }
  }
}
