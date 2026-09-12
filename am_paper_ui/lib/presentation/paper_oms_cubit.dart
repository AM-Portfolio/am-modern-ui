import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/oms_models.dart';
import '../data/paper_oms_data_source.dart';
import 'paper_oms_state.dart';

class PaperOmsCubit extends Cubit<PaperOmsState> {
  PaperOmsCubit(this._source) : super(const PaperOmsState());

  final PaperOmsDataSource _source;

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
      List<OmsPosition> positions = const [];
      if (paper != null) {
        orders = await _source.listOrders(walletId: paper.walletId);
        positions = await _source.listPositions(paper.walletId);
      }
      emit(state.copyWith(
        wallet: paper,
        orders: orders,
        positions: positions,
        loading: false,
        clearError: true,
      ));
    } catch (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }

  Future<void> enablePaper() async {
    emit(state.copyWith(submitting: true, clearError: true, clearToast: true));
    try {
      final wallet = await _source.createPaperWallet();
      emit(state.copyWith(
        wallet: wallet,
        submitting: false,
        toast:
            'Paper trading enabled — ₹${wallet.available} virtual cash (not live broker money).',
      ));
      await refreshBooks();
    } catch (e) {
      final msg = omsRejectMessage(omsErrorCode(e));
      emit(state.copyWith(submitting: false, error: msg, toast: msg));
    }
  }

  Future<void> refreshBooks() async {
    final wallet = state.wallet;
    if (wallet == null) return;
    try {
      final fresh = await _source.getWallet(wallet.walletId);
      final orders = await _source.listOrders(walletId: wallet.walletId);
      final positions = await _source.listPositions(wallet.walletId);
      emit(state.copyWith(wallet: fresh, orders: orders, positions: positions));
    } catch (_) {}
  }

  Future<OmsOrder?> placeOrder({
    required String symbol,
    required String side,
    required String orderType,
    required String quantity,
    String? limitPrice,
    String? triggerPrice,
    String? targetPrice,
    String? stopLoss,
    String? trailJump,
    String? entryType,
  }) async {
    final wallet = state.wallet;
    if (wallet == null) {
      emit(state.copyWith(toast: 'Enable paper trading first.'));
      return null;
    }
    emit(state.copyWith(submitting: true, clearError: true, clearToast: true));
    try {
      final order = await _source.createOrder(
        walletId: wallet.walletId,
        symbol: symbol,
        side: side,
        orderType: orderType,
        quantity: quantity,
        idempotencyKey:
            '${DateTime.now().toUtc().microsecondsSinceEpoch}-$symbol-$side-$orderType',
        limitPrice: limitPrice,
        triggerPrice: triggerPrice,
        targetPrice: targetPrice,
        stopLoss: stopLoss,
        trailJump: trailJump,
        entryType: entryType,
      );
      OmsWallet next = wallet;
      if (order.available != null) {
        next = OmsWallet(
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
          : order.isWorking
              ? 'Working ${order.orderType} ${order.side} ${order.quantity} ${order.symbol}'
              : 'Filled ${order.side} ${order.quantity} ${order.symbol} at ${order.fillPrice}';
      emit(state.copyWith(
        wallet: next,
        orders: [order, ...state.orders],
        submitting: false,
        toast: toast,
      ));
      // Refresh books in background — do not block Instant Buy UI.
      unawaited(refreshBooks());
      return order;
    } catch (e) {
      final msg = omsRejectMessage(omsErrorCode(e));
      emit(state.copyWith(submitting: false, error: msg, toast: msg));
      return null;
    }
  }

  Future<void> cancel(String orderId) async {
    emit(state.copyWith(submitting: true, clearToast: true));
    try {
      await _source.cancelOrder(orderId);
      emit(state.copyWith(submitting: false, toast: 'Order cancelled'));
      await refreshBooks();
    } catch (e) {
      final msg = omsRejectMessage(omsErrorCode(e));
      emit(state.copyWith(submitting: false, toast: msg));
    }
  }
}
