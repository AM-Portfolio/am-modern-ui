import 'package:equatable/equatable.dart';

import '../../internal/data/dtos/oms_dto.dart';

class OmsState extends Equatable {
  const OmsState({
    this.paperWallet,
    this.orders = const [],
    this.loading = false,
    this.submitting = false,
    this.error,
    this.toast,
  });

  final OmsWallet? paperWallet;
  final List<OmsOrder> orders;
  final bool loading;
  final bool submitting;
  final String? error;
  final String? toast;

  bool get hasPaperWallet => paperWallet != null;

  OmsState copyWith({
    OmsWallet? paperWallet,
    List<OmsOrder>? orders,
    bool? loading,
    bool? submitting,
    String? error,
    String? toast,
    bool clearError = false,
    bool clearToast = false,
  }) =>
      OmsState(
        paperWallet: paperWallet ?? this.paperWallet,
        orders: orders ?? this.orders,
        loading: loading ?? this.loading,
        submitting: submitting ?? this.submitting,
        error: clearError ? null : error ?? this.error,
        toast: clearToast ? null : toast ?? this.toast,
      );

  @override
  List<Object?> get props =>
      [paperWallet, orders, loading, submitting, error, toast];
}
