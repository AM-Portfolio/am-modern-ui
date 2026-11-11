import 'package:equatable/equatable.dart';

import '../data/oms_models.dart';

class PaperOmsState extends Equatable {
  const PaperOmsState({
    this.wallet,
    this.orders = const [],
    this.positions = const [],
    this.orderTypeFavorite = 'MARKET',
    this.loading = false,
    this.loadingOrders = false,
    this.loadingPositions = false,
    this.submitting = false,
    this.error,
    this.ordersError,
    this.positionsError,
    this.toast,
  });

  final OmsWallet? wallet;
  final List<OmsOrder> orders;
  final List<OmsPosition> positions;
  final String orderTypeFavorite;
  final bool loading;
  final bool loadingOrders;
  final bool loadingPositions;
  final bool submitting;
  final String? error;
  final String? ordersError;
  final String? positionsError;
  final String? toast;

  PaperOmsState copyWith({
    OmsWallet? wallet,
    List<OmsOrder>? orders,
    List<OmsPosition>? positions,
    String? orderTypeFavorite,
    bool? loading,
    bool? loadingOrders,
    bool? loadingPositions,
    bool? submitting,
    String? error,
    String? ordersError,
    String? positionsError,
    String? toast,
    bool clearError = false,
    bool clearOrdersError = false,
    bool clearPositionsError = false,
    bool clearToast = false,
  }) {
    return PaperOmsState(
      wallet: wallet ?? this.wallet,
      orders: orders ?? this.orders,
      positions: positions ?? this.positions,
      orderTypeFavorite: orderTypeFavorite ?? this.orderTypeFavorite,
      loading: loading ?? this.loading,
      loadingOrders: loadingOrders ?? this.loadingOrders,
      loadingPositions: loadingPositions ?? this.loadingPositions,
      submitting: submitting ?? this.submitting,
      error: clearError ? null : (error ?? this.error),
      ordersError: clearOrdersError ? null : (ordersError ?? this.ordersError),
      positionsError:
          clearPositionsError ? null : (positionsError ?? this.positionsError),
      toast: clearToast ? null : (toast ?? this.toast),
    );
  }

  @override
  List<Object?> get props => [
        wallet,
        orders,
        positions,
        orderTypeFavorite,
        loading,
        loadingOrders,
        loadingPositions,
        submitting,
        error,
        ordersError,
        positionsError,
        toast,
      ];
}
