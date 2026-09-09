import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:am_doc_intelligence_ui/features/document_processor/pending_batch_intake.dart';
import 'package:am_doc_intelligence_ui/features/document_processor/pending_sync_file.dart';

Uint8List _bytes([int length = 8]) => Uint8List(length);

void main() {
  tearDown(() {
    // Controllers on PendingSyncFile must be disposed between tests.
  });

  test('addAll stages multiple files atomically up to max', () {
    final pending = <PendingSyncFile>[];
    final result = PendingBatchIntake.addAll(
      pending: pending,
      incoming: [
        for (var i = 1; i <= 6; i++)
          StagedFileBytes(bytes: _bytes(), filename: 'file$i.xlsx'),
      ],
    );

    expect(result.addedCount, PendingBatchIntake.maxFiles);
    expect(pending, hasLength(PendingBatchIntake.maxFiles));
    expect(result.rejected, hasLength(1));
    expect(result.rejected.first.reason, IntakeRejectReason.batchFull);
    for (final f in pending) {
      f.dispose();
    }
  });

  test('addAll rejects unsupported, oversized, and duplicate names', () {
    final pending = <PendingSyncFile>[
      PendingSyncFile(bytes: _bytes(), filename: 'keep.xlsx'),
    ];
    final oversized = StagedFileBytes(
      bytes: Uint8List(PendingBatchIntake.maxFileBytes + 1),
      filename: 'big.xlsx',
    );
    final result = PendingBatchIntake.addAll(
      pending: pending,
      incoming: [
        StagedFileBytes(bytes: Uint8List(0), filename: 'notes.txt'),
        oversized,
        StagedFileBytes(bytes: _bytes(), filename: 'keep.xlsx'),
        StagedFileBytes(bytes: _bytes(), filename: 'ok.pdf'),
      ],
    );

    expect(result.addedCount, 1);
    expect(pending.map((e) => e.filename), ['keep.xlsx', 'ok.pdf']);
    expect(
      result.rejected.map((e) => e.reason),
      [
        IntakeRejectReason.unsupportedType,
        IntakeRejectReason.tooLarge,
        IntakeRejectReason.duplicateName,
      ],
    );
    for (final f in pending) {
      f.dispose();
    }
  });

  test('addAll de-dupes same filename within one drop (keeps last)', () {
    final pending = <PendingSyncFile>[];
    final first = Uint8List.fromList([1]);
    final second = Uint8List.fromList([2, 2]);
    final result = PendingBatchIntake.addAll(
      pending: pending,
      incoming: [
        StagedFileBytes(bytes: first, filename: 'a.xlsx'),
        StagedFileBytes(bytes: second, filename: 'a.xlsx'),
      ],
    );

    expect(result.addedCount, 1);
    expect(pending, hasLength(1));
    expect(pending.first.bytes, second);
    pending.first.dispose();
  });

  test('addAll evicts earlier file with same default broker', () {
    final pending = <PendingSyncFile>[];
    PendingBatchIntake.addAll(
      pending: pending,
      incoming: [StagedFileBytes(bytes: _bytes(), filename: 'old.xlsx')],
      defaultBroker: 'ZERODHA',
    );
    final result = PendingBatchIntake.addAll(
      pending: pending,
      incoming: [StagedFileBytes(bytes: _bytes(), filename: 'new.xlsx')],
      defaultBroker: 'ZERODHA',
    );

    expect(result.addedCount, 1);
    expect(result.replacedFilenames, ['old.xlsx']);
    expect(pending.map((e) => e.filename), ['new.xlsx']);
    pending.first.dispose();
  });

  test('statusMessage summarizes adds and rejections', () {
    final result = IntakeResult(
      addedCount: 2,
      rejected: const [
        IntakeReject(filename: 'x.txt', reason: IntakeRejectReason.unsupportedType),
        IntakeReject(filename: 'y.txt', reason: IntakeRejectReason.unsupportedType),
      ],
      replacedFilenames: const ['old.xlsx'],
    );
    final message = result.statusMessage(pendingCount: 2);
    expect(message, contains('2 files added'));
    expect(message, contains('Replaced earlier old.xlsx'));
    expect(message, contains('x.txt'));
    expect(message, contains('+1 more skipped'));
  });
}
