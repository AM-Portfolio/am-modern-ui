enum OutboxItemStatus {
  queued,
  flushing,
  done,
  failed,
  needsAttention,
}

class OutboxItem {
  const OutboxItem({
    required this.clientMutationId,
    required this.type,
    required this.payloadJson,
    required this.createdAt,
    required this.status,
    this.localFilePath,
    this.attempts = 0,
    this.lastError,
    this.serverId,
  });

  final String clientMutationId;
  final String type;
  final String payloadJson;
  final DateTime createdAt;
  final OutboxItemStatus status;
  final String? localFilePath;
  final int attempts;
  final String? lastError;
  final String? serverId;

  OutboxItem copyWith({
    OutboxItemStatus? status,
    int? attempts,
    String? lastError,
    String? serverId,
    String? localFilePath,
  }) {
    return OutboxItem(
      clientMutationId: clientMutationId,
      type: type,
      payloadJson: payloadJson,
      createdAt: createdAt,
      status: status ?? this.status,
      localFilePath: localFilePath ?? this.localFilePath,
      attempts: attempts ?? this.attempts,
      lastError: lastError ?? this.lastError,
      serverId: serverId ?? this.serverId,
    );
  }

  Map<String, dynamic> toJson() => {
        'clientMutationId': clientMutationId,
        'type': type,
        'payloadJson': payloadJson,
        'createdAt': createdAt.toIso8601String(),
        'status': status.name,
        'localFilePath': localFilePath,
        'attempts': attempts,
        'lastError': lastError,
        'serverId': serverId,
      };

  factory OutboxItem.fromJson(Map<String, dynamic> json) {
    return OutboxItem(
      clientMutationId: json['clientMutationId'] as String,
      type: json['type'] as String,
      payloadJson: json['payloadJson'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      status: OutboxItemStatus.values.byName(json['status'] as String),
      localFilePath: json['localFilePath'] as String?,
      attempts: (json['attempts'] as num?)?.toInt() ?? 0,
      lastError: json['lastError'] as String?,
      serverId: json['serverId'] as String?,
    );
  }
}
