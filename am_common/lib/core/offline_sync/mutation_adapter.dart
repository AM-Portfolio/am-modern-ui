import 'outbox_item.dart';

enum FlushStatus {
  success,
  retryableFailure,
  permanentFailure,
  conflict,
}

class FlushResult {
  const FlushResult({
    required this.status,
    this.serverId,
    this.errorMessage,
  });

  final FlushStatus status;
  final String? serverId;
  final String? errorMessage;

  factory FlushResult.success({String? serverId}) => FlushResult(
        status: FlushStatus.success,
        serverId: serverId,
      );

  factory FlushResult.retryable(String message) => FlushResult(
        status: FlushStatus.retryableFailure,
        errorMessage: message,
      );

  factory FlushResult.permanent(String message) => FlushResult(
        status: FlushStatus.permanentFailure,
        errorMessage: message,
      );

  factory FlushResult.conflict(String message) => FlushResult(
        status: FlushStatus.conflict,
        errorMessage: message,
      );
}

abstract class MutationAdapter {
  String get type;

  bool get blocksOtherTypes => false;

  Future<void> applyOptimistic(OutboxItem item);

  Future<FlushResult> flush(OutboxItem item);

  Future<void> reconcileServerIds(String clientMutationId, String serverId);
}
