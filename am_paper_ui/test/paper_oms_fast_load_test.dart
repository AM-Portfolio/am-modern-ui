import 'dart:async';

import 'package:am_paper_ui/data/oms_models.dart';
import 'package:am_paper_ui/data/paper_oms_data_source.dart';
import 'package:am_paper_ui/presentation/paper_oms_cubit.dart';
import 'package:am_paper_ui/presentation/paper_oms_state.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeSlowPaperOmsDataSource implements PaperOmsDataSource {
  final Completer<List<OmsOrder>> ordersCompleter = Completer<List<OmsOrder>>();
  final Completer<List<OmsPosition>> positionsCompleter = Completer<List<OmsPosition>>();

  @override
  Future<List<OmsWallet>> listWallets({String kind = 'PAPER'}) async {
    return [
      const OmsWallet(
        walletId: 'w-paper-1',
        kind: 'PAPER',
        available: '1000000',
        reserved: '0',
        currency: 'INR',
        portfolioId: '',
        portfolioUuid: '',
      ),
    ];
  }

  @override
  Future<List<OmsOrder>> listOrders({
    required String walletId,
    String? status,
    DateTime? from,
    DateTime? to,
    int limit = 100,
  }) {
    return ordersCompleter.future;
  }

  @override
  Future<List<OmsPosition>> listPositions(String walletId) {
    return positionsCompleter.future;
  }

  @override
  Future<String> getOrderTypeFavorite() async => 'MARKET';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('PaperOmsCubit Fast First Paint', () {
    test('emits wallet immediately while orders and positions are still loading', () async {
      final fake = _FakeSlowPaperOmsDataSource();
      final cubit = PaperOmsCubit(fake);

      final states = <PaperOmsState>[];
      cubit.stream.listen(states.add);

      final loadFuture = cubit.load();
      // Allow microtasks to run so wallet resolves
      await Future<void>.delayed(const Duration(milliseconds: 10));

      // Wallet should already be emitted with loading = false and loadingOrders/Positions = true
      expect(cubit.state.wallet, isNotNull);
      expect(cubit.state.wallet?.walletId, 'w-paper-1');
      expect(cubit.state.loading, isFalse);
      expect(cubit.state.loadingOrders, isTrue);
      expect(cubit.state.loadingPositions, isTrue);

      // Now complete orders and positions
      fake.ordersCompleter.complete([
        const OmsOrder(
          orderId: 'ord-1',
          walletId: 'w-paper-1',
          symbol: 'TRENT',
          side: 'BUY',
          orderType: 'MARKET',
          quantity: '5',
          status: 'FILLED',
        ),
      ]);
      fake.positionsCompleter.complete([
        const OmsPosition(
          walletId: 'w-paper-1',
          symbol: 'TRENT',
          qty: '5',
        ),
      ]);

      await loadFuture;
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(cubit.state.loadingOrders, isFalse);
      expect(cubit.state.loadingPositions, isFalse);
      expect(cubit.state.orders.length, 1);
      expect(cubit.state.positions.length, 1);

      await cubit.close();
    });
  });
}
