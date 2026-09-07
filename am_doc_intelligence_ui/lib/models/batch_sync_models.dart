/// Overall status for `POST /v1/documents/sync` and status polling.
class BatchSyncStatus {
  final String batchId;
  final int total;
  final int completed;
  final int failed;
  final String overallStatus;
  final List<FileSyncStatus> files;

  const BatchSyncStatus({
    required this.batchId,
    required this.total,
    required this.completed,
    required this.failed,
    required this.overallStatus,
    required this.files,
  });

  bool get isTerminal =>
      overallStatus == 'COMPLETED' ||
      overallStatus == 'FAILED' ||
      overallStatus == 'PARTIAL';

  factory BatchSyncStatus.fromJson(Map<String, dynamic> json) {
    final filesJson = json['files'];
    return BatchSyncStatus(
      batchId: (json['batchId'] ?? '').toString(),
      total: (json['total'] as num?)?.toInt() ?? 0,
      completed: (json['completed'] as num?)?.toInt() ?? 0,
      failed: (json['failed'] as num?)?.toInt() ?? 0,
      overallStatus: (json['overallStatus'] ?? 'QUEUED').toString(),
      files: filesJson is List
          ? filesJson
              .whereType<Map>()
              .map((e) => FileSyncStatus.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
    );
  }
}

/// Per-file status inside a [BatchSyncStatus].
class FileSyncStatus {
  final String fileId;
  final String fileName;
  final String? detectedBroker;
  final String? detectedDocumentType;
  final String status;
  final String? errorMessage;
  final int recordsProcessed;

  const FileSyncStatus({
    required this.fileId,
    required this.fileName,
    this.detectedBroker,
    this.detectedDocumentType,
    required this.status,
    this.errorMessage,
    this.recordsProcessed = 0,
  });

  factory FileSyncStatus.fromJson(Map<String, dynamic> json) {
    return FileSyncStatus(
      fileId: (json['fileId'] ?? '').toString(),
      fileName: (json['fileName'] ?? 'unknown').toString(),
      detectedBroker: json['detectedBroker']?.toString(),
      detectedDocumentType: json['detectedDocumentType']?.toString(),
      status: (json['status'] ?? 'QUEUED').toString(),
      errorMessage: json['errorMessage']?.toString(),
      recordsProcessed: (json['recordsProcessed'] as num?)?.toInt() ?? 0,
    );
  }
}
