
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/notification_entity.dart';

// State for the notification feature
class NotificationState {
  final List<NotificationEntity> notifications;
  final bool isLoading;
  final String? error;

  NotificationState({
    this.notifications = const [],
    this.isLoading = false,
    this.error,
  });

  NotificationState copyWith({
    List<NotificationEntity>? notifications,
    bool? isLoading,
    String? error,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
  
  int get unreadCount => notifications.where((n) => !n.isRead).length;
}

class NotificationNotifier extends Notifier<NotificationState> {
  @override
  NotificationState build() {
    // Trigger initial fetch
    Future.microtask(() => fetchNotifications());
    return NotificationState();
  }

  Future<void> fetchNotifications() async {
    state = state.copyWith(isLoading: true);
    
    try {
      // TODO: Replace with actual API call when backend is ready
      await Future.delayed(const Duration(seconds: 1));
      
      final mockNotifications = [
        NotificationEntity(
          id: '1',
          title: 'Welcome',
          message: 'Welcome to the new AM Portfolio experience.',
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
          type: NotificationType.info,
          isRead: false,
        ),
        NotificationEntity(
          id: '2',
          title: 'Basket Opportunity',
          message: 'Your portfolio has an 85% match with "Tech Giants ETF".',
          timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
          type: NotificationType.opportunity,
          isRead: false,
          actionUrl: '/basket/preview/123',
        ),
      ];
      
      state = state.copyWith(
        notifications: mockNotifications,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void markAsRead(String id) {
    final updatedList = state.notifications.map((n) {
      if (n.id == id) {
        return n.copyWith(isRead: true);
      }
      return n;
    }).toList();
    
    state = state.copyWith(notifications: updatedList);
  }
  
  void markAllAsRead() {
    final updatedList = state.notifications.map((n) {
      return n.copyWith(isRead: true);
    }).toList();
    
    state = state.copyWith(notifications: updatedList);
  }

  void addNotification(NotificationEntity notification) {
    state = state.copyWith(
      notifications: [notification, ...state.notifications],
    );
  }
}

final notificationProvider = NotifierProvider<NotificationNotifier, NotificationState>(NotificationNotifier.new);
