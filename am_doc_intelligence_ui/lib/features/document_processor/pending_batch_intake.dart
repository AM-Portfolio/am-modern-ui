import 'dart:typed_data';

import 'package:am_doc_intelligence_ui/features/document_processor/pending_sync_file.dart';

/// One file candidate before it is staged into a sync batch.
class StagedFileBytes {
  final Uint8List bytes;
  final String filename;

  const StagedFileBytes({required this.bytes, required this.filename});
}

enum IntakeRejectReason {
  unsupportedType,
  tooLarge,
  duplicateName,
  batchFull,
}

class IntakeReject {
  final String filename;
  final IntakeRejectReason reason;

  const IntakeReject({required this.filename, required this.reason});

  String get message {
    switch (reason) {
      case IntakeRejectReason.unsupportedType:
        return '$filename — use XLSX, XLS, PDF, or CSV';
      case IntakeRejectReason.tooLarge:
        return '$filename exceeds the 10 MB limit';
      case IntakeRejectReason.duplicateName:
        return '$filename is already in this batch';
      case IntakeRejectReason.batchFull:
        return 'Batch is full (max ${PendingBatchIntake.maxFiles} files)';
    }
  }
}

/// Result of staging one or more files into the pending batch.
class IntakeResult {
  final int addedCount;
  final List<IntakeReject> rejected;
  final List<String> replacedFilenames;

  const IntakeResult({
    required this.addedCount,
    required this.rejected,
    required this.replacedFilenames,
  });

  bool get hasAdditions => addedCount > 0;
  bool get hasRejections => rejected.isNotEmpty;

  /// User-facing status line after a drop / pick.
  String statusMessage({required int pendingCount}) {
    final parts = <String>[];
    if (addedCount > 0) {
      parts.add(
        '$addedCount file${addedCount == 1 ? '' : 's'} added · $pendingCount of ${PendingBatchIntake.maxFiles} ready',
      );
    }
    if (replacedFilenames.isNotEmpty) {
      parts.add(
        'Replaced earlier ${replacedFilenames.join(', ')} (latest wins per broker)',
      );
    }
    if (rejected.isNotEmpty) {
      // Surface the most actionable rejection first; avoid dumping a novel.
      parts.add(rejected.first.message);
      if (rejected.length > 1) {
        parts.add('+${rejected.length - 1} more skipped');
      }
    }
    if (parts.isEmpty) {
      return pendingCount == 0
          ? ''
          : '$pendingCount file${pendingCount == 1 ? '' : 's'} ready to sync';
    }
    return parts.join(' · ');
  }
}

/// Pure, race-safe staging rules for multi-document sync.
///
/// Call [addAll] once per drop/pick with the full candidate list so capacity,
/// duplicates, and per-broker eviction are evaluated atomically.
class PendingBatchIntake {
  static const int maxFiles = 5;
  static const int maxFileBytes = 10 * 1024 * 1024;
  static const Set<String> allowedExtensions = {
    'pdf',
    'xlsx',
    'xls',
    'csv',
  };

  /// MIME hints for the browser file dialog / dropzone (defense in depth).
  static const List<String> acceptedMimeTypes = [
    'application/pdf',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'application/vnd.ms-excel',
    'text/csv',
    'application/csv',
    'text/plain',
  ];

  static String extensionOf(String filename) {
    final dot = filename.lastIndexOf('.');
    if (dot < 0 || dot == filename.length - 1) return '';
    return filename.substring(dot + 1).toLowerCase();
  }

  static bool isAllowedFilename(String filename) =>
      allowedExtensions.contains(extensionOf(filename));

  /// Stages [incoming] into [pending]. Mutates [pending]; disposes evicted files.
  static IntakeResult addAll({
    required List<PendingSyncFile> pending,
    required List<StagedFileBytes> incoming,
    String? defaultBroker,
    String? defaultDocType,
  }) {
    var addedCount = 0;
    final rejected = <IntakeReject>[];
    final replaced = <String>[];
    final seenInBatch = incoming.map((e) => e.filename).toList();

    // De-dupe within the same drop (keep last occurrence).
    final uniqueIncoming = <String, StagedFileBytes>{};
    for (final file in incoming) {
      uniqueIncoming[file.filename] = file;
    }
    // Preserve drop order of last occurrence.
    final ordered = <StagedFileBytes>[];
    final emitted = <String>{};
    for (final name in seenInBatch.reversed) {
      if (emitted.add(name)) {
        ordered.add(uniqueIncoming[name]!);
      }
    }
    final candidates = ordered.reversed.toList();

    for (final candidate in candidates) {
      final filename = candidate.filename;
      final bytes = candidate.bytes;

      if (!isAllowedFilename(filename)) {
        rejected.add(IntakeReject(
          filename: filename,
          reason: IntakeRejectReason.unsupportedType,
        ));
        continue;
      }
      if (bytes.length > maxFileBytes) {
        rejected.add(IntakeReject(
          filename: filename,
          reason: IntakeRejectReason.tooLarge,
        ));
        continue;
      }
      if (pending.any((f) => f.filename == filename)) {
        rejected.add(IntakeReject(
          filename: filename,
          reason: IntakeRejectReason.duplicateName,
        ));
        continue;
      }

      final broker = defaultBroker;
      if (broker != null && broker.isNotEmpty) {
        final evicted = _evictBroker(pending, broker);
        if (evicted != null) replaced.add(evicted);
      }

      if (pending.length >= maxFiles) {
        rejected.add(IntakeReject(
          filename: filename,
          reason: IntakeRejectReason.batchFull,
        ));
        continue;
      }

      pending.add(PendingSyncFile(
        bytes: bytes,
        filename: filename,
        brokerType: broker,
        documentType: defaultDocType,
      ));
      addedCount++;
    }

    return IntakeResult(
      addedCount: addedCount,
      rejected: rejected,
      replacedFilenames: replaced,
    );
  }

  /// Removes pending files already tagged with [broker]. Returns last removed name.
  static String? evictBroker(
    List<PendingSyncFile> pending,
    String broker, {
    PendingSyncFile? except,
  }) =>
      _evictBroker(pending, broker, except: except);

  static String? _evictBroker(
    List<PendingSyncFile> pending,
    String broker, {
    PendingSyncFile? except,
  }) {
    String? lastRemoved;
    for (var i = pending.length - 1; i >= 0; i--) {
      final f = pending[i];
      if (identical(f, except)) continue;
      if (f.brokerType == broker) {
        lastRemoved = f.filename;
        pending.removeAt(i).dispose();
      }
    }
    return lastRemoved;
  }
}
