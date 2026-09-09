import 'package:flutter_test/flutter_test.dart';
import 'package:am_doc_intelligence_ui/models/batch_sync_models.dart';
import 'package:am_doc_intelligence_ui/models/sync_unavailable_exception.dart';

void main() {
  test('BatchSyncStatus.fromJson maps per-file progress', () {
    final status = BatchSyncStatus.fromJson({
      'batchId': '11111111-1111-1111-1111-111111111111',
      'total': 2,
      'completed': 1,
      'failed': 0,
      'overallStatus': 'PROCESSING',
      'files': [
        {
          'fileId': 'a',
          'fileName': 'zerodha.xlsx',
          'detectedBroker': 'ZERODHA',
          'status': 'COMPLETED',
          'recordsProcessed': 12,
        },
        {
          'fileId': 'b',
          'fileName': 'groww.xlsx',
          'status': 'QUEUED',
        },
      ],
    });

    expect(status.batchId, '11111111-1111-1111-1111-111111111111');
    expect(status.total, 2);
    expect(status.files, hasLength(2));
    expect(status.files.first.detectedBroker, 'ZERODHA');
    expect(status.files.first.recordsProcessed, 12);
    expect(status.isTerminal, isFalse);
  });

  test('BatchSyncStatus.isTerminal for mixed and failed batches', () {
    expect(
      BatchSyncStatus.fromJson({
        'batchId': 'x',
        'total': 1,
        'completed': 0,
        'failed': 1,
        'overallStatus': 'FAILED',
        'files': [],
      }).isTerminal,
      isTrue,
    );
    expect(
      BatchSyncStatus.fromJson({
        'batchId': 'x',
        'total': 2,
        'completed': 1,
        'failed': 1,
        'overallStatus': 'PARTIAL',
        'files': [],
      }).isTerminal,
      isTrue,
    );
  });

  test('BatchSyncStatus counts SKIPPED files', () {
    final status = BatchSyncStatus.fromJson({
      'batchId': 'x',
      'total': 2,
      'completed': 1,
      'failed': 0,
      'overallStatus': 'COMPLETED',
      'files': [
        {
          'fileId': 'a',
          'fileName': 'old.xlsx',
          'detectedBroker': 'ZERODHA',
          'status': 'SKIPPED',
          'errorMessage': 'Duplicate ZERODHA file; kept new.xlsx (latest)',
        },
        {
          'fileId': 'b',
          'fileName': 'new.xlsx',
          'detectedBroker': 'ZERODHA',
          'status': 'COMPLETED',
          'recordsProcessed': 5,
        },
      ],
    });

    expect(status.skipped, 1);
    expect(status.files.first.isSkipped, isTrue);
    expect(status.files.first.isTerminal, isTrue);
    expect(status.isTerminal, isTrue);
  });

  test('BatchSyncStatus maps NEEDS_INPUT and detection fields', () {
    final status = BatchSyncStatus.fromJson({
      'batchId': 'x',
      'total': 1,
      'completed': 0,
      'failed': 0,
      'overallStatus': 'PARTIAL',
      'files': [
        {
          'fileId': 'a',
          'fileName': 'scan.pdf',
          'status': 'NEEDS_INPUT',
          'detectionConfidence': 0,
          'detectionDecision': 'NEEDS_INPUT',
          'detectionWarnings': ['Scanned or image-only PDF'],
          'detectionEvidenceSummary': ['PdfTextBrokerDetectionStrategy:pdfText=empty'],
          'errorMessage': 'Scanned or image-only PDF — set broker and document type',
        },
      ],
    });

    expect(status.needsInput, 1);
    expect(status.files.first.isNeedsInput, isTrue);
    expect(status.files.first.isTerminal, isTrue);
    expect(status.files.first.detectionDecision, 'NEEDS_INPUT');
    expect(status.files.first.detectionWarnings, isNotEmpty);
    expect(status.isTerminal, isTrue);
  });

  test('BatchSyncStatus maps NEEDS_CONFIRM and password hint', () {
    final status = BatchSyncStatus.fromJson({
      'batchId': 'x',
      'total': 2,
      'completed': 0,
      'failed': 0,
      'overallStatus': 'PARTIAL',
      'files': [
        {
          'fileId': 'a',
          'fileName': 'zerodha.xlsx',
          'detectedBroker': 'ZERODHA',
          'detectedDocumentType': 'STOCK_PORTFOLIO',
          'status': 'NEEDS_CONFIRM',
          'detectionConfidence': 60,
          'detectionDecision': 'CONFIRM',
        },
        {
          'fileId': 'b',
          'fileName': 'angel.xlsx',
          'status': 'NEEDS_INPUT',
          'errorMessage': 'Password required to open encrypted workbook',
          'detectionWarnings': ['Password required'],
        },
      ],
    });

    expect(status.needsConfirm, 1);
    expect(status.needsInput, 1);
    expect(status.files.first.isNeedsConfirm, isTrue);
    expect(status.files.last.needsPassword, isTrue);
  });

  test('SyncUnavailableException detects Failed to fetch and 404', () {
    expect(
      SyncUnavailableException.looksLikeNetworkOrMissingRoute(
        'ClientException: Failed to fetch, uri=https://example/sync',
      ),
      isTrue,
    );
    expect(
      SyncUnavailableException.looksLikeNetworkOrMissingRoute('ok', 404),
      isTrue,
    );
    expect(
      SyncUnavailableException.looksLikeNetworkOrMissingRoute(
        'Sync failed: 400\nbad request',
        400,
      ),
      isFalse,
    );
  });
}
