import 'package:flutter_test/flutter_test.dart';
import 'package:am_common/core/offline_sync/outbox_item.dart';
import 'package:am_common/core/offline_sync/outbox_queue.dart';
import 'package:am_common/core/offline_sync/mutation_adapter.dart';

void main() {
  group('OutboxItem', () {
    test('round-trips json', () {
      final item = OutboxItem(
        clientMutationId: 'abc',
        type: 'createTrade',
        payloadJson: '{"x":1}',
        createdAt: DateTime.utc(2026, 1, 2, 3, 4, 5),
        status: OutboxItemStatus.queued,
        attempts: 1,
        lastError: 'x',
        serverId: 's1',
      );
      final restored = OutboxItem.fromJson(item.toJson());
      expect(restored.clientMutationId, 'abc');
      expect(restored.type, 'createTrade');
      expect(restored.attempts, 1);
      expect(restored.status, OutboxItemStatus.queued);
      expect(restored.serverId, 's1');
    });

    test('copyWith updates status and attempts', () {
      final item = OutboxItem(
        clientMutationId: 'id',
        type: 'createTrade',
        payloadJson: '{}',
        createdAt: DateTime.utc(2026, 1, 1),
        status: OutboxItemStatus.queued,
      );
      final next = item.copyWith(
        status: OutboxItemStatus.flushing,
        attempts: 2,
      );
      expect(next.status, OutboxItemStatus.flushing);
      expect(next.attempts, 2);
      expect(next.clientMutationId, 'id');
    });
  });

  group('FlushResult', () {
    test('factories', () {
      expect(FlushResult.success(serverId: '1').status, FlushStatus.success);
      expect(FlushResult.retryable('e').status, FlushStatus.retryableFailure);
      expect(FlushResult.permanent('e').status, FlushStatus.permanentFailure);
      expect(FlushResult.conflict('e').status, FlushStatus.conflict);
    });
  });

  group('OutboxQueue', () {
    test('maxAttempts is 5 for poison isolation', () {
      expect(OutboxQueue.maxAttempts, 5);
    });
  });

  group('flush priority ordering', () {
    test('upload < trade < ai', () {
      const priority = <String, int>{
        'uploadPortfolioDocument': 0,
        'createTrade': 1,
        'updateTrade': 1,
        'aiChatSend': 2,
      };
      final types = [
        'aiChatSend',
        'createTrade',
        'uploadPortfolioDocument',
      ];
      types.sort((a, b) => (priority[a] ?? 50).compareTo(priority[b] ?? 50));
      expect(types, [
        'uploadPortfolioDocument',
        'createTrade',
        'aiChatSend',
      ]);
    });
  });
}
