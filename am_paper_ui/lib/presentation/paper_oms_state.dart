import 'package:equatable/equatable.dart';

import '../data/oms_models.dart';

class PaperOmsState extends Equatable {
  const PaperOmsState({
    this.wallet,
    this.orders = const [],
    this.positions = const [],
    this.orderTypeFavorite = 'MARKET',
    this.loading = false,
    this.submitting = false,
    this.error,
    this.toast,
  });

  final OmsWallet? wallet;
  final List<OmsOrder> orders;
  final List<OmsPosition> positions;
  final String orderTypeFavorite;
  final bool loading;
  final bool submitting;
  final String? error;
  final String? toast;

  PaperOmsState copyWith({
    OmsWallet? wallet,
    List<OmsOrder>? orders,
    List<OmsPosition>? positions,
    String? orderTypeFavorite,
    bool? loading,
    bool? submitting,
    String? error,
    String? toast,
    bool clearError = false,
    bool clearToast = false,
  }) {
    return PaperOmsState(
      wallet: wallet ?? this.wallet,
      orders: orders ?? this.orders,
      positions: positions ?? this.positions,
      orderTypeFavorite: orderTypeFavorite ?? this.orderTypeFavorite,
      loading: loading ?? this.loading,
      submitting: submitting ?? this.submitting,
      error: clearError ? null : (error ?? this.error),
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
        submitting,
        error,
        toast,
      ];
}
