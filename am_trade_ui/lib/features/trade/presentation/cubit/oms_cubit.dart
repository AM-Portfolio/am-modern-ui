import 'package:flutter_bloc/flutter_bloc.dart';

import '../../internal/data/datasources/oms_remote_data_source.dart';
import '../../internal/data/dtos/oms_dto.dart';
import 'oms_state.dart';

class OmsCubit extends Cubit<OmsState> {
  OmsCubit(this._source) : super(const OmsState());

  final OmsRemoteDataSource _source;

  Future<void> load() async {
    emit(state.copyWith(loading: true, clearError: true, clearToast: true));
    try {
      final wallets = await _source.listWallets();
      OmsWallet? paper;
      for (final w in wallets) {
        if (w.isPaper) {
          paper = w;
          break;
        }
      }
      List<OmsOrder> orders = const [];
      if (paper != null) {
        orders = await _source.listOrders(walletId: paper.walletId);
      }
      emit(state.copyWith(
        paperWallet: paper,
        orders: orders,
        loading: false,
        clearError: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        loading: false,
        error: omsRejectMessage(omsErrorCode(e)) == 'Order rejected.'
            ? e.toString()
            : omsRejectMessage(omsErrorCode(e)),
      ));
    }
  }

  Future<void> createPaperWallet() async {
    emit(state.copyWith(submitting: true, clearError: true, clearToast: true));
    try {
      final wallet = await _source.createPaperWallet();
      emit(state.copyWith(
        paperWallet: wallet,
        submitting: false,
        toast: 'Paper wallet ready — ₹${wallet.available} virtual cash, not a live broker order.',
      ));
      await loadOrders();
    } catch (e) {
      emit(state.copyWith(
        submitting: false,
        error: omsRejectMessage(omsErrorCode(e)),
        toast: omsRejectMessage(omsErrorCode(e)),
      ));
    }
  }

  Future<void> loadOrders() async {
    final wallet = state.paperWallet;
    if (wallet == null) return;
    try {
      final orders = await _source.listOrders(walletId: wallet.walletId);
      emit(state.copyWith(orders: orders));
    } catch (_) {}
  }

  Future<OmsOrder?> placeMarketOrder({
    required String symbol,
    required String side,
    required String quantity,
  }) async {
    final wallet = state.paperWallet;
    if (wallet == null) {
      emit(state.copyWith(toast: 'Create a paper wallet first.'));
      return null;
    }
    emit(state.copyWith(submitting: true, clearError: true, clearToast: true));
    try {
      final order = await _source.createOrder(
        walletId: wallet.walletId,
        symbol: symbol,
        side: side,
        quantity: quantity,
        idempotencyKey: '${DateTime.now().toUtc().microsecondsSinceEpoch}-$symbol-$side-$quantity',
      );
      OmsWallet nextWallet = wallet;
      if (order.available != null) {
        nextWallet = OmsWallet(
          walletId: wallet.walletId,
          kind: wallet.kind,
          currency: wallet.currency,
          available: order.available!,
          reserved: order.reserved ?? wallet.reserved,
          portfolioId: wallet.portfolioId,
          portfolioUuid: wallet.portfolioUuid,
        );
      }
      final toast = order.isRejected
          ? omsRejectMessage(order.rejectReason)
          : 'Filled ${order.side} ${order.quantity} ${order.symbol} at ${order.fillPrice}';
      emit(state.copyWith(
        paperWallet: nextWallet,
        orders: [order, ...state.orders],
        submitting: false,
        toast: toast,
      ));
      return order;
    } catch (e) {
      final msg = omsRejectMessage(omsErrorCode(e));
      emit(state.copyWith(submitting: false, error: msg, toast: msg));
      return null;
    }
  }
}
