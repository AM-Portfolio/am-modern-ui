/// Overall status for `POST /v1/documents/sync` and status polling.
class BatchSyncStatus {
  final String batchId;
  final int total;
  final int completed;
  final int failed;
  final String overallStatus;
  final List<FileSyncStatus> files;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const BatchSyncStatus({
    required this.batchId,
    required this.total,
    required this.completed,
    required this.failed,
    required this.overallStatus,
    required this.files,
    this.createdAt,
    this.updatedAt,
  });

  int get skipped => files.where((f) => f.status == 'SKIPPED').length;

  int get needsInput => files.where((f) => f.status == 'NEEDS_INPUT').length;

  int get needsConfirm => files.where((f) => f.status == 'NEEDS_CONFIRM').length;

  bool get isTerminal =>
      overallStatus == 'COMPLETED' ||
      overallStatus == 'FAILED' ||
      overallStatus == 'PARTIAL';

  /// True when every file is in a terminal per-file state (including confirm/input waits).
  bool get allFilesSettled =>
      files.isNotEmpty && files.every((f) => f.isTerminal);

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
      createdAt: DateTime.tryParse('${json['createdAt'] ?? ''}'),
      updatedAt: DateTime.tryParse('${json['updatedAt'] ?? ''}'),
    );
  }
}

/// Response for `GET /v1/documents/sync` (user batch history).
class BatchSyncHistoryResponse {
  final List<BatchSyncStatus> items;

  const BatchSyncHistoryResponse({required this.items});

  factory BatchSyncHistoryResponse.fromJson(Map<String, dynamic> json) {
    final raw = json['items'];
    return BatchSyncHistoryResponse(
      items: raw is List
          ? raw
              .whereType<Map>()
              .map((e) =>
                  BatchSyncStatus.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
    );
  }
}

/// One row from `GET /api/v1/extract/history`.
class ExtractHistoryItem {
  final String id;
  final String broker;
  final DateTime extractedAt;
  final String source;
  final String? filename;
  final String? mailbox;
  final int holdingsCount;

  const ExtractHistoryItem({
    required this.id,
    required this.broker,
    required this.extractedAt,
    required this.source,
    this.filename,
    this.mailbox,
    this.holdingsCount = 0,
  });

  factory ExtractHistoryItem.fromJson(Map<String, dynamic> json) {
    return ExtractHistoryItem(
      id: '${json['id'] ?? ''}',
      broker: '${json['broker'] ?? ''}',
      extractedAt:
          DateTime.tryParse('${json['extracted_at'] ?? ''}')?.toLocal() ??
              DateTime.now(),
      source: '${json['source'] ?? 'gmail'}',
      filename: json['filename']?.toString(),
      mailbox: json['mailbox']?.toString(),
      holdingsCount: (json['holdings_count'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Per-file status inside a [BatchSyncStatus].
class FileSyncStatus {
  final String fileId;
  final String fileName;
  final String? detectedBroker;
  final String? detectedDocumentType;
  final int? detectionConfidence;
  final String? detectionDecision;
  final List<String> detectionWarnings;
  final List<String> detectionEvidenceSummary;
  final String? catalogVersion;
  final String status;
  final String? errorMessage;
  final int recordsProcessed;
  final DateTime? startedAt;
  final DateTime? completedAt;

  const FileSyncStatus({
    required this.fileId,
    required this.fileName,
    this.detectedBroker,
    this.detectedDocumentType,
    this.detectionConfidence,
    this.detectionDecision,
    this.detectionWarnings = const [],
    this.detectionEvidenceSummary = const [],
    this.catalogVersion,
    required this.status,
    this.errorMessage,
    this.recordsProcessed = 0,
    this.startedAt,
    this.completedAt,
  });

  bool get isSkipped => status == 'SKIPPED';
  bool get isNeedsInput => status == 'NEEDS_INPUT';
  bool get isNeedsConfirm => status == 'NEEDS_CONFIRM';
  bool get needsPassword {
    final blob = [
      errorMessage,
      ...detectionWarnings,
    ].whereType<String>().join(' ').toLowerCase();
    return blob.contains('password') || blob.contains('encrypted');
  }

  bool get isTerminal =>
      status == 'COMPLETED' ||
      status == 'FAILED' ||
      status == 'SKIPPED' ||
      status == 'NEEDS_INPUT' ||
      status == 'NEEDS_CONFIRM';

  factory FileSyncStatus.fromJson(Map<String, dynamic> json) {
    List<String> stringList(dynamic raw) {
      if (raw is! List) return const [];
      return raw.map((e) => e.toString()).toList();
    }

    return FileSyncStatus(
      fileId: (json['fileId'] ?? '').toString(),
      fileName: (json['fileName'] ?? 'unknown').toString(),
      detectedBroker: json['detectedBroker']?.toString(),
      detectedDocumentType: json['detectedDocumentType']?.toString(),
      detectionConfidence: (json['detectionConfidence'] as num?)?.toInt(),
      detectionDecision: json['detectionDecision']?.toString(),
      detectionWarnings: stringList(json['detectionWarnings']),
      detectionEvidenceSummary: stringList(json['detectionEvidenceSummary']),
      catalogVersion: json['catalogVersion']?.toString(),
      status: (json['status'] ?? 'QUEUED').toString(),
      errorMessage: json['errorMessage']?.toString(),
      recordsProcessed: (json['recordsProcessed'] as num?)?.toInt() ?? 0,
      startedAt: DateTime.tryParse('${json['startedAt'] ?? ''}'),
      completedAt: DateTime.tryParse('${json['completedAt'] ?? ''}'),
    );
  }
}
