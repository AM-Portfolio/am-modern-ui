import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/oms_models.dart';
import '../data/paper_oms_data_source.dart';
import 'paper_oms_state.dart';

class PaperOmsCubit extends Cubit<PaperOmsState> {
  PaperOmsCubit(this._source) : super(const PaperOmsState());

  final PaperOmsDataSource _source;

  Future<void> load() async {
    emit(state.copyWith(
      loading: true,
      loadingOrders: false,
      loadingPositions: false,
      clearError: true,
      clearToast: true,
    ));
    try {
      final wallets = await _source.listWallets();
      OmsWallet? paper;
      for (final w in wallets) {
        if (w.isPaper) {
          paper = w;
          break;
        }
      }
      if (paper == null) {
        emit(state.copyWith(
          wallet: null,
          orders: const [],
          positions: const [],
          loading: false,
          loadingOrders: false,
          loadingPositions: false,
          clearError: true,
        ));
        return;
      }

      // Fast first paint: emit wallet immediately so desk shell renders.
      emit(state.copyWith(
        wallet: paper,
        loading: false,
        loadingOrders: true,
        loadingPositions: true,
        clearError: true,
      ));

      // Lazy-load orders, positions, and preferences in parallel.
      unawaited(_loadOrders(paper.walletId));
      unawaited(_loadPositions(paper.walletId));
      unawaited(_loadFavorite());
    } catch (e) {
      emit(state.copyWith(
        loading: false,
        loadingOrders: false,
        loadingPositions: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> _loadOrders(String walletId) async {
    try {
      final orders = await _source.listOrders(walletId: walletId);
      emit(state.copyWith(orders: orders, loadingOrders: false));
    } catch (_) {
      emit(state.copyWith(loadingOrders: false));
    }
  }

  Future<void> _loadPositions(String walletId) async {
    try {
      final positions = await _source.listPositions(walletId);
      emit(state.copyWith(positions: positions, loadingPositions: false));
    } catch (_) {
      emit(state.copyWith(loadingPositions: false));
    }
  }

  Future<void> _loadFavorite() async {
    try {
      final favorite = await _source.getOrderTypeFavorite();
      emit(state.copyWith(orderTypeFavorite: favorite));
    } catch (_) {}
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
    emit(state.copyWith(loadingOrders: true, loadingPositions: true));
    try {
      final fresh = await _source.getWallet(wallet.walletId);
      final orders = await _source.listOrders(walletId: wallet.walletId);
      final positions = await _source.listPositions(wallet.walletId);
      emit(state.copyWith(
        wallet: fresh,
        orders: orders,
        positions: positions,
        loadingOrders: false,
        loadingPositions: false,
      ));
    } catch (_) {
      emit(state.copyWith(loadingOrders: false, loadingPositions: false));
    }
  }

  Future<void> saveOrderTypeFavorite(String orderType) async {
    final fav = await _source.putOrderTypeFavorite(orderType);
    emit(state.copyWith(orderTypeFavorite: fav));
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

  Future<void> cancelAllPending() async {
    final wallet = state.wallet;
    if (wallet == null) return;
    emit(state.copyWith(submitting: true, clearToast: true));
    try {
      final n = await _source.cancelAllOrders(walletId: wallet.walletId);
      emit(state.copyWith(
        submitting: false,
        toast: n == 0 ? 'No pending orders to cancel' : 'Cancelled $n pending order(s)',
      ));
      await refreshBooks();
    } catch (e) {
      final msg = omsRejectMessage(omsErrorCode(e));
      emit(state.copyWith(submitting: false, toast: msg));
    }
  }
}
