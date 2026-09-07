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
