
import 'package:flutter_test/flutter_test.dart';
import 'package:am_common/features/notifications/domain/notification_entity.dart';
import 'package:am_common/features/notifications/providers/notification_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  group('NotificationProvider', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state is empty', () {
      final state = container.read(notificationProvider);
      // It starts with empty. Loading triggers asynchronously.
      expect(state.notifications, isEmpty);
      expect(state.isLoading, false); 
    });
    
    test('can add notification', () {
      final notifier = container.read(notificationProvider.notifier);
      final notification = NotificationEntity(
        id: '999',
        title: 'Test',
        message: 'Test Message',
        timestamp: DateTime.now(),
      );
      
      notifier.addNotification(notification);
      
      final state = container.read(notificationProvider);
      expect(state.notifications.length, 1);
      expect(state.notifications.first.id, '999');
      expect(state.unreadCount, 1);
    });

    test('mark as read updates state', () {
      final notifier = container.read(notificationProvider.notifier);
      final notification = NotificationEntity(
        id: '999',
        title: 'Test',
        message: 'Test Message',
        timestamp: DateTime.now(),
      );
      
      notifier.addNotification(notification);
      notifier.markAsRead('999');
      
      final state = container.read(notificationProvider);
      expect(state.notifications.first.isRead, true);
      expect(state.unreadCount, 0);
    });
    
     test('mark all as read updates all', () {
      final notifier = container.read(notificationProvider.notifier);
      notifier.addNotification(NotificationEntity(id: '1', title: 'A', message: 'A', timestamp: DateTime.now()));
      notifier.addNotification(NotificationEntity(id: '2', title: 'B', message: 'B', timestamp: DateTime.now()));
      
      notifier.markAllAsRead();
      
      final state = container.read(notificationProvider);
      expect(state.notifications.every((n) => n.isRead), true);
      expect(state.unreadCount, 0);
    });
  });
}
