import 'package:am_trade_ui/features/trade/internal/data/datasources/oms_remote_data_source.dart';
import 'package:am_trade_ui/features/trade/internal/data/dtos/oms_dto.dart';
import 'package:am_trade_ui/features/trade/presentation/cubit/oms_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeOms implements OmsRemoteDataSource {
  _FakeOms({this.wallet, this.order});

  OmsWallet? wallet;
  OmsOrder? order;
  int createWalletCalls = 0;

  @override
  Future<OmsWallet> createPaperWallet() async {
    createWalletCalls += 1;
    wallet = const OmsWallet(
      walletId: 'w1',
      kind: 'PAPER',
      currency: 'INR',
      available: '1000000.00',
      reserved: '0.00',
      portfolioId: 'Paper',
      portfolioUuid: 'puuid',
    );
    return wallet!;
  }

  @override
  Future<OmsOrder> createOrder({
    required String walletId,
    required String symbol,
    required String side,
    required String quantity,
    required String idempotencyKey,
  }) async {
    return order ??
        OmsOrder(
          orderId: 'o1',
          walletId: walletId,
          symbol: symbol,
          side: side,
          quantity: quantity,
          status: 'REJECTED',
          rejectReason: 'INSUFFICIENT_CASH',
          available: wallet?.available ?? '1000000.00',
          reserved: '0.00',
        );
  }

  @override
  Future<OmsWallet> getWallet(String walletId) async => wallet!;

  @override
  Future<List<OmsOrder>> listOrders({required String walletId}) async =>
      order == null ? const [] : [order!];

  @override
  Future<List<OmsWallet>> listWallets({String kind = 'PAPER'}) async =>
      wallet == null ? const [] : [wallet!];
}

void main() {
  test('createPaperWallet seeds virtual cash', () async {
    final cubit = OmsCubit(_FakeOms());
    await cubit.createPaperWallet();
    expect(cubit.state.paperWallet?.available, '1000000.00');
    expect(cubit.state.toast, contains('virtual cash'));
  });

  test('rejected order maps to toast', () async {
    final source = _FakeOms(
      wallet: const OmsWallet(
        walletId: 'w1',
        kind: 'PAPER',
        currency: 'INR',
        available: '1000000.00',
        reserved: '0.00',
        portfolioId: 'Paper',
        portfolioUuid: 'puuid',
      ),
    );
    final cubit = OmsCubit(source);
    await cubit.load();
    await cubit.placeMarketOrder(symbol: 'RELIANCE', side: 'BUY', quantity: '999999');
    expect(cubit.state.toast, contains('virtual cash'));
    expect(cubit.state.orders.first.status, 'REJECTED');
  });

  test('omsRejectMessage covers P0 codes', () {
    expect(omsRejectMessage('LTP_UNAVAILABLE'), contains('Live price'));
    expect(omsRejectMessage('INSUFFICIENT_QTY'), contains('quantity'));
    expect(omsRejectMessage('OPTIONS_NOT_ENABLED'), contains('Options'));
  });
}
