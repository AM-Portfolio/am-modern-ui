
import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification_entity.freezed.dart';
part 'notification_entity.g.dart';

enum NotificationType {
  info,
  success,
  warning,
  error,
  opportunity
}

@freezed
class NotificationEntity with _$NotificationEntity {
  const factory NotificationEntity({
    required String id,
    required String title,
    required String message,
    required DateTime timestamp,
    @Default(false) bool isRead,
    @Default(NotificationType.info) NotificationType type,
    String? actionUrl,
    Map<String, dynamic>? payload,
  }) = _NotificationEntity;

  factory NotificationEntity.fromJson(Map<String, dynamic> json) => 
      _$NotificationEntityFromJson(json);
}
